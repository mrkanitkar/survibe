import AVFoundation
import Accelerate
import Synchronization
import os.log

/// Module-level logger — not actor-isolated, safe to use from any context.
private let pitchLogger = Logger(
    subsystem: "com.survibe",
    category: "PitchDetector"
)

/// Thread-safe counter for buffer diagnostics.
/// Uses Mutex from Swift Synchronization module for compiler-verified Sendable.
private final class AtomicCounter: Sendable {
    private let value = Mutex<Int>(0)

    var currentValue: Int {
        value.withLock { $0 }
    }

    @discardableResult
    func increment() -> Int {
        value.withLock { val in
            val += 1
            return val
        }
    }
}

/// Autocorrelation-based pitch detector using Accelerate/vDSP.
/// Uses direct AVAudioEngine installTap for buffer access.
/// DSP runs on a dedicated queue to avoid blocking the real-time audio thread.
@MainActor
public final class AudioKitPitchDetector: PitchDetectorProtocol {
    private var continuation: AsyncStream<PitchResult>.Continuation?
    private var isDetecting = false

    /// Reference pitch for frequency-to-note conversion (default: A4 = 440 Hz).
    public var referencePitch: Double = 440.0

    /// Number of audio buffers received (for diagnostics).
    public private(set) var bufferCount: Int = 0

    /// Last measured amplitude (for diagnostics / live meter).
    public private(set) var lastAmplitude: Double = 0

    /// Current detector status for UI feedback.
    public private(set) var status: String = "Idle"

    /// Dedicated queue for DSP processing — keeps audio render thread clear.
    private let processingQueue = DispatchQueue(
        label: "com.survibe.pitch-detection",
        qos: .userInteractive
    )

    public init() {}

    deinit {
        // Safety net: ensure the stream is terminated if this instance
        // is deallocated without an explicit stop() call.
        // Note: AudioEngineManager cleanup must happen on MainActor via Task.
        if isDetecting {
            continuation?.finish()
            Task { @MainActor in
                AudioEngineManager.shared.removeMicTap()
            }
        }
    }

    public func start() -> AsyncStream<PitchResult> {
        // Stop any previous session
        stopInternal()
        bufferCount = 0
        lastAmplitude = 0
        status = "Starting..."

        let refPitch = referencePitch

        let stream = AsyncStream<PitchResult>(
            bufferingPolicy: .bufferingNewest(1)
        ) { continuation in
            self.continuation = continuation
            self.isDetecting = true
            self.status = "Installing mic tap..."

            // Capture only what the tap closure needs — no `self` capture.
            // This avoids actor-isolation issues since the closure is @Sendable.
            let queue = self.processingQueue
            let counter = AtomicCounter()

            AudioEngineManager.shared.installMicTap { buffer, _ in
                // Audio render thread — only copy data, do NOT do heavy work here.
                guard let channelData = buffer.floatChannelData?[0] else {
                    return
                }
                let frameLength = Int(buffer.frameLength)
                guard frameLength > 0 else { return }
                let sampleRate = buffer.format.sampleRate
                let samples = Array(
                    UnsafeBufferPointer(start: channelData, count: frameLength)
                )

                let count = counter.increment()
                // Log every 50th buffer to confirm tap is firing
                if count % 50 == 1 {
                    pitchLogger.info(
                        "Tap buffer #\(count): frames=\(frameLength) rate=\(sampleRate)"
                    )
                }

                // Dispatch all processing to dedicated queue
                queue.async {
                    let amplitude = Self.calculateRMS(samples)

                    // Log amplitude periodically to see if mic is picking up sound
                    if count % 50 == 1 {
                        pitchLogger.info(
                            "Buffer #\(count) amp=\(String(format: "%.6f", amplitude))"
                        )
                    }

                    // Always yield amplitude-only result so UI can show live level
                    // Use frequency=0 to indicate "no pitch detected"
                    if amplitude <= 0.002 {
                        let silentResult = PitchResult(
                            frequency: 0,
                            amplitude: amplitude,
                            noteName: "",
                            octave: 0,
                            centsOffset: 0,
                            confidence: 0
                        )
                        continuation.yield(silentResult)
                        return
                    }

                    let frequency = Self.detectPitch(
                        samples: samples,
                        sampleRate: sampleRate
                    )

                    // Log DSP results periodically
                    if count % 20 == 1 {
                        pitchLogger.info(
                            "DSP: amp=\(String(format: "%.4f", amplitude)) freq=\(String(format: "%.1f", frequency))"
                        )
                    }

                    if frequency > 0, let (noteName, octave, cents) =
                        try? SwarUtility.frequencyToNote(
                            frequency, referencePitch: refPitch
                        ) {
                        let confidence = min(1.0, amplitude * 2.0)

                        let result = PitchResult(
                            frequency: frequency,
                            amplitude: amplitude,
                            noteName: noteName,
                            octave: octave,
                            centsOffset: cents,
                            confidence: confidence
                        )
                        pitchLogger.info(
                            "DETECTED: \(noteName)\(octave) \(String(format: "%.1f", frequency))Hz amp=\(String(format: "%.4f", amplitude))"
                        )
                        continuation.yield(result)
                    } else {
                        // Yield amplitude-only so UI knows mic is working
                        let noFreqResult = PitchResult(
                            frequency: 0,
                            amplitude: amplitude,
                            noteName: "",
                            octave: 0,
                            centsOffset: 0,
                            confidence: 0
                        )
                        continuation.yield(noFreqResult)
                    }
                }
            }

            self.status = "Listening"
            pitchLogger.info("Pitch detector started, mic tap installed")

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.stopInternal()
                }
            }
        }
        return stream
    }

    public func stop() {
        stopInternal()
    }

    /// Internal cleanup — removes tap and finishes stream.
    private func stopInternal() {
        guard isDetecting else { return }
        isDetecting = false
        status = "Stopped"
        AudioEngineManager.shared.removeMicTap()
        continuation?.finish()
        continuation = nil
        pitchLogger.info("Pitch detector stopped")
    }

    // MARK: - DSP (nonisolated static — safe to call from any thread)

    /// Calculate RMS amplitude from audio samples.
    nonisolated private static func calculateRMS(_ samples: [Float]) -> Double {
        var rms: Float = 0
        samples.withUnsafeBufferPointer { ptr in
            guard let base = ptr.baseAddress else { return }
            vDSP_rmsqv(base, 1, &rms, vDSP_Length(samples.count))
        }
        return Double(rms)
    }

    /// Autocorrelation-based pitch detection using Accelerate vDSP.
    nonisolated private static func detectPitch(
        samples: [Float],
        sampleRate: Double
    ) -> Double {
        let frameCount = samples.count
        let halfLength = frameCount / 2
        guard halfLength > 2 else { return 0 }

        // Compute autocorrelation via dot product at each lag
        var autocorrelation = [Float](repeating: 0, count: halfLength)

        samples.withUnsafeBufferPointer { bufPtr in
            guard let baseAddress = bufPtr.baseAddress else { return }
            for lag in 0..<halfLength {
                var sum: Float = 0
                let count = vDSP_Length(halfLength - lag)
                guard count > 0 else { continue }
                vDSP_dotpr(
                    baseAddress, 1,
                    baseAddress + lag, 1,
                    &sum,
                    count
                )
                autocorrelation[lag] = sum
            }
        }

        // Normalize by the zero-lag value (autocorrelation[0] == signal energy;
        // zero means silence or a fully-zero buffer — no pitch to detect).
        guard autocorrelation[0] > 0 else { return 0 }
        var invNorm: Float = 1.0 / autocorrelation[0]
        var normalized = [Float](repeating: 0, count: halfLength)
        vDSP_vsmul(
            &autocorrelation, 1, &invNorm, &normalized, 1,
            vDSP_Length(halfLength)
        )
        autocorrelation = normalized

        // Find first peak after the initial decline
        // Min lag: sampleRate / 4000 Hz, but at least 2
        let minLag = max(2, Int(sampleRate / 4000.0))
        guard minLag < halfLength else { return 0 }

        var bestLag = 0
        var bestVal: Float = 0
        var declining = true

        for lag in minLag..<halfLength {
            if declining && autocorrelation[lag] > autocorrelation[lag - 1] {
                declining = false
            }
            if !declining && autocorrelation[lag] > bestVal {
                bestVal = autocorrelation[lag]
                bestLag = lag
            }
            if !declining
                && autocorrelation[lag] < autocorrelation[lag - 1]
            {
                break
            }
        }

        guard bestLag > 0, bestVal > 0.2 else { return 0 }

        // Parabolic interpolation for sub-sample accuracy
        let refinedLag: Double
        if bestLag > 0 && bestLag < halfLength - 1 {
            let s0 = Double(autocorrelation[bestLag - 1])
            let s1 = Double(autocorrelation[bestLag])
            let s2 = Double(autocorrelation[bestLag + 1])
            let denom = 2.0 * (2.0 * s1 - s2 - s0)
            if abs(denom) > 1e-10 {
                refinedLag = Double(bestLag) + (s2 - s0) / denom
            } else {
                refinedLag = Double(bestLag)
            }
        } else {
            refinedLag = Double(bestLag)
        }

        guard refinedLag > 0 else { return 0 }
        let frequency = sampleRate / refinedLag
        return (frequency > 50 && frequency < 4000) ? frequency : 0
    }
}

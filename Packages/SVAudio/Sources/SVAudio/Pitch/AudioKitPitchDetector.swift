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

            let queue = self.processingQueue
            let counter = AtomicCounter()

            AudioEngineManager.shared.installMicTap { buffer, _ in
                Self.handleMicBuffer(
                    buffer, counter: counter, queue: queue,
                    continuation: continuation, refPitch: refPitch
                )
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

    // MARK: - Mic Buffer Handling (nonisolated static)

    /// Handle a mic buffer from the audio tap on a background queue.
    nonisolated private static func handleMicBuffer(
        _ buffer: AVAudioPCMBuffer,
        counter: AtomicCounter,
        queue: DispatchQueue,
        continuation: AsyncStream<PitchResult>.Continuation,
        refPitch: Double
    ) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        let sampleRate = buffer.format.sampleRate
        let samples = Array(
            UnsafeBufferPointer(start: channelData, count: frameLength)
        )

        let count = counter.increment()
        if count % 50 == 1 {
            pitchLogger.info(
                "Tap buffer #\(count): frames=\(frameLength) rate=\(sampleRate)"
            )
        }

        queue.async {
            processBuffer(
                samples: samples, sampleRate: sampleRate,
                bufferCount: count, continuation: continuation,
                refPitch: refPitch
            )
        }
    }

    /// Process audio samples on the DSP queue and yield pitch results.
    nonisolated private static func processBuffer(
        samples: [Float],
        sampleRate: Double,
        bufferCount: Int,
        continuation: AsyncStream<PitchResult>.Continuation,
        refPitch: Double
    ) {
        let amplitude = calculateRMS(samples)

        if bufferCount % 50 == 1 {
            pitchLogger.info(
                "Buffer #\(bufferCount) amp=\(String(format: "%.6f", amplitude))"
            )
        }

        guard amplitude > 0.002 else {
            continuation.yield(silenceResult(amplitude: amplitude))
            return
        }

        let detection = detectPitchWithConfidence(
            samples: samples, sampleRate: sampleRate
        )

        if bufferCount % 20 == 1 {
            let ampStr = String(format: "%.4f", amplitude)
            let freqStr = String(format: "%.1f", detection.frequency)
            pitchLogger.info("DSP: amp=\(ampStr) freq=\(freqStr)")
        }

        guard detection.frequency > 0,
              let (noteName, octave, cents) = try? SwarUtility.frequencyToNote(
                  detection.frequency, referencePitch: refPitch
              )
        else {
            continuation.yield(silenceResult(amplitude: amplitude))
            return
        }

        let confidence = detection.confidence
        let result = PitchResult(
            frequency: detection.frequency, amplitude: amplitude,
            noteName: noteName, octave: octave,
            centsOffset: cents, confidence: confidence
        )
        let ampStr = String(format: "%.4f", amplitude)
        let freqStr = String(format: "%.1f", detection.frequency)
        pitchLogger.info(
            "DETECTED: \(noteName)\(octave) \(freqStr)Hz amp=\(ampStr)"
        )
        continuation.yield(result)
    }

    /// Create a silent/no-pitch result for the given amplitude.
    nonisolated private static func silenceResult(
        amplitude: Double
    ) -> PitchResult {
        PitchResult(
            frequency: 0, amplitude: amplitude,
            noteName: "", octave: 0,
            centsOffset: 0, confidence: 0
        )
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

    /// Raw detection result containing frequency and spectral confidence.
    private struct PitchDetectionResult {
        let frequency: Double
        let confidence: Double
    }

    /// Autocorrelation-based pitch detection with spectral confidence.
    ///
    /// Returns both the detected frequency and a confidence metric based on
    /// peak-to-sidelobe ratio (via `SpectralConfidence`), replacing the
    /// naive amplitude-based heuristic.
    nonisolated private static func detectPitchWithConfidence(
        samples: [Float],
        sampleRate: Double
    ) -> PitchDetectionResult {
        let autocorrelation = computeAutocorrelation(samples)
        guard !autocorrelation.isEmpty else {
            return PitchDetectionResult(frequency: 0, confidence: 0)
        }

        let halfLength = autocorrelation.count
        let minLag = max(2, Int(sampleRate / 4000.0))
        guard minLag < halfLength else {
            return PitchDetectionResult(frequency: 0, confidence: 0)
        }

        let bestLag = findBestLag(
            autocorrelation, minLag: minLag, halfLength: halfLength
        )
        guard bestLag > 0 else {
            return PitchDetectionResult(frequency: 0, confidence: 0)
        }

        let refinedLag = parabolicInterpolation(
            autocorrelation, lag: bestLag
        )
        guard refinedLag > 0 else {
            return PitchDetectionResult(frequency: 0, confidence: 0)
        }

        let frequency = sampleRate / refinedLag
        guard frequency > 50, frequency < 4000 else {
            return PitchDetectionResult(frequency: 0, confidence: 0)
        }

        let confidence = SpectralConfidence.compute(
            autocorrelation: autocorrelation,
            bestLag: bestLag,
            minLag: minLag
        )

        return PitchDetectionResult(frequency: frequency, confidence: confidence)
    }

    /// Compute normalized autocorrelation of audio samples via vDSP.
    nonisolated private static func computeAutocorrelation(
        _ samples: [Float]
    ) -> [Float] {
        let halfLength = samples.count / 2
        guard halfLength > 2 else { return [] }

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
                    &sum, count
                )
                autocorrelation[lag] = sum
            }
        }

        guard autocorrelation[0] > 0 else { return [] }
        var invNorm: Float = 1.0 / autocorrelation[0]
        var normalized = [Float](repeating: 0, count: halfLength)
        vDSP_vsmul(
            &autocorrelation, 1, &invNorm, &normalized, 1,
            vDSP_Length(halfLength)
        )
        return normalized
    }

    /// Find the best autocorrelation lag (first peak after initial decline).
    nonisolated private static func findBestLag(
        _ autocorrelation: [Float], minLag: Int, halfLength: Int
    ) -> Int {
        var bestLag = 0
        var bestVal: Float = 0
        var declining = true

        for lag in minLag..<halfLength {
            if declining, autocorrelation[lag] > autocorrelation[lag - 1] {
                declining = false
            }
            if !declining, autocorrelation[lag] > bestVal {
                bestVal = autocorrelation[lag]
                bestLag = lag
            }
            if !declining, autocorrelation[lag] < autocorrelation[lag - 1] {
                break
            }
        }
        return bestVal > 0.2 ? bestLag : 0
    }

    /// Parabolic interpolation for sub-sample pitch accuracy.
    nonisolated private static func parabolicInterpolation(
        _ data: [Float], lag: Int
    ) -> Double {
        guard lag > 0, lag < data.count - 1 else { return Double(lag) }
        let s0 = Double(data[lag - 1])
        let s1 = Double(data[lag])
        let s2 = Double(data[lag + 1])
        let denom = 2.0 * (2.0 * s1 - s2 - s0)
        guard abs(denom) > 1e-10 else { return Double(lag) }
        return Double(lag) + (s2 - s0) / denom
    }
}

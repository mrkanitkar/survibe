import AVFoundation
import os.log
import Synchronization

// File-private logger accessible from nonisolated static methods.
// Logger is Sendable so this is safe to use from any isolation context.
private let practiceAudioLogger = Logger(subsystem: "com.survibe", category: "PracticeAudioProcessor")

/// A `Sendable` snapshot of audio buffer data extracted on the audio thread.
///
/// `AVAudioPCMBuffer` is not `Sendable`, so we copy the float samples and
/// metadata into this value type to safely cross isolation boundaries.
private struct BufferSnapshot: Sendable {
    /// Float samples from the first channel.
    let samples: [Float]
    /// The audio sample rate in Hz.
    let sampleRate: Double
}

/// Thread-safe container for passing audio buffer data between the real-time
/// audio callback and the DSP processing task.
///
/// Wraps a `Mutex<BufferSnapshot?>` in a `Sendable` final class so it can be
/// safely captured in `@Sendable` closures and across actor boundaries.
private final class SharedBufferStorage: Sendable {
    /// The mutex-protected buffer snapshot.
    let storage = Mutex<BufferSnapshot?>(nil)

    /// Write a new snapshot (called from the audio callback).
    func write(_ snapshot: BufferSnapshot) {
        storage.withLock { $0 = snapshot }
    }

    /// Read and consume the latest snapshot (called from the DSP task).
    ///
    /// - Returns: The latest snapshot if one is available, nil otherwise.
    ///   Clears the stored value after reading.
    func consume() -> BufferSnapshot? {
        storage.withLock { current in
            let snap = current
            current = nil
            return snap
        }
    }

    /// Clear any stored snapshot.
    func clear() {
        storage.withLock { $0 = nil }
    }
}

/// Processes microphone audio during practice mode and produces pitch detection results.
///
/// Installs a mic tap on `AudioEngineManager.shared`, runs pitch detection
/// on a dedicated DSP queue, and vends results as an `AsyncStream<PitchResult>`.
/// Uses `Mutex` for thread-safe buffer management between the audio thread
/// and the DSP processing queue.
///
/// Usage:
/// ```swift
/// let processor = PracticeAudioProcessor()
/// try processor.start()
/// for await pitch in processor.pitchStream {
///     // Handle PitchResult
/// }
/// processor.stop()
/// ```
@MainActor
public final class PracticeAudioProcessor {
    // MARK: - Properties

    /// Whether the processor is currently active and producing pitch results.
    public private(set) var isActive: Bool = false

    /// The async stream of pitch detection results.
    ///
    /// Yields `PitchResult` values as they are detected from the microphone.
    /// The stream terminates when `stop()` is called.
    public var pitchStream: AsyncStream<PitchResult> {
        guard let stream = _pitchStream else {
            return AsyncStream { $0.finish() }
        }
        return stream
    }

    private var _pitchStream: AsyncStream<PitchResult>?
    private var continuation: AsyncStream<PitchResult>.Continuation?

    /// Thread-safe buffer storage shared between the audio callback and DSP task.
    ///
    /// Held as a `Sendable` reference type so it can be freely captured in
    /// `@Sendable` closures without borrowing `self`.
    private let sharedBuffer = SharedBufferStorage()

    /// Reference pitch for frequency-to-note conversion (A4, in Hz).
    public var referencePitch: Double = 440.0

    /// Optional ring buffer to receive a copy of all mic samples.
    ///
    /// When set, every audio frame delivered to the mic tap is also written
    /// into this buffer so callers can run FFT-based chord detection
    /// (e.g. `ChromagramDSP.analyzeChord`) on a larger, accumulated window.
    /// Set to `nil` to disable. The ring buffer is `Sendable` and thread-safe.
    public var ringBuffer: AudioRingBuffer?

    /// Minimum RMS amplitude to consider a buffer worth analyzing.
    ///
    /// 0.005 (~0.5% of full scale) is appropriate for acoustic instruments
    /// (piano, guitar) picked up 0.5–2m from the device microphone.
    /// Lower values increase sensitivity at the cost of processing noise.
    private let silenceThreshold: Double = 0.005

    /// Minimum autocorrelation confidence for a pitch result to be yielded.
    ///
    /// 0.3 is a practical lower bound for piano notes: the fundamental
    /// autocorrelation peak can be weaker than harmonic peaks on bright-toned
    /// instruments. The caller (PlayAlongViewModel) applies its own confidence
    /// filter via PracticeConstants.confidenceThreshold.
    private let confidenceThreshold: Double = 0.3

    /// Timer task for periodic DSP processing.
    private var dspTask: Task<Void, Never>?

    private static let logger = Logger(
        subsystem: "com.survibe",
        category: "PracticeAudioProcessor"
    )

    // MARK: - Initialization

    /// Create a new practice audio processor.
    public init() {}

    // MARK: - Public Methods

    /// Start capturing microphone audio and producing pitch results.
    ///
    /// Ensures the audio engine is running in playAndRecord mode, installs
    /// a mic tap, and begins periodic DSP processing on a background queue.
    ///
    /// - Throws: `PracticeAudioProcessorError.micTapFailed` if the mic tap
    ///   could not be installed, or any error from `AudioEngineManager.shared.start()`.
    public func start() throws {
        guard !isActive else { return }

        // Ensure engine is in playAndRecord mode for mic access
        try AudioEngineManager.shared.start()

        // Create the AsyncStream
        let (stream, cont) = AsyncStream<PitchResult>.makeStream()
        _pitchStream = stream
        continuation = cont

        // Install mic tap — audio callback extracts samples into a Sendable snapshot
        let buffer = sharedBuffer
        let tapLogger = Self.logger
        // Capture ringBuffer as a Sendable reference so it can be written on
        // the audio thread. The caller sets self.ringBuffer BEFORE calling start(),
        // so the initial value is captured here and remains valid for the tap lifetime.
        let capturedRingBuffer = ringBuffer
        let installed = AudioEngineManager.shared.installMicTap { pcmBuffer, _ in
            guard let channelData = pcmBuffer.floatChannelData?[0] else {
                tapLogger.error("installMicTap callback: no float channel data")
                return
            }
            let frameLength = Int(pcmBuffer.frameLength)
            guard frameLength > 0 else {
                tapLogger.error("installMicTap callback: zero frameLength")
                return
            }
            let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
            let snapshot = BufferSnapshot(
                samples: samples,
                sampleRate: pcmBuffer.format.sampleRate
            )
            buffer.write(snapshot)
            // Also feed the ring buffer for FFT chord detection (if one is attached).
            capturedRingBuffer?.write(samples)
        }

        guard installed else {
            cont.finish()
            _pitchStream = nil
            continuation = nil
            Self.logger.error("Failed to install mic tap")
            throw PracticeAudioProcessorError.micTapFailed
        }

        isActive = true
        startDSPLoop()
        Self.logger.info("PracticeAudioProcessor started")
    }

    /// Stop capturing audio and finish the pitch stream.
    ///
    /// Cancels the DSP processing task, removes the mic tap, and terminates
    /// the pitch result stream. Safe to call if not currently active.
    public func stop() {
        guard isActive else { return }

        dspTask?.cancel()
        dspTask = nil
        AudioEngineManager.shared.removeMicTap()
        continuation?.finish()
        continuation = nil
        _pitchStream = nil
        sharedBuffer.clear()
        isActive = false
        Self.logger.info("PracticeAudioProcessor stopped")
    }

    // MARK: - Private Methods

    /// Start the periodic DSP processing loop.
    ///
    /// Runs approximately every 50ms, reads the latest audio buffer snapshot,
    /// performs autocorrelation-based pitch detection, and yields results
    /// to the async stream.
    private func startDSPLoop() {
        let buffer = sharedBuffer
        let refPitch = referencePitch
        let silenceThresh = silenceThreshold
        let confThresh = confidenceThreshold

        dspTask = Task { [weak self] in
            var emptyBufferCount = 0
            while !Task.isCancelled {
                // Read latest snapshot atomically
                if let snapshot = buffer.consume() {
                    emptyBufferCount = 0
                    let result = Self.detectPitch(
                        from: snapshot,
                        referencePitch: refPitch,
                        silenceThreshold: silenceThresh,
                        confidenceThreshold: confThresh
                    )
                    if let result {
                        let freqStr = String(format: "%.1f", result.frequency)
                        let confStr = String(format: "%.2f", result.confidence)
                        Self.logger.debug(
                            "Pitch detected: \(result.noteName)\(result.octave) \(freqStr)Hz conf=\(confStr)"
                        )
                        self?.continuation?.yield(result)
                    }
                } else {
                    emptyBufferCount += 1
                    // Log every 20 empty cycles (~1 second) to detect no-audio-data scenarios
                    if emptyBufferCount == 20 {
                        Self.logger.warning("DSP loop: no audio data for ~1s — mic tap may not be receiving audio")
                    }
                }

                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    /// Perform pitch detection on a buffer snapshot using autocorrelation.
    ///
    /// This is a `nonisolated static` method so it can be called from any
    /// isolation context without capturing `self`.
    ///
    /// - Parameters:
    ///   - snapshot: The audio buffer snapshot to analyze.
    ///   - referencePitch: Reference pitch for A4 (Hz).
    ///   - silenceThreshold: Minimum amplitude to process.
    ///   - confidenceThreshold: Minimum confidence for results.
    /// - Returns: A `PitchResult` if pitch was detected above thresholds, nil otherwise.
    nonisolated private static func detectPitch(
        from snapshot: BufferSnapshot,
        referencePitch: Double,
        silenceThreshold: Double,
        confidenceThreshold: Double
    ) -> PitchResult? {
        let samples = snapshot.samples
        guard !samples.isEmpty else { return nil }

        let rms = calculateRMS(samples)
        // Debug-level only — visible in Console.app with subsystem filter, not in production logs.
        // Log even below-threshold values so we can verify the mic tap is delivering audio.
        if rms > 0.001 {
            let rmsStr = String(format: "%.4f", rms)
            let thrStr = String(format: "%.4f", silenceThreshold)
            let rateStr = String(format: "%.0f", snapshot.sampleRate)
            practiceAudioLogger.debug("detectPitch: rms=\(rmsStr) threshold=\(thrStr) rate=\(rateStr)Hz")
        }
        guard rms >= silenceThreshold else { return nil }

        let sampleRate = snapshot.sampleRate
        guard sampleRate > 0 else { return nil }

        let result = findBestCorrelation(
            samples: samples, sampleRate: sampleRate
        )
        let confStr2 = String(format: "%.3f", result.confidence)
        let thrStr2 = String(format: "%.3f", confidenceThreshold)
        practiceAudioLogger.debug("detectPitch: lag=\(result.lag) confidence=\(confStr2) threshold=\(thrStr2)")
        guard result.confidence >= confidenceThreshold,
              result.lag > 0
        else { return nil }

        let frequency = sampleRate / Double(result.lag)

        guard let (noteName, octave, centsOffset) = try? SwarUtility.frequencyToNote(
            frequency, referencePitch: referencePitch
        ) else { return nil }

        return PitchResult(
            frequency: frequency, amplitude: rms,
            noteName: noteName, octave: octave,
            centsOffset: centsOffset, confidence: result.confidence
        )
    }

    /// Calculate RMS amplitude from audio samples.
    nonisolated private static func calculateRMS(_ samples: [Float]) -> Double {
        var sum: Float = 0
        for i in 0..<samples.count {
            sum += samples[i] * samples[i]
        }
        return Double(sqrt(sum / Float(samples.count)))
    }

    /// Find the best autocorrelation lag and its confidence.
    nonisolated private static func findBestCorrelation(
        samples: [Float], sampleRate: Double
    ) -> (lag: Int, confidence: Double) {
        let frameLength = samples.count
        let minLag = Int(sampleRate / 2000.0)
        let maxLag = min(Int(sampleRate / 50.0), frameLength / 2)
        guard minLag < maxLag else { return (0, 0) }

        var bestCorrelation: Float = 0
        var bestLag = 0

        for lag in minLag..<maxLag {
            var correlation: Float = 0
            var norm1: Float = 0
            var norm2: Float = 0
            let compareLength = min(frameLength - lag, frameLength / 2)

            for i in 0..<compareLength {
                correlation += samples[i] * samples[i + lag]
                norm1 += samples[i] * samples[i]
                norm2 += samples[i + lag] * samples[i + lag]
            }

            let normProduct = sqrt(norm1 * norm2)
            guard normProduct > 0 else { continue }
            let normalized = correlation / normProduct

            if normalized > bestCorrelation {
                bestCorrelation = normalized
                bestLag = lag
            }
        }

        return (bestLag, Double(bestCorrelation))
    }
}

/// Errors from the practice audio processor.
public enum PracticeAudioProcessorError: Error, Sendable, LocalizedError {
    /// The microphone tap could not be installed.
    case micTapFailed

    /// A localized description of the error.
    public var errorDescription: String? {
        switch self {
        case .micTapFailed:
            "Failed to install microphone tap for practice mode"
        }
    }
}

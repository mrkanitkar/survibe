import AVFoundation
import os.log
import Synchronization

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

    /// Minimum amplitude to consider a pitch detection valid.
    private let silenceThreshold: Double = 0.02

    /// Minimum confidence for pitch results.
    private let confidenceThreshold: Double = 0.5

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
        let installed = AudioEngineManager.shared.installMicTap { pcmBuffer, _ in
            guard let channelData = pcmBuffer.floatChannelData?[0] else { return }
            let frameLength = Int(pcmBuffer.frameLength)
            guard frameLength > 0 else { return }
            let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
            let snapshot = BufferSnapshot(
                samples: samples,
                sampleRate: pcmBuffer.format.sampleRate
            )
            buffer.write(snapshot)
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
            while !Task.isCancelled {
                // Read latest snapshot atomically
                if let snapshot = buffer.consume() {
                    let result = Self.detectPitch(
                        from: snapshot,
                        referencePitch: refPitch,
                        silenceThreshold: silenceThresh,
                        confidenceThreshold: confThresh
                    )
                    if let result {
                        self?.continuation?.yield(result)
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
        let frameLength = samples.count
        guard frameLength > 0 else { return nil }

        // Calculate RMS amplitude
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += samples[i] * samples[i]
        }
        let rms = Double(sqrt(sum / Float(frameLength)))

        guard rms >= silenceThreshold else { return nil }

        // Simple autocorrelation pitch detection
        let sampleRate = snapshot.sampleRate
        guard sampleRate > 0 else { return nil }

        // Search for pitch in the range ~50Hz to ~2000Hz
        let minLag = Int(sampleRate / 2000.0)
        let maxLag = min(Int(sampleRate / 50.0), frameLength / 2)
        guard minLag < maxLag else { return nil }

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
            let normalizedCorrelation = correlation / normProduct

            if normalizedCorrelation > bestCorrelation {
                bestCorrelation = normalizedCorrelation
                bestLag = lag
            }
        }

        let confidence = Double(bestCorrelation)
        guard confidence >= confidenceThreshold, bestLag > 0 else { return nil }

        let frequency = sampleRate / Double(bestLag)

        // Convert frequency to note using SwarUtility
        guard let (noteName, octave, centsOffset) = try? SwarUtility.frequencyToNote(
            frequency,
            referencePitch: referencePitch
        ) else {
            return nil
        }

        return PitchResult(
            frequency: frequency,
            amplitude: rms,
            noteName: noteName,
            octave: octave,
            centsOffset: centsOffset,
            confidence: confidence
        )
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

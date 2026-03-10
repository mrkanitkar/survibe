import Accelerate
import AVFoundation
import Foundation
import Observation
import SVAudio
import SVCore
import os.log

/// Module-level logger — not actor-isolated, safe from any context.
private let vmLogger = Logger(
    subsystem: "com.survibe",
    category: "PitchDetectionVM"
)

// MARK: - Sendable Result Carrier

/// Carries a single DSP result from the processing queue to MainActor.
/// Sendable because all fields are immutable value types.
private struct DSPResult: Sendable {
    let amplitude: Double
    let frequency: Double
    let noteName: String
    let westernName: String
    let octave: Int
    let cents: Double
    let confidence: Double
}

/// Weak, Sendable reference to the ViewModel for use in Task closures.
/// The mic tap closure does NOT capture this — only the inner Task does.
///
/// @unchecked Sendable rationale: Only holds a weak reference read inside
/// `Task { @MainActor }`, so the actual ViewModel access is always on MainActor.
/// No mutable shared state — the weak reference itself is set once at init.
private final class WeakVM: @unchecked Sendable {
    weak var vm: PitchDetectionViewModel?
    init(_ vm: PitchDetectionViewModel) { self.vm = vm }
}

// MARK: - Detection Mode

/// Detection mode controlling which pipeline runs.
enum DetectionMode: String, CaseIterable, Sendable {
    /// Autocorrelation only — single note, fastest, existing behavior.
    case melody
    /// FFT chromagram — multiple notes + chord name.
    case chord
    /// Both pipelines; show chord when ≥2 notes, single note otherwise.
    case both

    /// Localized display name for UI.
    var displayName: String {
        switch self {
        case .melody: String(localized: "Melody")
        case .chord: String(localized: "Chord")
        case .both: String(localized: "Both")
        }
    }
}

/// ViewModel for real-time pitch detection in PracticeTab.
///
/// Pipeline (zero `self` capture in audio/DSP closures):
///   1. Mic tap (audio thread) → copies samples to Array + writes to ring buffer
///   2. dspQueue.async → PitchDSP (melody) and/or ChromagramDSP (chord)
///   3. Task { @MainActor } → reads WeakVM to update UI state
///
/// Supports three detection modes: melody (autocorrelation), chord (FFT chromagram),
/// and both (parallel pipelines). Chord detection uses a ring buffer to accumulate
/// samples for overlapping FFT windows with configurable latency presets.
@MainActor
@Observable
final class PitchDetectionViewModel {
    // MARK: - Properties

    /// Current pitch result from detector (melody mode).
    var currentResult: PitchResult?

    /// Western note name for the current detection (C, D, E, etc.).
    var westernNoteName: String = ""

    /// Whether the detector is actively listening.
    var isListening = false

    /// Error message to display.
    var errorMessage: String?

    /// Detection history for the last few notes (rolling buffer).
    var recentNotes: [DetectedNote] = []

    /// Debug status string for UI feedback.
    var debugStatus: String = "Not started"

    /// Number of pitch detections received.
    var detectionCount: Int = 0

    /// Absolute MIDI note number (36–96) of the currently detected note, for keyboard highlighting.
    /// Each octave produces a unique value: C4=60, C5=72, etc.
    var activeMidiNote: Int? {
        guard let result = currentResult,
              let swar = Swar.allCases.first(where: { $0.rawValue == result.noteName })
        else { return nil }
        return 60 + (result.octave - 4) * 12 + swar.midiOffset
    }

    /// Live amplitude level (0.0 to 1.0) for visual meter.
    var liveAmplitude: Double = 0

    /// Microphone permission status.
    var micStatus: MicrophonePermissionStatus {
        PermissionManager.shared.microphoneStatus
    }

    // MARK: - Chord Detection Properties

    /// Current detection mode.
    var detectionMode: DetectionMode = .melody

    /// Current latency preset for chord detection.
    var latencyPreset: LatencyPreset = .fast

    /// Most recent chord detection result.
    var currentChordResult: ChordResult?

    /// Current pitch expression analysis result.
    var currentExpression: ExpressionResult?

    /// Set of active MIDI notes for multi-key highlighting.
    /// In chord mode: all detected chord notes. In melody mode: the single detected note.
    var activeMidiNotes: Set<Int> {
        if detectionMode != .melody,
           let chord = currentChordResult,
           !chord.detectedPitches.isEmpty
        {
            return chord.activeMidiNotes
        }
        if let single = activeMidiNote {
            return [single]
        }
        return []
    }

    /// Current chord name for display (e.g., "C Major").
    var chordDisplayName: String? {
        currentChordResult?.chordName?.displayName
    }

    /// Sargam chord name for display (e.g., "Sa Major").
    var sargamChordName: String? {
        currentChordResult?.chordName?.sargamDisplayName
    }

    private let maxRecentNotes = 12

    /// Dedicated queue for DSP — keeps audio render thread clear.
    private let dspQueue = DispatchQueue(
        label: "com.survibe.pitch-dsp",
        qos: .userInteractive
    )

    /// Reference pitch for A4.
    private let referencePitch: Double = 440.0

    /// Atomic stop flag shared with the mic tap closure.
    private var stopFlag: AtomicFlag?

    /// Ring buffer for accumulating samples for chord detection FFT.
    private var ringBuffer: AudioRingBuffer?

    /// Last total samples count read from the ring buffer (for hop detection).
    private var lastReadSampleCount: Int = 0

    /// Rolling window of cents offsets for expression analysis.
    private var centsHistory: [Double] = []

    /// Maximum number of cents history entries (~500ms at 23ms hop).
    private let centsHistoryMaxSize = 22

    // MARK: - Public Methods

    /// Start listening for pitch via microphone.
    func startListening() async {
        guard !isListening else { return }
        errorMessage = nil
        debugStatus = "Requesting mic permission..."
        vmLogger.info("startListening called")

        guard await requestMicPermission() else { return }
        guard await startEngine() else { return }

        debugStatus = "Installing mic tap..."
        isListening = true
        detectionCount = 0

        let context = prepareTapContext()
        let tapInstalled = AudioEngineManager.shared.installMicTap(
            handler: buildMicTapHandler(context: context)
        )

        if tapInstalled {
            debugStatus = "Listening (\(context.mode.displayName)) — play a note"
            vmLogger.info("Mic tap installed, mode=\(context.mode.rawValue), listening")
        } else {
            isListening = false
            stopFlag = nil
            ringBuffer = nil
            errorMessage = String(localized: "Could not access microphone. Please check permissions and try again.")
            debugStatus = "Mic tap failed — check logs"
            vmLogger.error("installMicTap returned false — tap not installed")
        }
    }

    // MARK: - Listening Setup Helpers

    /// Request microphone permission. Returns `true` if granted.
    private func requestMicPermission() async -> Bool {
        PermissionManager.shared.updateMicrophoneStatus()
        let granted = await PermissionManager.shared.requestMicrophoneAccess()
        if !granted {
            PermissionManager.shared.updateMicrophoneStatus()
            errorMessage = String(localized: "Microphone access is needed to detect notes.")
            debugStatus = "Mic permission denied"
            vmLogger.error("Mic permission denied")
        }
        return granted
    }

    /// Start the audio engine. Returns `true` if running.
    private func startEngine() async -> Bool {
        debugStatus = "Starting audio engine..."
        vmLogger.info("Mic permission granted, starting engine")

        do {
            try AudioEngineManager.shared.start()
        } catch {
            errorMessage = String(localized: "Could not start audio: \(error.localizedDescription)")
            debugStatus = "Engine failed: \(error.localizedDescription)"
            vmLogger.error("Engine start failed: \(error.localizedDescription)")
            return false
        }

        vmLogger.info("Engine started, isRunning=\(AudioEngineManager.shared.isRunning)")
        try? await Task.sleep(for: .milliseconds(200))

        guard AudioEngineManager.shared.isRunning else {
            debugStatus = "Engine stopped during setup"
            vmLogger.warning("Engine stopped during sleep — aborting")
            return false
        }
        return true
    }

    /// Captures needed for the mic tap closure, bundled to avoid multi-field capture.
    private struct TapContext: Sendable {
        let mode: DetectionMode
        let refPitch: Double
        let realSamples: Int
        let queue: DispatchQueue
        let counter: AtomicCounter
        let flag: AtomicFlag
        let ringBuf: AudioRingBuffer?
        let weakRef: WeakVM
    }

    /// Prepare the ring buffer and capture context for the mic tap.
    private func prepareTapContext() -> TapContext {
        let mode = detectionMode
        let preset = latencyPreset

        if mode == .chord || mode == .both {
            ringBuffer = AudioRingBuffer(capacity: preset.realSamples * 2)
            lastReadSampleCount = 0
            centsHistory = []
        }

        let flag = AtomicFlag()
        self.stopFlag = flag

        return TapContext(
            mode: mode,
            refPitch: referencePitch,
            realSamples: preset.realSamples,
            queue: dspQueue,
            counter: AtomicCounter(),
            flag: flag,
            ringBuf: ringBuffer,
            weakRef: WeakVM(self)
        )
    }

    /// Build the mic tap handler closure from a prepared context.
    private func buildMicTapHandler(
        context: TapContext
    ) -> @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void {
        { buffer, _ in
            guard !context.flag.isSet else { return }
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return }
            let sampleRate = buffer.format.sampleRate
            let samples = Array(
                UnsafeBufferPointer(start: channelData, count: frameLength)
            )

            if context.mode == .chord || context.mode == .both {
                context.ringBuf?.write(samples)
            }

            let bufNum = context.counter.increment()
            if bufNum % 50 == 1 {
                vmLogger.info("Tap #\(bufNum): frames=\(frameLength) rate=\(sampleRate)")
            }

            context.queue.async {
                guard !context.flag.isSet else { return }
                Self.processDSP(
                    samples: samples,
                    sampleRate: sampleRate,
                    bufNum: bufNum,
                    context: context
                )
            }
        }
    }

    /// Run melody and/or chord DSP, then dispatch results to MainActor.
    nonisolated private static func processDSP(
        samples: [Float],
        sampleRate: Double,
        bufNum: Int,
        context: TapContext
    ) {
        let amplitude = PitchDSP.calculateRMS(samples)

        if bufNum % 50 == 1 {
            vmLogger.info("Buf #\(bufNum) amp=\(String(format: "%.6f", amplitude))")
        }

        let melodyResult = runMelodyPipeline(
            samples: samples, sampleRate: sampleRate,
            amplitude: amplitude, mode: context.mode, refPitch: context.refPitch
        )
        let chordDetection = runChordPipeline(
            mode: context.mode, ringBuf: context.ringBuf,
            realSamples: context.realSamples, sampleRate: sampleRate,
            refPitch: context.refPitch
        )

        let amp = amplitude
        let centsForExpression = melodyResult?.cents
        let weakRef = context.weakRef
        let mode = context.mode

        Task { @MainActor in
            guard let vm = weakRef.vm, vm.isListening else { return }
            vm.applyResults(
                amplitude: amp, melodyResult: melodyResult,
                chordDetection: chordDetection,
                centsForExpression: centsForExpression, mode: mode
            )
        }
    }

    /// Autocorrelation melody detection. Returns nil if below threshold.
    nonisolated private static func runMelodyPipeline(
        samples: [Float], sampleRate: Double,
        amplitude: Double, mode: DetectionMode, refPitch: Double
    ) -> DSPResult? {
        guard mode == .melody || mode == .both else { return nil }
        guard amplitude > 0.002 else { return nil }
        let frequency = PitchDSP.detectPitch(samples: samples, sampleRate: sampleRate)
        guard frequency > 0 else { return nil }
        let (noteName, octave, cents) = SwarUtility.frequencyToNote(
            frequency, referencePitch: refPitch
        )
        return DSPResult(
            amplitude: amplitude, frequency: frequency, noteName: noteName,
            westernName: SwarUtility.westernName(for: noteName),
            octave: octave, cents: cents, confidence: min(1.0, amplitude * 2.0)
        )
    }

    /// FFT chromagram chord detection. Returns nil if not in chord mode.
    nonisolated private static func runChordPipeline(
        mode: DetectionMode, ringBuf: AudioRingBuffer?,
        realSamples: Int, sampleRate: Double, refPitch: Double
    ) -> ChordResult? {
        guard mode == .chord || mode == .both else { return nil }
        guard let ringBuf, let fftSamples = ringBuf.read(count: realSamples) else { return nil }
        return ChromagramDSP.analyzeChord(
            samples: fftSamples, sampleRate: sampleRate, referencePitch: refPitch
        )
    }

    /// Apply DSP results to ViewModel state on MainActor.
    private func applyResults(
        amplitude: Double, melodyResult: DSPResult?,
        chordDetection: ChordResult?,
        centsForExpression: Double?, mode: DetectionMode
    ) {
        liveAmplitude = amplitude

        if let r = melodyResult {
            let pitchResult = PitchResult(
                frequency: r.frequency, amplitude: r.amplitude,
                noteName: r.noteName, octave: r.octave,
                centsOffset: r.cents, confidence: r.confidence
            )
            detectionCount += 1
            currentResult = pitchResult
            westernNoteName = r.westernName
            debugStatus = "Detected: \(r.westernName)\(r.octave) (\(Int(r.frequency))Hz)"
            appendNote(pitchResult)
        } else if amplitude > 0.002 && mode != .chord {
            debugStatus = "Sound (amp: \(String(format: "%.3f", amplitude))) — no pitch"
        }

        if let chord = chordDetection {
            currentChordResult = chord
            if let name = chord.chordName {
                debugStatus = "Chord: \(name.displayName)"
            }
        }

        if let cents = centsForExpression {
            centsHistory.append(cents)
            if centsHistory.count > centsHistoryMaxSize {
                centsHistory.removeFirst()
            }
            if centsHistory.count >= 10 {
                currentExpression = PitchExpressionAnalyzer.analyze(
                    centsHistory: centsHistory,
                    hopIntervalSeconds: 1024.0 / 44100.0
                )
            }
        }
    }

    /// Stop listening and tear down audio.
    func stopListening() {
        stopFlag?.set()
        stopFlag = nil
        AudioEngineManager.shared.removeMicTap()
        AudioEngineManager.shared.stop()
        isListening = false

        // Reset chord detection state
        ringBuffer?.reset()
        ringBuffer = nil
        currentChordResult = nil
        currentExpression = nil
        centsHistory = []
        lastReadSampleCount = 0

        debugStatus = "Stopped"
        vmLogger.info("stopListening complete")
    }

    /// URL to iOS Settings for mic permission (opened by the View via @Environment(\.openURL)).
    var settingsURL: URL? {
        PermissionManager.shared.settingsURL
    }

    // MARK: - Private Methods

    /// Append a detected note to the rolling history.
    private func appendNote(_ result: PitchResult) {
        let western = SwarUtility.westernName(for: result.noteName)
        let note = DetectedNote(
            swarName: result.noteName,
            westernName: western,
            octave: result.octave,
            centsOffset: result.centsOffset,
            frequency: result.frequency,
            timestamp: result.timestamp
        )
        recentNotes.append(note)
        if recentNotes.count > maxRecentNotes {
            recentNotes.removeFirst()
        }
    }
}

/// A detected note for display in the history list.
struct DetectedNote: Identifiable {
    let id = UUID()
    let swarName: String
    let westernName: String
    let octave: Int
    let centsOffset: Double
    let frequency: Double
    let timestamp: Date
}

// MARK: - Thread-Safe Primitives

/// Thread-safe boolean flag for signaling stop across threads.
///
/// @unchecked Sendable rationale: All access to `_value` is NSLock-protected.
/// @MainActor isolation is impossible here — read from audio render thread.
private final class AtomicFlag: @unchecked Sendable {
    private var _value: Bool = false
    private let lock = NSLock()

    var isSet: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func set() {
        lock.lock()
        defer { lock.unlock() }
        _value = true
    }
}

/// Thread-safe counter for buffer diagnostics.
///
/// @unchecked Sendable rationale: All access to `_value` is NSLock-protected.
/// Incremented from audio render thread, read from DSP queue.
private final class AtomicCounter: @unchecked Sendable {
    private var _value: Int = 0
    private let lock = NSLock()

    @discardableResult
    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        _value += 1
        return _value
    }
}

// MARK: - Pure DSP Functions (no actor isolation)

/// Stateless DSP functions for pitch detection. Safe to call from any thread.
enum PitchDSP {
    /// Calculate RMS amplitude from audio samples.
    static func calculateRMS(_ samples: [Float]) -> Double {
        var rms: Float = 0
        samples.withUnsafeBufferPointer { ptr in
            guard let base = ptr.baseAddress else { return }
            vDSP_rmsqv(base, 1, &rms, vDSP_Length(samples.count))
        }
        return Double(rms)
    }

    /// Autocorrelation-based pitch detection using Accelerate vDSP.
    ///
    /// For each lag, computes the dot product of the signal with a shifted copy.
    /// Uses (frameCount - lag) samples per lag for maximum correlation strength.
    /// Searches lags 0..<maxLag where maxLag = frameCount/2.
    ///
    /// Includes octave correction: after finding the first peak, checks if a peak
    /// at ~2x the lag (the true fundamental) has comparable strength. This prevents
    /// the common autocorrelation error of locking onto the 2nd harmonic.
    static func detectPitch(
        samples: [Float],
        sampleRate: Double
    ) -> Double {
        let frameCount = samples.count
        guard frameCount > 4 else { return 0 }

        // Search lags up to half the frame length
        let maxLag = frameCount / 2

        // Compute autocorrelation via dot product at each lag
        var autocorrelation = [Float](repeating: 0, count: maxLag)

        samples.withUnsafeBufferPointer { bufPtr in
            guard let baseAddress = bufPtr.baseAddress else { return }
            for lag in 0..<maxLag {
                var sum: Float = 0
                // Use ALL available samples for this lag (frameCount - lag)
                let count = vDSP_Length(frameCount - lag)
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

        // Normalize by the zero-lag value (total energy)
        guard autocorrelation[0] > 0 else { return 0 }
        var invNorm: Float = 1.0 / autocorrelation[0]
        var normalized = [Float](repeating: 0, count: maxLag)
        vDSP_vsmul(
            &autocorrelation, 1, &invNorm, &normalized, 1,
            vDSP_Length(maxLag)
        )
        autocorrelation = normalized

        // Collect ALL peaks (not just the first one) for octave correction
        // Min lag = highest detectable frequency (4000 Hz)
        let minLag = max(2, Int(sampleRate / 4000.0))
        guard minLag < maxLag else { return 0 }

        struct Peak {
            let lag: Int
            let value: Float
        }
        var peaks: [Peak] = []
        var declining = true

        for lag in minLag..<maxLag {
            if declining && autocorrelation[lag] > autocorrelation[lag - 1] {
                declining = false
            }
            if !declining && autocorrelation[lag] < autocorrelation[lag - 1] {
                // Previous sample was a peak
                let peakLag = lag - 1
                let peakVal = autocorrelation[peakLag]
                if peakVal > 0.15 {
                    peaks.append(Peak(lag: peakLag, value: peakVal))
                }
                declining = true
            }
        }

        guard let firstPeak = peaks.first else { return 0 }

        // Octave correction: check if a peak at ~2x the first peak's lag
        // has comparable strength. If so, prefer the longer lag (lower frequency,
        // true fundamental) over the shorter lag (harmonic).
        var bestPeak = firstPeak
        let octaveCorrectionThreshold: Float = 0.85  // sub-octave peak must be >= 85% of first peak

        for peak in peaks where peak.lag != firstPeak.lag {
            let ratio = Double(peak.lag) / Double(firstPeak.lag)
            // Check if this peak is near 2x the first peak (ratio ~1.8 to 2.2)
            if ratio > 1.8 && ratio < 2.2 {
                if peak.value >= firstPeak.value * octaveCorrectionThreshold {
                    bestPeak = peak
                    break
                }
            }
        }

        // Confidence threshold
        guard bestPeak.value > 0.15 else { return 0 }
        let bestLag = bestPeak.lag

        // Parabolic interpolation for sub-sample accuracy
        let refinedLag: Double
        if bestLag > 0 && bestLag < maxLag - 1 {
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

import Foundation
import AVFoundation
import Accelerate

/// Fallback YIN autocorrelation pitch detector using Accelerate/vDSP.
/// Uses direct AVAudioEngine installTap for buffer access.
/// Independent of AudioKit — works with raw AVAudioEngine.
@MainActor
public final class YINPitchDetector: PitchDetectorProtocol {
    private var continuation: AsyncStream<PitchResult>.Continuation?
    private var isDetecting = false

    /// Reference pitch for frequency-to-note conversion (default: A4 = 440 Hz).
    public var referencePitch: Double = 440.0

    /// YIN threshold (lower = stricter, typical range 0.1 to 0.2).
    public var threshold: Double = 0.15

    /// Current detector status for UI feedback (consistent with AudioKitPitchDetector API).
    public private(set) var status: String = "Idle"

    public init() {}

    public func start() -> AsyncStream<PitchResult> {
        let stream = AsyncStream<PitchResult> { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            self.continuation = continuation
            self.isDetecting = true
            self.status = "Listening"

            let refPitch = self.referencePitch
            let yinThreshold = self.threshold

            AudioEngineManager.shared.installMicTap { buffer, _ in
                Self.handleMicTap(
                    buffer: buffer, continuation: continuation,
                    refPitch: refPitch, yinThreshold: yinThreshold
                )
            }

            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.isDetecting = false
                    AudioEngineManager.shared.removeMicTap()
                }
            }
        }
        return stream
    }

    /// Process a mic buffer and yield a pitch result.
    nonisolated private static func handleMicTap(
        buffer: AVAudioPCMBuffer,
        continuation: AsyncStream<PitchResult>.Continuation,
        refPitch: Double,
        yinThreshold: Double
    ) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        let amplitude = Double(rms)

        guard amplitude > 0.002 else {
            continuation.yield(silenceResult(amplitude: amplitude))
            return
        }

        let detection = detectPitchWithConfidence(
            buffer: channelData, frameCount: frameLength,
            sampleRate: buffer.format.sampleRate, threshold: yinThreshold
        )

        guard detection.frequency > 0,
              let (noteName, octave, cents) = try? SwarUtility.frequencyToNote(
                  detection.frequency, referencePitch: refPitch
              )
        else {
            continuation.yield(silenceResult(amplitude: amplitude))
            return
        }

        continuation.yield(PitchResult(
            frequency: detection.frequency, amplitude: amplitude,
            noteName: noteName, octave: octave,
            centsOffset: cents, confidence: detection.confidence
        ))
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

    public func stop() {
        isDetecting = false
        status = "Stopped"
        AudioEngineManager.shared.removeMicTap()
        continuation?.finish()
        continuation = nil
    }

    // MARK: - YIN Pitch Detection

    /// Raw detection result containing frequency and confidence.
    private struct YINDetectionResult {
        let frequency: Double
        let confidence: Double
    }

    /// YIN autocorrelation pitch detection with spectral confidence.
    ///
    /// Returns both the detected frequency and a confidence metric based on
    /// YIN's cumulative mean normalized difference function (CMNDF).
    /// Confidence = 1.0 - cmndf[bestTau], which naturally measures signal clarity.
    nonisolated private static func detectPitchWithConfidence(
        buffer: UnsafePointer<Float>,
        frameCount: Int,
        sampleRate: Double,
        threshold: Double
    ) -> YINDetectionResult {
        let halfLength = frameCount / 2
        guard halfLength > 0 else {
            return YINDetectionResult(frequency: 0, confidence: 0)
        }

        // Step 1: Compute difference function d(tau)
        var difference = [Float](repeating: 0, count: halfLength)
        for tau in 0..<halfLength {
            var sum: Float = 0
            for i in 0..<halfLength {
                let delta = buffer[i] - buffer[i + tau]
                sum += delta * delta
            }
            difference[tau] = sum
        }

        // Step 2: Cumulative mean normalized difference function d'(tau)
        var cumulativeNorm = [Float](repeating: 0, count: halfLength)
        cumulativeNorm[0] = 1.0
        var runningSum: Float = 0
        for tau in 1..<halfLength {
            runningSum += difference[tau]
            if runningSum > 0 {
                cumulativeNorm[tau] = difference[tau] * Float(tau) / runningSum
            } else {
                cumulativeNorm[tau] = 1.0
            }
        }

        // Step 3: Absolute threshold — find first dip below threshold
        let minTau = Int(sampleRate / 4000.0)
        for tau in minTau..<halfLength where cumulativeNorm[tau] < Float(threshold) {
            // Step 4: Parabolic interpolation for sub-sample accuracy
            let refinedTau = parabolicInterpolation(cumulativeNorm, tau: tau)
            let frequency = sampleRate / Double(refinedTau)
            if frequency > 50, frequency < 4000 {
                let confidence = SpectralConfidence.fromYIN(
                    cmndfAtBestTau: cumulativeNorm[tau]
                )
                return YINDetectionResult(
                    frequency: frequency, confidence: confidence
                )
            }
        }

        return YINDetectionResult(frequency: 0, confidence: 0)
    }

    /// Parabolic interpolation around a detected minimum for sub-sample accuracy.
    nonisolated private static func parabolicInterpolation(_ values: [Float], tau: Int) -> Double {
        guard tau > 0, tau < values.count - 1 else { return Double(tau) }

        let s0 = Double(values[tau - 1])
        let s1 = Double(values[tau])
        let s2 = Double(values[tau + 1])

        let denom = 2.0 * (2.0 * s1 - s2 - s0)
        guard abs(denom) > 1e-10 else { return Double(tau) }

        let adjustment = (s2 - s0) / denom
        return Double(tau) + adjustment
    }
}

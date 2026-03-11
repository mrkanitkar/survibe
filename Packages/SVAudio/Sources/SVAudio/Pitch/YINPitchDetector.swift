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
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)
                guard frameLength > 0 else { return }

                // Calculate amplitude first so UI always gets live level feedback
                var rms: Float = 0
                vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
                let amplitude = Double(rms)

                // Below noise floor — yield silence result for live meter
                guard amplitude > 0.002 else {
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

                let frequency = YINPitchDetector.detectPitch(
                    buffer: channelData,
                    frameCount: frameLength,
                    sampleRate: buffer.format.sampleRate,
                    threshold: yinThreshold
                )

                if frequency > 0 {
                    let (noteName, octave, cents) = SwarUtility.frequencyToNote(
                        frequency, referencePitch: refPitch
                    )
                    let confidence = min(1.0, amplitude * 2.0)

                    let result = PitchResult(
                        frequency: frequency,
                        amplitude: amplitude,
                        noteName: noteName,
                        octave: octave,
                        centsOffset: cents,
                        confidence: confidence
                    )
                    continuation.yield(result)
                } else {
                    // No pitch detected but mic is active — yield amplitude-only
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

            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.isDetecting = false
                    AudioEngineManager.shared.removeMicTap()
                }
            }
        }
        return stream
    }

    public func stop() {
        isDetecting = false
        status = "Stopped"
        AudioEngineManager.shared.removeMicTap()
        continuation?.finish()
        continuation = nil
    }

    // MARK: - YIN Pitch Detection

    /// YIN autocorrelation pitch detection algorithm.
    /// Returns detected frequency in Hz, or 0 if no pitch detected.
    nonisolated private static func detectPitch(
        buffer: UnsafePointer<Float>,
        frameCount: Int,
        sampleRate: Double,
        threshold: Double
    ) -> Double {
        let halfLength = frameCount / 2
        guard halfLength > 0 else { return 0 }

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
            // Guard against division by zero (silence)
            if runningSum > 0 {
                cumulativeNorm[tau] = difference[tau] * Float(tau) / runningSum
            } else {
                cumulativeNorm[tau] = 1.0
            }
        }

        // Step 3: Absolute threshold — find first dip below threshold
        let minTau = Int(sampleRate / 4000.0) // ~4000 Hz max detectable
        for tau in minTau..<halfLength where cumulativeNorm[tau] < Float(threshold) {
            // Step 4: Parabolic interpolation for sub-sample accuracy
            let refinedTau = parabolicInterpolation(cumulativeNorm, tau: tau)
            let frequency = sampleRate / Double(refinedTau)
            if frequency > 50 && frequency < 4000 {
                return frequency
            }
        }

        return 0
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

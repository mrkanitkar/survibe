import Foundation
import AVFoundation
import Accelerate

/// Fallback YIN autocorrelation pitch detector using Accelerate/vDSP.
/// Uses direct AVAudioEngine installTap for buffer access.
/// Independent of AudioKit — works with raw AVAudioEngine.
public final class YINPitchDetector: PitchDetectorProtocol, @unchecked Sendable {
    private var continuation: AsyncStream<PitchResult>.Continuation?
    private var isDetecting = false

    /// Reference pitch for frequency-to-note conversion (default: A4 = 440 Hz).
    public var referencePitch: Double = 440.0

    /// YIN threshold (lower = stricter, typical range 0.1 to 0.2).
    public var threshold: Double = 0.15

    public init() {}

    public func start() -> AsyncStream<PitchResult> {
        let stream = AsyncStream<PitchResult> { continuation in
            self.continuation = continuation
            self.isDetecting = true

            AudioEngineManager.shared.installMicTap { [weak self] buffer, _ in
                guard let self, self.isDetecting else { return }

                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)

                let frequency = self.detectPitch(
                    buffer: channelData,
                    frameCount: frameLength,
                    sampleRate: buffer.format.sampleRate
                )

                guard frequency > 0 else { return }

                // Calculate amplitude (RMS)
                var rms: Float = 0
                vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
                let amplitude = Double(rms)

                guard amplitude > 0.01 else { return }

                let (noteName, octave, cents) = self.frequencyToNote(frequency)
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
            }

            continuation.onTermination = { [weak self] _ in
                self?.isDetecting = false
                AudioEngineManager.shared.removeMicTap()
            }
        }
        return stream
    }

    public func stop() {
        isDetecting = false
        AudioEngineManager.shared.removeMicTap()
        continuation?.finish()
        continuation = nil
    }

    // MARK: - YIN Pitch Detection

    /// YIN autocorrelation pitch detection algorithm.
    /// Returns detected frequency in Hz, or 0 if no pitch detected.
    private func detectPitch(buffer: UnsafePointer<Float>, frameCount: Int, sampleRate: Double) -> Double {
        let halfLength = frameCount / 2
        guard halfLength > 0 else { return 0 }

        // Step 1: Compute difference function d(τ)
        var difference = [Float](repeating: 0, count: halfLength)
        for tau in 0..<halfLength {
            var sum: Float = 0
            for i in 0..<halfLength {
                let delta = buffer[i] - buffer[i + tau]
                sum += delta * delta
            }
            difference[tau] = sum
        }

        // Step 2: Cumulative mean normalized difference function d'(τ)
        var cumulativeNorm = [Float](repeating: 0, count: halfLength)
        cumulativeNorm[0] = 1.0
        var runningSum: Float = 0
        for tau in 1..<halfLength {
            runningSum += difference[tau]
            cumulativeNorm[tau] = difference[tau] * Float(tau) / runningSum
        }

        // Step 3: Absolute threshold — find first dip below threshold
        // Minimum tau corresponds to maximum detectable frequency (~20 Hz minimum pitch)
        let minTau = Int(sampleRate / 4000.0) // ~4000 Hz max detectable
        for tau in minTau..<halfLength {
            if cumulativeNorm[tau] < Float(threshold) {
                // Step 4: Parabolic interpolation for sub-sample accuracy
                let refinedTau = parabolicInterpolation(cumulativeNorm, tau: tau)
                let frequency = sampleRate / Double(refinedTau)
                // Sanity check: human vocal range + instrument range (50–4000 Hz)
                if frequency > 50 && frequency < 4000 {
                    return frequency
                }
            }
        }

        return 0
    }

    /// Parabolic interpolation around a detected minimum for sub-sample accuracy.
    private func parabolicInterpolation(_ values: [Float], tau: Int) -> Double {
        guard tau > 0, tau < values.count - 1 else { return Double(tau) }

        let s0 = Double(values[tau - 1])
        let s1 = Double(values[tau])
        let s2 = Double(values[tau + 1])

        let adjustment = (s2 - s0) / (2.0 * (2.0 * s1 - s2 - s0))
        return Double(tau) + adjustment
    }

    // MARK: - Frequency to Note Conversion

    /// Convert a frequency to the nearest Swar note name, octave, and cents offset.
    private func frequencyToNote(_ frequency: Double) -> (String, Int, Double) {
        let midiNote = 69.0 + 12.0 * log2(frequency / referencePitch)
        let roundedMidi = Int(round(midiNote))
        let centsOffset = (midiNote - Double(roundedMidi)) * 100.0

        let swarIndex = ((roundedMidi - 60) % 12 + 12) % 12
        let octave = (roundedMidi - 60) / 12 + 4

        let swarNames = ["Sa", "Komal Re", "Re", "Komal Ga", "Ga", "Ma",
                         "Tivra Ma", "Pa", "Komal Dha", "Dha", "Komal Ni", "Ni"]
        let noteName = swarNames[swarIndex]

        return (noteName, octave, centsOffset)
    }
}

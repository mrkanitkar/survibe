import Foundation
import AVFoundation
import Accelerate
import AudioKit
import SoundpipeAudioKit

/// Autocorrelation-based pitch detector using Accelerate/vDSP.
/// Uses direct AVAudioEngine installTap for buffer access.
///
/// Note: PitchTap (SoundpipeAudioKit) requires AudioKit's Node graph which
/// conflicts with the single AVAudioEngine + AVAudioUnitSampler pattern.
/// This detector uses FFT-based autocorrelation as an alternative approach.
/// AudioKit/SoundpipeAudioKit imports are retained for future PitchTap integration
/// if engine architecture changes in Sprint 2+.
@MainActor
public final class AudioKitPitchDetector: PitchDetectorProtocol {
    private var continuation: AsyncStream<PitchResult>.Continuation?
    private var isDetecting = false

    /// Reference pitch for frequency-to-note conversion (default: A4 = 440 Hz).
    public var referencePitch: Double = 440.0

    public init() {}

    public func start() -> AsyncStream<PitchResult> {
        let stream = AsyncStream<PitchResult> { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            self.continuation = continuation
            self.isDetecting = true

            let refPitch = self.referencePitch

            AudioEngineManager.shared.installMicTap { buffer, _ in
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)

                let frequency = AudioKitPitchDetector.detectPitch(
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

                let (noteName, octave, cents) = SwarUtility.frequencyToNote(frequency, referencePitch: refPitch)
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
        AudioEngineManager.shared.removeMicTap()
        continuation?.finish()
        continuation = nil
    }

    // MARK: - Autocorrelation Pitch Detection (vDSP)

    /// Autocorrelation-based pitch detection using Accelerate vDSP.
    /// Uses vDSP_correlate for proper normalized autocorrelation.
    nonisolated private static func detectPitch(buffer: UnsafePointer<Float>, frameCount: Int, sampleRate: Double) -> Double {
        let halfLength = frameCount / 2
        guard halfLength > 0 else { return 0 }

        // Compute autocorrelation via dot product at each lag
        var autocorrelation = [Float](repeating: 0, count: halfLength)
        let bufferArray = Array(UnsafeBufferPointer(start: buffer, count: frameCount))

        bufferArray.withUnsafeBufferPointer { bufPtr in
            guard let baseAddress = bufPtr.baseAddress else { return }
            for lag in 0..<halfLength {
                var sum: Float = 0
                vDSP_dotpr(baseAddress, 1, baseAddress + lag, 1, &sum, vDSP_Length(halfLength))
                autocorrelation[lag] = sum
            }
        }

        // Normalize by the zero-lag value
        guard autocorrelation[0] > 0 else { return 0 }
        var invNorm: Float = 1.0 / autocorrelation[0]
        // Use separate output to avoid overlapping access
        var normalized = [Float](repeating: 0, count: halfLength)
        vDSP_vsmul(&autocorrelation, 1, &invNorm, &normalized, 1, vDSP_Length(halfLength))
        autocorrelation = normalized

        // Find first peak after the initial decline
        let minLag = Int(sampleRate / 4000.0) // Max detectable ~4000 Hz
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
            if !declining && autocorrelation[lag] < autocorrelation[lag - 1] {
                break
            }
        }

        guard bestLag > 0, bestVal > 0.3 else { return 0 }

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

        let frequency = sampleRate / refinedLag
        return (frequency > 50 && frequency < 4000) ? frequency : 0
    }
}

import Foundation
import AVFoundation
import Accelerate
import AudioKit
import SoundpipeAudioKit

/// Primary pitch detection using SoundpipeAudioKit.
/// Buffer size: 2048 samples (~46ms at 44100 Hz).
///
/// Note: PitchTap requires AudioKit's Node type. Since we use a single
/// AVAudioEngine with AVAudioUnitSampler (per WWDC best practice), the
/// direct PitchTap approach may conflict. This implementation uses
/// autocorrelation via installTap as a compatible approach. If AudioKit's
/// PitchTap can be integrated without conflict, swap the detection method.
public final class AudioKitPitchDetector: PitchDetectorProtocol, @unchecked Sendable {
    private var continuation: AsyncStream<PitchResult>.Continuation?
    private var isDetecting = false

    /// Reference pitch for frequency-to-note conversion (default: A4 = 440 Hz).
    public var referencePitch: Double = 440.0

    public init() {}

    public func start() -> AsyncStream<PitchResult> {
        let stream = AsyncStream<PitchResult> { continuation in
            self.continuation = continuation
            self.isDetecting = true

            // Use direct installTap approach compatible with single AVAudioEngine
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

    // MARK: - Autocorrelation Pitch Detection

    /// Autocorrelation-based pitch detection using Accelerate vDSP.
    private func detectPitch(buffer: UnsafePointer<Float>, frameCount: Int, sampleRate: Double) -> Double {
        let halfLength = frameCount / 2
        guard halfLength > 0 else { return 0 }

        // Compute autocorrelation via vDSP_conv
        var autocorrelation = [Float](repeating: 0, count: halfLength)
        var bufferCopy = Array(UnsafeBufferPointer(start: buffer, count: frameCount))
        vDSP_conv(&bufferCopy, 1, &bufferCopy, 1, &autocorrelation, 1, vDSP_Length(halfLength), vDSP_Length(frameCount))

        // Normalize by the zero-lag value
        if autocorrelation[0] > 0 {
            let norm = autocorrelation[0]
            for i in 0..<halfLength {
                autocorrelation[i] /= norm
            }
        }

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

        let frequency = sampleRate / Double(bestLag)
        return (frequency > 50 && frequency < 4000) ? frequency : 0
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

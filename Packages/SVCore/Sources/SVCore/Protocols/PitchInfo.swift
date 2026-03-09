import Foundation

/// Shared pitch detection result, used by SVAudio and SVLearning.
public struct PitchInfo: Sendable {
    public let frequency: Double
    public let amplitude: Double
    public let noteName: String
    public let octave: Int
    public let centsOffset: Double

    public init(
        frequency: Double,
        amplitude: Double,
        noteName: String,
        octave: Int,
        centsOffset: Double
    ) {
        self.frequency = frequency
        self.amplitude = amplitude
        self.noteName = noteName
        self.octave = octave
        self.centsOffset = centsOffset
    }
}

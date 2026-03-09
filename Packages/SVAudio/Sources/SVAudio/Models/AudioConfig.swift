import Foundation

/// Audio engine configuration parameters.
public struct AudioConfig: Sendable {
    /// Sample rate in Hz (default: 44100).
    public let sampleRate: Double

    /// Buffer size in frames (default: 2048 for ~46ms latency at 44100 Hz).
    public let bufferSize: UInt32

    /// Number of audio channels (default: 1 for mono mic input).
    public let channelCount: UInt32

    public init(
        sampleRate: Double = 44100,
        bufferSize: UInt32 = 2048,
        channelCount: UInt32 = 1
    ) {
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
        self.channelCount = channelCount
    }

    /// Default configuration for pitch detection.
    public static let pitchDetection = AudioConfig()

    /// Latency in milliseconds for current buffer size and sample rate.
    public var latencyMs: Double {
        Double(bufferSize) / sampleRate * 1000.0
    }
}

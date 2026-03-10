import Foundation

/// Protocol defining voice synthesis/processing operations.
/// Sprint 0 stub — full implementation in Sprint 2+.
public protocol VoiceProvider: Sendable {
    /// The display name of this voice provider.
    var name: String { get }

    /// Whether this provider is currently available.
    var isAvailable: Bool { get }

    /// Synthesize speech from text.
    /// - Parameter text: The text to synthesize
    /// - Returns: Audio data of the synthesized speech
    func synthesize(text: String) async throws -> Data
}

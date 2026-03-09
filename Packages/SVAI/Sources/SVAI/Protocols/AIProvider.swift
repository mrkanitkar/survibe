import Foundation

/// Protocol for AI service providers (on-device or cloud).
public protocol AIProvider: Sendable {
    /// Generate a response for the given prompt.
    func generate(prompt: String) async throws -> String

    /// Whether this provider is currently available.
    var isAvailable: Bool { get }

    /// Display name of this provider.
    var name: String { get }
}

import Foundation

/// Renders Sargam notation for display in lesson and practice views.
/// Full implementation in Sprint 1.
public struct SargamRenderer: Sendable {
    public init() {}

    /// Render a sequence of swar names into a formatted notation string.
    public func render(notes: [String]) -> String {
        // Sprint 1: Proper notation rendering with spacing, octave markers
        notes.joined(separator: " ")
    }
}

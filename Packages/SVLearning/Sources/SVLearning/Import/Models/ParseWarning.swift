import Foundation

/// A warning generated during notation parsing or validation.
///
/// Warnings are non-fatal. The import pipeline presents them to the user
/// via the smart warnings UI and allows the user to proceed anyway.
public struct ParseWarning: Sendable, Identifiable {

    /// Severity level of the warning.
    public enum Severity: String, Sendable {
        /// Informational — import will succeed, minor quality note.
        case info
        /// Warning — import will succeed but accuracy may be reduced.
        case warning
        /// Error — import will fail unless the user corrects the input.
        case error
    }

    public let id: UUID
    /// Human-readable description of the warning.
    public let message: String
    /// Severity of the warning.
    public let severity: Severity
    /// Zero-based index of the note that triggered this warning. Nil for global warnings.
    public let noteIndex: Int?

    /// Creates a parse warning.
    ///
    /// - Parameters:
    ///   - message: Human-readable description.
    ///   - severity: Severity level.
    ///   - noteIndex: Index of the offending note, if applicable.
    public init(message: String, severity: Severity, noteIndex: Int? = nil) {
        self.id = UUID()
        self.message = message
        self.severity = severity
        self.noteIndex = noteIndex
    }
}

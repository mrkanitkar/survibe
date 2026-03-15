import Foundation

/// The raw input provided by the user for song import.
///
/// Wraps the raw string or data payload along with an optional filename hint
/// that aids format detection.
public struct NotationInput: Sendable {

    /// The detected or declared format of this input.
    public enum Format: String, Sendable, CaseIterable {
        /// Indian sargam notation: Sa Re Ga Ma Pa Dha Ni
        case sargam
        /// Western staff notation: C D E F G A B with octave numbers
        case western
        /// MusicXML document (ISO standard)
        case musicXML
        /// Unknown — format detection required
        case unknown
    }

    /// Raw text content (for sargam, western, paste inputs).
    public let text: String

    /// Optional filename hint (e.g. "song.xml") to assist format detection.
    public let filenameHint: String?

    /// Declared format, or `.unknown` if auto-detection is needed.
    public let declaredFormat: Format

    /// Creates a notation input from raw text.
    ///
    /// - Parameters:
    ///   - text: Raw notation text from the user.
    ///   - filenameHint: Optional filename (e.g. from a file picker) to assist format detection.
    ///   - declaredFormat: Format declared by the UI tab. Use `.unknown` for paste input.
    public init(text: String, filenameHint: String? = nil, declaredFormat: Format = .unknown) {
        self.text = text
        self.filenameHint = filenameHint
        self.declaredFormat = declaredFormat
    }
}

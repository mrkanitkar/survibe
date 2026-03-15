import Foundation

/// Parses raw notation text into a structured `ParsedNotation`.
///
/// Each format (Sargam, Western, MusicXML) has its own conforming type.
/// Implementations must be stateless — all input is passed via the method parameter.
public protocol NotationParserProtocol: Sendable {

    /// The format this parser handles.
    var supportedFormat: NotationInput.Format { get }

    /// Parses raw notation text into a structured result.
    ///
    /// - Parameter input: The raw notation input to parse.
    /// - Returns: A `ParsedNotation` containing the note sequence and metadata.
    /// - Throws: `ImportError` if the text cannot be parsed at all.
    func parse(_ input: NotationInput) throws -> ParsedNotation
}

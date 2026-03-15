import Foundation

/// Validates a parsed notation and generates smart warnings.
///
/// Validation is non-destructive — it produces warnings but does not modify
/// the parsed notation. The import pipeline presents warnings to the user
/// before allowing save.
public protocol ImportValidatorProtocol: Sendable {

    /// Validates a parsed notation and returns any warnings.
    ///
    /// - Parameter notation: The parsed notation to validate.
    /// - Returns: An array of `ParseWarning` items. Empty array means fully valid.
    func validate(_ notation: ParsedNotation) -> [ParseWarning]
}

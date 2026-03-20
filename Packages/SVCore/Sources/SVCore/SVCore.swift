@_exported import Foundation

/// SVCore provides shared models, utilities, and foundation types
/// used across all SurVibe modules.
///
/// Re-exports `Foundation` so downstream packages that `import SVCore`
/// automatically get Foundation types without a separate import.
public enum SVCore {
    public static let version = "1.0.0"
}

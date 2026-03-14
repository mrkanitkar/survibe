import Foundation
import SVAudio

/// Lightweight scoring context that holds raga metadata for note scoring.
///
/// Created from `RagaTuningProvider.context(for:)` when a song has a raga name.
/// Passed to `NoteScoreCalculator.score()` to enable raga-aware scoring:
/// - Uses JI cents deviation instead of 12ET cents for pitch accuracy
/// - Penalizes out-of-raga notes by capping their pitch accuracy
public struct RagaScoringContext: Sendable, Equatable {
    /// Set of allowed Swar raw values for the raga (e.g., "Sa", "Re", "Tivra Ma").
    public let allowedSwars: Set<String>

    /// Raga name for display purposes.
    public let ragaName: String

    /// Create a raga scoring context from a `RagaContext`.
    ///
    /// - Parameter ragaContext: The raga context from `RagaTuningProvider`.
    public init(ragaContext: RagaContext) {
        self.allowedSwars = ragaContext.allowedSwarNames
        self.ragaName = ragaContext.ragaName
    }

    /// Create a raga scoring context from a raga name.
    ///
    /// Returns `nil` if the raga is not recognized by `RagaTuningProvider`.
    ///
    /// - Parameter ragaName: Name of the raga (e.g., "Yaman").
    /// - Returns: A scoring context, or `nil` if the raga is unknown.
    public static func from(ragaName: String) -> RagaScoringContext? {
        guard let context = RagaTuningProvider.context(for: ragaName) else {
            return nil
        }
        return RagaScoringContext(ragaContext: context)
    }

    /// Check whether a note is in the raga's scale.
    ///
    /// - Parameter noteName: Swar name (e.g., "Ma", "Tivra Ma").
    /// - Returns: `true` if the note is in the raga.
    public func isNoteInRaga(_ noteName: String) -> Bool {
        allowedSwars.contains(noteName)
    }
}

import Foundation

/// A fully validated, normalised song ready to be saved to SwiftData.
///
/// This DTO is the final output of the import pipeline. The app target's
/// `ContentImportManager` maps this into a `Song` @Model object.
public struct ImportedSongDTO: Sendable {

    /// Human-readable title for the song.
    public let title: String

    /// Composer or artist name.
    public let artist: String

    /// ISO 639-1 language code (e.g. "hi", "mr", "en").
    public let language: String

    /// Difficulty level 1–5.
    public let difficulty: Int

    /// Category string (e.g. "folk", "classical").
    public let category: String

    /// Tempo in BPM.
    public let tempo: Int

    /// Estimated duration in seconds.
    public let durationSeconds: Int

    /// JSON-encoded sargam notes. Nil if source format is western-only.
    public let sargamNotationData: Data?

    /// JSON-encoded western notes. Nil if source format is sargam-only.
    public let westernNotationData: Data?

    /// Generated MIDI binary data. Nil if synthesis was skipped.
    public let midiData: Data?

    /// Key signature string.
    public let keySignature: String

    /// Time signature string.
    public let timeSignature: String

    /// Source discriminator — always "user" for imported songs.
    public let source: String

    /// Warnings that were accepted by the user before saving.
    public let acceptedWarnings: [ParseWarning]

    /// Creates an imported song DTO.
    public init(
        title: String,
        artist: String,
        language: String,
        difficulty: Int,
        category: String,
        tempo: Int,
        durationSeconds: Int,
        sargamNotationData: Data?,
        westernNotationData: Data?,
        midiData: Data?,
        keySignature: String,
        timeSignature: String,
        source: String = "user",
        acceptedWarnings: [ParseWarning] = []
    ) {
        self.title = title
        self.artist = artist
        self.language = language
        self.difficulty = difficulty
        self.category = category
        self.tempo = tempo
        self.durationSeconds = durationSeconds
        self.sargamNotationData = sargamNotationData
        self.westernNotationData = westernNotationData
        self.midiData = midiData
        self.keySignature = keySignature
        self.timeSignature = timeSignature
        self.source = source
        self.acceptedWarnings = acceptedWarnings
    }
}

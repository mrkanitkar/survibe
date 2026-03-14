import Foundation

/// Data Transfer Object for importing songs from JSON files.
///
/// Maps directly to the JSON song schema defined in SPEC-D02-011.
/// The import pipeline reads JSON → `SongImportDTO` → validates → `Song` @Model.
///
/// All fields use Codable types; no SwiftData dependencies.
/// This DTO lives in SVLearning (not the app target) so it can be
/// tested independently without a ModelContainer.
public struct SongImportDTO: Codable, Equatable, Sendable {
    // MARK: - Required Fields

    /// Unique slug identifier (kebab-case, e.g., "song-001-raag-yaman-hindi-folk").
    public let slugId: String

    /// Display title in the song's primary language.
    public let title: String

    /// Artist or composer name.
    public let artist: String

    /// ISO 639-1 language code ("hi", "mr", "en").
    public let language: String

    /// Difficulty level (1–5).
    public let difficulty: Int

    /// Song category ("folk", "devotional", "film", "classical", "nursery", "popular").
    public let category: String

    /// Tempo in beats per minute (1–300).
    public let tempo: Int

    /// Duration in seconds.
    public let durationSeconds: Int

    /// Display order (ascending).
    public let sortOrder: Int

    /// Base64-encoded MIDI binary data. Optional — null or absent means no MIDI.
    public let midiData: String?

    /// Array of Sargam notes.
    public let sargamNotation: [SargamNoteDTO]

    /// Array of Western notes.
    public let westernNotation: [WesternNoteDTO]

    // MARK: - Optional Fields

    /// Raga classification (not all songs map to a classical raga).
    public let ragaName: String?

    /// Whether this song is available to free-tier users.
    public let isFree: Bool?

    /// Key signature for staff notation (e.g., "C", "G", "Bb").
    /// Defaults to C Major when absent.
    public let keySignature: String?

    /// Time signature for staff notation (e.g., "4/4", "3/4", "6/8").
    /// Defaults to 4/4 when absent.
    public let timeSignature: String?

    // MARK: - Validation

    /// Validates the DTO against schema rules.
    ///
    /// - Throws: `SongImportError` with details about the first validation failure.
    public func validate() throws {
        guard !slugId.isEmpty else {
            throw SongImportError.missingField("slugId")
        }
        guard !title.isEmpty, title.count <= 100 else {
            throw SongImportError.invalidField("title", reason: "must be 1–100 characters")
        }
        guard !artist.isEmpty, artist.count <= 100 else {
            throw SongImportError.invalidField("artist", reason: "must be 1–100 characters")
        }
        guard ["hi", "mr", "en"].contains(language) else {
            throw SongImportError.invalidField("language", reason: "must be hi, mr, or en")
        }
        guard (1...5).contains(difficulty) else {
            throw SongImportError.invalidField("difficulty", reason: "must be 1–5")
        }
        guard ["folk", "devotional", "film", "classical", "nursery", "popular"].contains(category) else {
            throw SongImportError.invalidField("category", reason: "invalid category")
        }
        guard (1...300).contains(tempo) else {
            throw SongImportError.invalidField("tempo", reason: "must be 1–300 BPM")
        }
        guard durationSeconds > 0, durationSeconds <= 600 else {
            throw SongImportError.invalidField("durationSeconds", reason: "must be 1–600")
        }
        guard !sargamNotation.isEmpty else {
            throw SongImportError.missingField("sargamNotation")
        }
        guard !westernNotation.isEmpty else {
            throw SongImportError.missingField("westernNotation")
        }
    }
}

/// A single Sargam note in the import JSON.
public struct SargamNoteDTO: Codable, Equatable, Sendable {
    /// Swara name: Sa, Re, Ga, Ma, Pa, Dha, Ni.
    public let note: String
    /// Octave (0–8).
    public let octave: Int
    /// Duration in quarter-note beats.
    public let duration: Double
    /// Optional modifier: "komal" or "tivra".
    public let modifier: String?

    public init(note: String, octave: Int, duration: Double, modifier: String? = nil) {
        self.note = note
        self.octave = octave
        self.duration = duration
        self.modifier = modifier
    }
}

/// A single Western note in the import JSON.
public struct WesternNoteDTO: Codable, Equatable, Sendable {
    /// Note name with octave (e.g., "C4", "D#4").
    public let note: String
    /// Duration in quarter-note beats.
    public let duration: Double
    /// MIDI note number (0–127).
    public let midiNumber: Int

    public init(note: String, duration: Double, midiNumber: Int) {
        self.note = note
        self.duration = duration
        self.midiNumber = midiNumber
    }
}

/// Errors thrown during song import validation.
public enum SongImportError: Error, Sendable, CustomStringConvertible {
    /// A required field is missing or empty.
    case missingField(String)
    /// A field value is outside the allowed range or format.
    case invalidField(String, reason: String)
    /// The JSON data could not be decoded.
    case decodingFailed(String)

    public var description: String {
        switch self {
        case .missingField(let field):
            "Missing required field: \(field)"
        case .invalidField(let field, let reason):
            "Invalid field '\(field)': \(reason)"
        case .decodingFailed(let detail):
            "JSON decoding failed: \(detail)"
        }
    }
}

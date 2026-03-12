import Foundation

/// Composite model containing all information needed to render a single note
/// on a staff notation canvas.
///
/// Decoupled from the app target's `WesternNote` model — stores raw
/// MIDI number, note name, and duration so that SVLearning has no
/// dependency on @Model types. Created by `NoteLayoutEngine` after
/// computing layout, measure assignment, and accidental resolution.
public struct StaffNoteInfo: Sendable, Equatable {

    // MARK: - Accidental

    /// Accidental marking to display next to a notehead.
    ///
    /// Accidentals are resolved per-measure: a sharp or flat is shown
    /// on the first occurrence, and a natural cancels a key signature
    /// alteration or courtesy accidental.
    public enum Accidental: String, Sendable, Equatable {
        /// Sharp — raises pitch by one semitone.
        case sharp = "♯"

        /// Flat — lowers pitch by one semitone.
        case flat = "♭"

        /// Natural — cancels a previous accidental or key signature.
        case natural = "♮"
    }

    // MARK: - Note Data

    /// MIDI note number (0–127).
    public let midiNumber: Int

    /// Western note name (e.g., "C", "F#", "Bb").
    public let noteName: String

    /// Duration in beats (quarter note = 1.0).
    public let duration: Double

    /// Whether this note info represents a rest rather than a sounded note.
    public let isRest: Bool

    // MARK: - Visual Properties

    /// The notehead shape based on duration.
    public let noteheadType: NoteheadType

    /// Whether the note is dotted (1.5x base duration).
    public let isDotted: Bool

    /// Vertical position on the staff (0 = bottom line E4).
    public let staffYOffset: Int

    /// Direction the stem should be drawn.
    public let stemDirection: StemDirection

    /// Ledger lines needed for this note.
    public let ledgerLines: LedgerLineInfo

    /// Accidental to display, if any.
    public let accidental: Accidental?

    // MARK: - Layout Properties

    /// Horizontal position in points from the start of the notation area.
    public var xPosition: Double

    /// Zero-based measure number this note belongs to.
    public var measureNumber: Int

    // MARK: - Initialization

    /// Create a staff note info with all rendering properties.
    ///
    /// - Parameters:
    ///   - midiNumber: MIDI note number.
    ///   - noteName: Western note name string.
    ///   - duration: Duration in beats.
    ///   - isRest: Whether this is a rest.
    ///   - noteheadType: Visual notehead shape.
    ///   - isDotted: Whether a dot should be drawn.
    ///   - staffYOffset: Vertical staff position.
    ///   - stemDirection: Stem direction.
    ///   - ledgerLines: Ledger line requirements.
    ///   - accidental: Accidental marking, if any.
    ///   - xPosition: Horizontal layout position.
    ///   - measureNumber: Measure assignment.
    public init(
        midiNumber: Int,
        noteName: String,
        duration: Double,
        isRest: Bool = false,
        noteheadType: NoteheadType,
        isDotted: Bool,
        staffYOffset: Int,
        stemDirection: StemDirection,
        ledgerLines: LedgerLineInfo,
        accidental: Accidental?,
        xPosition: Double = 0,
        measureNumber: Int = 0
    ) {
        self.midiNumber = midiNumber
        self.noteName = noteName
        self.duration = duration
        self.isRest = isRest
        self.noteheadType = noteheadType
        self.isDotted = isDotted
        self.staffYOffset = staffYOffset
        self.stemDirection = stemDirection
        self.ledgerLines = ledgerLines
        self.accidental = accidental
        self.xPosition = xPosition
        self.measureNumber = measureNumber
    }

    /// Create a rest note info at the given position.
    ///
    /// Rests have no pitch, so staff position defaults to the middle
    /// line (position 4) and no accidental or ledger lines are needed.
    ///
    /// - Parameters:
    ///   - duration: Duration in beats.
    ///   - xPosition: Horizontal layout position.
    ///   - measureNumber: Measure assignment.
    /// - Returns: A `StaffNoteInfo` configured as a rest.
    public static func rest(
        duration: Double,
        xPosition: Double = 0,
        measureNumber: Int = 0
    ) -> StaffNoteInfo {
        StaffNoteInfo(
            midiNumber: 0,
            noteName: "",
            duration: duration,
            isRest: true,
            noteheadType: NoteheadType(duration: duration),
            isDotted: DurationHelper.isDotted(duration: duration),
            staffYOffset: 4,
            stemDirection: .up,
            ledgerLines: .none,
            accidental: nil,
            xPosition: xPosition,
            measureNumber: measureNumber
        )
    }
}

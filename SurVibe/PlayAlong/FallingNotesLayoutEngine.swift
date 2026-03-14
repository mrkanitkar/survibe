import Foundation
import SwiftUI

/// Pure computation engine for falling notes layout.
///
/// All methods are static and have no side effects, making them
/// trivially testable and safe to call from any isolation context.
/// This engine handles all coordinate math for the falling notes
/// visualization without coupling to SwiftUI rendering.
enum FallingNotesLayoutEngine {

    // MARK: - Note State

    /// Scoring state of a note during play-along.
    ///
    /// Drives visual feedback: color, opacity, and optional glow.
    enum NoteState: Sendable, Equatable {
        /// Note has not yet reached the hit line.
        case upcoming
        /// Note is currently at the hit line (within tolerance window).
        case active
        /// Player hit the correct note at the right time.
        case correct
        /// Player hit the wrong note while this note was active.
        case wrong
        /// Note passed the hit line without being played.
        case missed
    }

    // MARK: - Layout Calculations

    /// Compute pixels per second based on the viewport and visible time window.
    ///
    /// This value converts time-domain positions (seconds) into spatial
    /// positions (points) so that notes scroll at a consistent speed
    /// regardless of device screen size.
    ///
    /// - Parameters:
    ///   - viewportHeight: Total height of the falling notes viewport in points.
    ///   - visibleDuration: Number of seconds of music visible at once.
    /// - Returns: Points per second conversion factor.
    static func pixelsPerSecond(viewportHeight: CGFloat, visibleDuration: TimeInterval) -> CGFloat {
        guard visibleDuration > 0 else { return 0 }
        return viewportHeight / visibleDuration
    }

    /// Compute the Y position for a note at the given playback time.
    ///
    /// Notes fall from top (future) to bottom (past). A note whose
    /// `noteTimestamp` equals `currentTime` appears at the bottom of the
    /// viewport (the "hit line"). Notes in the future appear higher.
    ///
    /// - Parameters:
    ///   - noteTimestamp: Absolute start time of the note in seconds.
    ///   - currentTime: Current playback position in seconds.
    ///   - pixelsPerSecond: Spatial conversion factor from ``pixelsPerSecond(viewportHeight:visibleDuration:)``.
    ///   - viewportHeight: Total height of the falling notes viewport in points.
    /// - Returns: Y offset in points from the top of the viewport.
    static func noteY(
        noteTimestamp: TimeInterval,
        currentTime: TimeInterval,
        pixelsPerSecond: CGFloat,
        viewportHeight: CGFloat
    ) -> CGFloat {
        let timeUntilHit = noteTimestamp - currentTime
        return viewportHeight - timeUntilHit * pixelsPerSecond
    }

    /// Compute the rendered height of a note rectangle.
    ///
    /// Longer notes produce taller rectangles so the player can see
    /// how long to hold. A minimum height ensures short notes remain
    /// visible and tappable.
    ///
    /// - Parameters:
    ///   - duration: Note duration in seconds.
    ///   - pixelsPerSecond: Spatial conversion factor.
    ///   - minimumHeight: Floor height in points. Default is 8.
    /// - Returns: Height of the note rectangle in points.
    static func noteHeight(
        duration: TimeInterval,
        pixelsPerSecond: CGFloat,
        minimumHeight: CGFloat = 8
    ) -> CGFloat {
        max(duration * pixelsPerSecond, minimumHeight)
    }

    /// Determine whether a note is visible within the current viewport.
    ///
    /// Used for viewport culling so only on-screen notes are rendered.
    /// A padding value extends the check region above and below the
    /// viewport to prevent pop-in during fast scrolling.
    ///
    /// - Parameters:
    ///   - noteY: Y position of the note's top edge (from ``noteY(noteTimestamp:currentTime:pixelsPerSecond:viewportHeight:)``).
    ///   - noteHeight: Height of the note rectangle (from ``noteHeight(duration:pixelsPerSecond:minimumHeight:)``).
    ///   - viewportHeight: Total height of the viewport.
    ///   - padding: Extra points beyond the viewport edges to check. Default is 50.
    /// - Returns: `true` if any part of the note is within the padded viewport.
    static func isNoteVisible(
        noteY: CGFloat,
        noteHeight: CGFloat,
        viewportHeight: CGFloat,
        padding: CGFloat = 50
    ) -> Bool {
        let noteBottom = noteY + noteHeight
        let noteTop = noteY
        return noteBottom > -padding && noteTop < viewportHeight + padding
    }

    /// Find the horizontal center X position for a MIDI note.
    ///
    /// Looks up the note in the provided key position array reported
    /// by `InteractivePianoView` via `KeyPositionPreference`.
    ///
    /// - Parameters:
    ///   - midiNote: MIDI note number to locate.
    ///   - keyPositions: Array of key positions from the piano keyboard view.
    /// - Returns: Center X of the matching key, or `nil` if the note is not on the visible keyboard.
    static func noteX(midiNote: UInt8, keyPositions: [KeyPosition]) -> CGFloat? {
        keyPositions.first { $0.midiNote == midiNote }?.centerX
    }

    /// Color for a note based on its scoring state.
    ///
    /// Returns distinct colors that provide clear visual feedback:
    /// - Upcoming notes are translucent blue.
    /// - Active notes glow yellow to draw attention.
    /// - Correct/wrong/missed use standard traffic-light metaphor.
    ///
    /// - Parameter state: The scoring state of the note.
    /// - Returns: A `Color` value for rendering.
    static func noteColor(state: NoteState) -> Color {
        switch state {
        case .upcoming: Color.blue.opacity(0.6)
        case .active: Color.yellow
        case .correct: Color.green
        case .wrong: Color.red
        case .missed: Color.gray.opacity(0.4)
        }
    }

    /// Label text to display inside a falling note.
    ///
    /// Returns the appropriate note name string based on the
    /// current notation display mode setting.
    ///
    /// - Parameters:
    ///   - swarName: Indian notation name (e.g., "Sa", "Komal Re").
    ///   - westernName: Western notation name (e.g., "C4", "Db4").
    ///   - mode: Current notation display mode preference.
    /// - Returns: The label string to render inside the note.
    static func noteLabel(
        swarName: String,
        westernName: String,
        mode: NotationDisplayMode
    ) -> String {
        switch mode {
        case .sargam, .sargamPlusSheet:
            swarName
        case .western, .sheetMusic:
            westernName
        case .dual:
            "\(swarName)\n\(westernName)"
        }
    }
}

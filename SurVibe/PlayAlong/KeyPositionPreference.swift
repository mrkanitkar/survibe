import SwiftUI

/// Preference key for reporting piano key positions from InteractivePianoView
/// up to the FallingNotesView container.
///
/// Each piano key reports its horizontal center X coordinate so that falling
/// notes can align precisely with the corresponding key on the keyboard.
///
/// ## Usage
/// ```swift
/// // In InteractivePianoView key rendering:
/// keyView
///     .anchorPreference(key: KeyPositionPreference.self, value: .center) { anchor in
///         [KeyPosition(midiNote: note, anchor: anchor)]
///     }
///
/// // In SongPlayAlongView container:
/// .overlayPreferenceValue(KeyPositionPreference.self) { positions in
///     // Use positions to align falling notes
/// }
/// ```
struct KeyPositionPreference: PreferenceKey {
    static var defaultValue: [KeyPosition] = []

    static func reduce(value: inout [KeyPosition], nextValue: () -> [KeyPosition]) {
        value.append(contentsOf: nextValue())
    }
}

/// Position data for a single piano key.
///
/// Reported by `InteractivePianoView` via `KeyPositionPreference`
/// so that `FallingNotesView` can align notes with keys.
struct KeyPosition: Equatable, Sendable {
    /// MIDI note number of the key (0–127).
    let midiNote: UInt8

    /// Center X position of the key in the coordinate space of the piano view.
    let centerX: CGFloat
}

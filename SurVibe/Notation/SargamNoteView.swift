import SwiftUI

/// Renders a single Sargam note as a colored block with modifier and octave markers.
///
/// Width is proportional to the note's duration multiplied by the zoom scale.
/// Visual treatment varies based on whether the note is currently playing,
/// has already been played, or is upcoming.
///
/// ## Layout
/// - Tivra modifier: thin line above the note block
/// - Main block: colored rectangle with rounded corners
/// - Komal modifier: dot below the note block
/// - Note label: swar name text below
/// - Octave marker: dot below (mandra/octave 3) or above (taar/octave 5),
///   none for madhya (octave 4)
struct SargamNoteView: View {

    // MARK: - Properties

    /// The Sargam note data to render.
    let note: SargamNote

    /// Zoom multiplier applied to note width. 1.0 is default size.
    let zoomScale: CGFloat

    /// Whether this note is the one currently being played.
    let isCurrentNote: Bool

    /// Whether this note has already been played in the sequence.
    let isPastNote: Bool

    /// Opacity for the note label text below the block.
    let labelOpacity: Double

    /// Whether the user has enabled reduced motion in accessibility settings.
    let reduceMotion: Bool

    /// Base width in points for a quarter note (duration 1.0) at 1.0x zoom.
    private let baseWidth: CGFloat = 44.0

    // MARK: - Computed Properties

    /// Computed note width based on duration and zoom.
    private var noteWidth: CGFloat {
        baseWidth * CGFloat(note.duration) * zoomScale
    }

    /// Background color for this swar.
    private var backgroundColor: Color {
        SargamColorMap.color(for: note.note)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            octaveAboveMarker
            tivraMarker
            noteBlock
            komalMarker
            noteLabel
            octaveBelowMarker
        }
        .frame(width: noteWidth)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Subviews

    /// Tivra modifier indicator: a thin horizontal line above the note block.
    @ViewBuilder
    private var tivraMarker: some View {
        if note.modifier == "Tivra" {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.primary)
                .frame(width: noteWidth - 8, height: 1.5)
                .opacity(0.6)
        }
    }

    /// The main colored rectangle representing the note.
    private var noteBlock: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .frame(width: noteWidth, height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        Color.primary.opacity(isCurrentNote ? 1 : 0.2),
                        lineWidth: isCurrentNote ? 2 : 0.5
                    )
            )
            .if(isCurrentNote) { view in
                view
                    .shadow(color: backgroundColor.opacity(0.6), radius: 8)
                    .scaleEffect(reduceMotion ? 1.0 : 1.15, anchor: .center)
            }
            .opacity(isPastNote ? 0.5 : (isCurrentNote ? 1.0 : 0.8))
    }

    /// Komal modifier indicator: a small dot below the note block.
    @ViewBuilder
    private var komalMarker: some View {
        if note.modifier == "Komal" {
            Circle()
                .fill(Color.primary)
                .frame(width: 6, height: 6)
                .opacity(0.6)
        }
    }

    /// The swar name label displayed below the note block.
    private var noteLabel: some View {
        Text(verbatim: note.note)
            .font(.system(size: 14, weight: .semibold))
            .frame(width: noteWidth)
            .lineLimit(1)
            .opacity(labelOpacity)
    }

    /// Dot above the note block indicating taar saptak (octave 5).
    @ViewBuilder
    private var octaveAboveMarker: some View {
        if note.octave == 5 {
            Circle()
                .fill(Color.secondary)
                .frame(width: 4, height: 4)
        }
    }

    /// Dot below the note label indicating mandra saptak (octave 3).
    @ViewBuilder
    private var octaveBelowMarker: some View {
        if note.octave == 3 {
            Circle()
                .fill(Color.secondary)
                .frame(width: 4, height: 4)
        }
    }

    // MARK: - Accessibility

    /// VoiceOver description combining note name, octave, modifier, duration, and playing state.
    private var accessibilityDescription: String {
        var parts: [String] = [note.note]

        switch note.octave {
        case 3: parts.append("low octave")
        case 4: parts.append("middle octave")
        case 5: parts.append("high octave")
        default: break
        }

        if let modifier = note.modifier {
            parts.append(modifier.lowercased())
        }

        switch note.duration {
        case 0.25: parts.append("sixteenth note")
        case 0.5: parts.append("eighth note")
        case 1.0: parts.append("quarter note")
        case 2.0: parts.append("half note")
        case 4.0: parts.append("whole note")
        default: parts.append("note")
        }

        if isCurrentNote {
            parts.append("currently playing")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Previews

#Preview("Current Note") {
    SargamNoteView(
        note: SargamNote(note: "Sa", octave: 4, duration: 1.0),
        zoomScale: 1.0,
        isCurrentNote: true,
        isPastNote: false,
        labelOpacity: 1.0,
        reduceMotion: false
    )
    .padding()
}

#Preview("Komal Modifier") {
    SargamNoteView(
        note: SargamNote(note: "Re", octave: 4, duration: 1.0, modifier: "Komal"),
        zoomScale: 1.0,
        isCurrentNote: false,
        isPastNote: false,
        labelOpacity: 1.0,
        reduceMotion: false
    )
    .padding()
}

#Preview("Tivra Modifier") {
    SargamNoteView(
        note: SargamNote(note: "Ma", octave: 4, duration: 1.0, modifier: "Tivra"),
        zoomScale: 1.0,
        isCurrentNote: false,
        isPastNote: false,
        labelOpacity: 1.0,
        reduceMotion: false
    )
    .padding()
}

#Preview("Mandra Saptak") {
    SargamNoteView(
        note: SargamNote(note: "Pa", octave: 3, duration: 2.0),
        zoomScale: 1.0,
        isCurrentNote: false,
        isPastNote: true,
        labelOpacity: 1.0,
        reduceMotion: false
    )
    .padding()
}

#Preview("Taar Saptak") {
    SargamNoteView(
        note: SargamNote(note: "Dha", octave: 5, duration: 0.5),
        zoomScale: 1.0,
        isCurrentNote: false,
        isPastNote: false,
        labelOpacity: 1.0,
        reduceMotion: false
    )
    .padding()
}

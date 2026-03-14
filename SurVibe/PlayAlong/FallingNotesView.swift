import SwiftUI

/// Canvas-based falling notes visualization for play-along mode.
///
/// Notes descend from the top of the viewport toward a "hit line" near the
/// bottom, aligned horizontally with the piano keyboard below. Uses `Canvas`
/// for efficient GPU-accelerated rendering of potentially hundreds of notes,
/// avoiding the overhead of individual SwiftUI views per note.
///
/// ## Layout Coordinate System
/// - Y = 0 is the top of the viewport (far future notes).
/// - Y = viewportHeight is the bottom (hit line / current playback position).
/// - X positions are derived from `KeyPosition` data reported by the piano keyboard.
///
/// ## Performance
/// Only notes passing the `isNoteVisible` culling check are drawn.
/// `TimelineView(.animation)` drives smooth 60 fps updates during playback.
///
/// ## Accessibility
/// When `accessibilityReduceMotion` is enabled, notes are drawn without
/// the animated glow effect on the active note, and the hit line pulse
/// is suppressed.
struct FallingNotesView: View {
    // MARK: - Input Properties

    /// All note events for the current song, sorted by timestamp.
    let noteEvents: [NoteEvent]

    /// Current playback position in seconds.
    let currentTime: TimeInterval

    /// Index of the note currently under the hit line, if any.
    let currentNoteIndex: Int?

    /// Per-note scoring states keyed by NoteEvent ID.
    let noteStates: [UUID: FallingNotesLayoutEngine.NoteState]

    /// Controls which label appears inside each note (Sargam, Western, etc.).
    let notationMode: NotationDisplayMode

    /// Horizontal positions of piano keys for note alignment.
    let keyPositions: [KeyPosition]

    /// Number of seconds of music visible in the viewport. Default is 4 seconds.
    var visibleDuration: TimeInterval = 4.0

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    /// Width of each falling note rectangle in points.
    private let noteWidth: CGFloat = 36

    /// Corner radius of note rectangles.
    private let noteCornerRadius: CGFloat = 6

    /// Height of the hit line indicator at the bottom.
    private let hitLineHeight: CGFloat = 2

    /// Distance from the bottom of the viewport to the hit line.
    private let hitLineBottomInset: CGFloat = 0

    /// Minimum font size for note labels.
    private let labelFontSize: CGFloat = 10

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let viewportHeight = geometry.size.height

            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { _ in
                Canvas { context, size in
                    drawHitLine(context: &context, size: size)
                    drawNotes(context: &context, size: size, viewportHeight: viewportHeight)
                }
                .accessibilityLabel(Text("Falling notes display", bundle: .module))
                .accessibilityHint(Text("Notes fall toward the piano keyboard. Play each note as it reaches the line.", bundle: .module))
            }
        }
    }

    // MARK: - Drawing Methods

    /// Draw the horizontal hit line near the bottom of the viewport.
    private func drawHitLine(context: inout GraphicsContext, size: CGSize) {
        let hitLineY = size.height - hitLineBottomInset
        let hitLineRect = CGRect(
            x: 0,
            y: hitLineY - hitLineHeight / 2,
            width: size.width,
            height: hitLineHeight
        )
        context.fill(
            Path(hitLineRect),
            with: .color(.white.opacity(0.6))
        )
    }

    /// Draw all visible notes as rounded rectangles with labels.
    private func drawNotes(
        context: inout GraphicsContext,
        size: CGSize,
        viewportHeight: CGFloat
    ) {
        let pps = FallingNotesLayoutEngine.pixelsPerSecond(
            viewportHeight: viewportHeight,
            visibleDuration: visibleDuration
        )

        for event in noteEvents {
            let y = FallingNotesLayoutEngine.noteY(
                noteTimestamp: event.timestamp,
                currentTime: currentTime,
                pixelsPerSecond: pps,
                viewportHeight: viewportHeight
            )
            let height = FallingNotesLayoutEngine.noteHeight(
                duration: event.duration,
                pixelsPerSecond: pps
            )

            // Viewport culling — skip off-screen notes.
            guard FallingNotesLayoutEngine.isNoteVisible(
                noteY: y,
                noteHeight: height,
                viewportHeight: viewportHeight
            ) else {
                continue
            }

            // Horizontal alignment with the piano key.
            guard let centerX = FallingNotesLayoutEngine.noteX(
                midiNote: event.midiNote,
                keyPositions: keyPositions
            ) else {
                continue
            }

            let state = noteStates[event.id] ?? .upcoming
            let color = FallingNotesLayoutEngine.noteColor(state: state)

            // Note rectangle — y is the TOP edge of the note.
            let noteRect = CGRect(
                x: centerX - noteWidth / 2,
                y: y - height,
                width: noteWidth,
                height: height
            )
            let roundedPath = Path(
                roundedRect: noteRect,
                cornerRadius: noteCornerRadius
            )

            // Active note glow (unless reduce motion is on).
            if state == .active && !reduceMotion {
                var glowContext = context
                glowContext.addFilter(.blur(radius: 6))
                glowContext.fill(roundedPath, with: .color(color.opacity(0.5)))
            }

            context.fill(roundedPath, with: .color(color))

            // Note label.
            let label = FallingNotesLayoutEngine.noteLabel(
                swarName: event.swarName,
                westernName: event.westernName,
                mode: notationMode
            )
            drawLabel(
                label,
                in: noteRect,
                context: &context,
                state: state
            )
        }
    }

    /// Draw a text label centered within a note rectangle.
    private func drawLabel(
        _ text: String,
        in rect: CGRect,
        context: inout GraphicsContext,
        state: FallingNotesLayoutEngine.NoteState
    ) {
        // Skip label if the note is too small to display text legibly.
        guard rect.height >= 16 else { return }

        let fontSize = min(labelFontSize, rect.height * 0.5)
        let textColor: Color = (state == .active || state == .correct) ? .black : .white

        let resolvedText = context.resolve(
            Text(verbatim: text)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor)
        )

        let textSize = resolvedText.measure(in: rect.size)
        let textOrigin = CGPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2
        )

        context.draw(resolvedText, at: textOrigin, anchor: .topLeading)
    }
}

// MARK: - Preview

#Preview("Falling Notes — Demo") {
    let events = (0..<12).map { index in
        NoteEvent(
            id: UUID(),
            midiNote: UInt8(60 + index),
            swarName: ["Sa", "Komal Re", "Re", "Komal Ga", "Ga", "Ma",
                        "Tivra Ma", "Pa", "Komal Dha", "Dha", "Komal Ni", "Ni"][index],
            westernName: ["C4", "Db4", "D4", "Eb4", "E4", "F4",
                          "F#4", "G4", "Ab4", "A4", "Bb4", "B4"][index],
            octave: 4,
            timestamp: TimeInterval(index) * 0.5,
            duration: 0.45,
            velocity: 100
        )
    }

    let positions = (0..<12).map { index in
        KeyPosition(midiNote: UInt8(60 + index), centerX: CGFloat(40 + index * 30))
    }

    FallingNotesView(
        noteEvents: events,
        currentTime: 2.0,
        currentNoteIndex: 4,
        noteStates: [events[4].id: .active, events[3].id: .correct, events[2].id: .correct],
        notationMode: .sargam,
        keyPositions: positions
    )
    .background(Color.black)
    .frame(height: 400)
}

import SVLearning
import SwiftUI

/// Canvas-based renderer for standard 5-line treble clef staff notation.
///
/// Draws a complete staff from an array of `WesternNote` values:
/// five staff lines, treble clef symbol, key signature accidentals,
/// time signature numerals, noteheads (filled/open), stems, beams,
/// flags, accidentals, ledger lines, augmentation dots, barlines,
/// and a highlight rectangle on the current note.
///
/// ## Design
/// - Receives `zoomScale` from the parent `NotationContainerView` (no own gesture).
/// - Uses `NoteLayoutEngine` for all position calculations.
/// - Adapts to dark mode via `@Environment(\.colorScheme)`.
/// - Respects reduce-motion for highlight animations.
struct StaffNotationRenderer: View {

    // MARK: - Properties

    /// Western notes to render on the staff.
    let notes: [WesternNote]

    /// Index of the currently playing note, if any.
    let currentNoteIndex: Int?

    /// Key signature for accidental resolution and display.
    let keySignature: KeySignature

    /// Time signature for measure division and display.
    let timeSignature: TimeSignature

    /// Zoom scale from the parent container.
    let zoomScale: CGFloat

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    /// Vertical spacing between adjacent staff lines in points.
    private let staffSpacing: CGFloat = 10.0

    /// Height of the staff (4 spaces × spacing).
    private var staffHeight: CGFloat { staffSpacing * 4 }

    /// Top margin above the staff for ledger lines and symbols.
    private let topMargin: CGFloat = 40.0

    /// Bottom margin below the staff.
    private let bottomMargin: CGFloat = 40.0

    /// Notehead width (horizontal diameter).
    private let noteheadWidth: CGFloat = 10.0

    /// Notehead height (vertical diameter, slightly compressed).
    private let noteheadHeight: CGFloat = 8.0

    /// Stem length in points.
    private let stemLength: CGFloat = 30.0

    /// Stem line width.
    private let stemWidth: CGFloat = 1.5

    // MARK: - Body

    var body: some View {
        let layout = computeLayout()
        let totalHeight = topMargin + staffHeight + bottomMargin

        ScrollView(.horizontal, showsIndicators: false) {
            Canvas { context, size in
                let staffTop = topMargin

                // Draw staff lines
                drawStaffLines(context: &context, staffTop: staffTop, width: size.width)

                // Draw treble clef symbol
                drawTrebleClef(context: &context, staffTop: staffTop)

                // Draw key signature
                drawKeySignature(context: &context, staffTop: staffTop)

                // Draw time signature
                drawTimeSignature(context: &context, staffTop: staffTop)

                // Draw barlines
                drawBarlines(context: &context, staffTop: staffTop, positions: layout.barlinePositions)

                // Draw notes
                for (index, noteInfo) in layout.notes.enumerated() {
                    let isHighlighted = index == currentNoteIndex
                    if noteInfo.isRest {
                        drawRest(context: &context, noteInfo: noteInfo, staffTop: staffTop)
                    } else {
                        drawNote(
                            context: &context, noteInfo: noteInfo,
                            staffTop: staffTop, isHighlighted: isHighlighted
                        )
                    }
                }

                // Draw beams
                for group in layout.beamGroups {
                    drawBeamGroup(context: &context, group: group, notes: layout.notes, staffTop: staffTop)
                }
            }
            .frame(width: layout.totalWidth * zoomScale, height: totalHeight * zoomScale)
            .scaleEffect(zoomScale, anchor: .topLeading)
            .frame(width: layout.totalWidth * zoomScale, height: totalHeight * zoomScale)
            .accessibilityLabel("Staff notation")
            .accessibilityHint("Sheet music display showing notes on a 5-line staff")
        }
    }

    // MARK: - Layout

    /// Compute the full note layout from the input notes.
    private func computeLayout() -> NoteLayoutResult {
        NoteLayoutEngine.layout(
            midiNumbers: notes.map(\.midiNumber),
            noteNames: notes.map(\.note),
            durations: notes.map(\.duration),
            keySignature: keySignature,
            timeSignature: timeSignature
        )
    }

    // MARK: - Staff Drawing

    /// Draw the five horizontal staff lines.
    private func drawStaffLines(context: inout GraphicsContext, staffTop: CGFloat, width: CGFloat) {
        let lineColor = staffColor
        for line in 0..<5 {
            let y = staffTop + CGFloat(line) * staffSpacing
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
            context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
        }
    }

    /// Draw the treble clef symbol at the left of the staff.
    private func drawTrebleClef(context: inout GraphicsContext, staffTop: CGFloat) {
        let text = Text("\u{1D11E}").font(.system(size: 42))
        let point = CGPoint(x: 6, y: staffTop - 12)
        context.draw(context.resolve(text), at: point, anchor: .topLeading)
    }

    /// Draw key signature accidentals after the treble clef.
    private func drawKeySignature(context: inout GraphicsContext, staffTop: CGFloat) {
        let sharpPositions = keySignature.sharpStaffPositions
        let flatPositions = keySignature.flatStaffPositions

        var xOffset: CGFloat = 36

        for position in sharpPositions {
            let y = yForStaffPosition(position, staffTop: staffTop)
            let text = Text("\u{266F}").font(.system(size: 14)).foregroundColor(staffSwiftUIColor)
            context.draw(context.resolve(text), at: CGPoint(x: xOffset, y: y), anchor: .center)
            xOffset += 8
        }

        for position in flatPositions {
            let y = yForStaffPosition(position, staffTop: staffTop)
            let text = Text("\u{266D}").font(.system(size: 14)).foregroundColor(staffSwiftUIColor)
            context.draw(context.resolve(text), at: CGPoint(x: xOffset, y: y), anchor: .center)
            xOffset += 8
        }
    }

    /// Draw the time signature numerals.
    private func drawTimeSignature(context: inout GraphicsContext, staffTop: CGFloat) {
        let xPos: CGFloat = 55
        let topY = staffTop + staffSpacing  // Second line from top
        let bottomY = staffTop + staffSpacing * 3  // Fourth line from top

        let topText = Text("\(timeSignature.numerator)")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(staffSwiftUIColor)
        let bottomText = Text("\(timeSignature.denominator)")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(staffSwiftUIColor)

        context.draw(context.resolve(topText), at: CGPoint(x: xPos, y: topY), anchor: .center)
        context.draw(context.resolve(bottomText), at: CGPoint(x: xPos, y: bottomY), anchor: .center)
    }

    // MARK: - Note Drawing

    /// Draw a single note with all its components.
    private func drawNote(
        context: inout GraphicsContext,
        noteInfo: StaffNoteInfo,
        staffTop: CGFloat,
        isHighlighted: Bool
    ) {
        let centerX = noteInfo.xPosition
        let centerY = yForStaffPosition(noteInfo.staffYOffset, staffTop: staffTop)

        // Highlight rectangle
        if isHighlighted {
            let highlightRect = CGRect(
                x: centerX - noteheadWidth,
                y: centerY - noteheadHeight * 2,
                width: noteheadWidth * 2,
                height: noteheadHeight * 4
            )
            let highlightColor: Color = .accentColor.opacity(0.2)
            context.fill(Path(roundedRect: highlightRect, cornerRadius: 4), with: .color(highlightColor))
        }

        // Ledger lines
        drawLedgerLines(context: &context, noteInfo: noteInfo, staffTop: staffTop, centerX: centerX)

        // Accidental
        if let accidental = noteInfo.accidental {
            let accidentalText = Text(accidental.rawValue)
                .font(.system(size: 14))
                .foregroundColor(isHighlighted ? .accentColor : staffSwiftUIColor)
            let accidentalX = centerX - noteheadWidth - 4
            context.draw(
                context.resolve(accidentalText),
                at: CGPoint(x: accidentalX, y: centerY),
                anchor: .trailing
            )
        }

        // Notehead
        let noteheadRect = CGRect(
            x: centerX - noteheadWidth / 2,
            y: centerY - noteheadHeight / 2,
            width: noteheadWidth,
            height: noteheadHeight
        )

        let noteColor = isHighlighted ? Color.accentColor : staffSwiftUIColor
        let ellipse = Path(ellipseIn: noteheadRect)

        if noteInfo.noteheadType.isFilled {
            context.fill(ellipse, with: .color(noteColor))
        } else {
            context.stroke(ellipse, with: .color(noteColor), lineWidth: 1.5)
        }

        // Stem and flags
        drawStemAndFlags(
            context: &context, noteInfo: noteInfo,
            centerX: centerX, centerY: centerY, color: noteColor
        )

        // Augmentation dot
        if noteInfo.isDotted {
            let dotX = centerX + noteheadWidth / 2 + 4
            let dotY = centerY - (noteInfo.staffYOffset % 2 == 0 ? staffSpacing / 4 : 0)
            let dotRect = CGRect(x: dotX - 1.5, y: dotY - 1.5, width: 3, height: 3)
            context.fill(Path(ellipseIn: dotRect), with: .color(noteColor))
        }
    }

    /// Draw stem and optional flags for a note.
    private func drawStemAndFlags(
        context: inout GraphicsContext,
        noteInfo: StaffNoteInfo,
        centerX: CGFloat,
        centerY: CGFloat,
        color: Color
    ) {
        guard noteInfo.noteheadType.hasStem else { return }

        drawStem(
            context: &context, centerX: centerX,
            centerY: centerY, direction: noteInfo.stemDirection,
            color: color
        )

        // Flags for unbeamed notes only
        if noteInfo.noteheadType.beamCount == 0,
           noteInfo.noteheadType.flagCount > 0 {
            drawFlags(
                context: &context, centerX: centerX,
                centerY: centerY, direction: noteInfo.stemDirection,
                flagCount: noteInfo.noteheadType.flagCount,
                color: color
            )
        }
    }

    /// Draw a rest symbol at the note's x-position.
    private func drawRest(context: inout GraphicsContext, noteInfo: StaffNoteInfo, staffTop: CGFloat) {
        let centerX = noteInfo.xPosition
        let centerY = staffTop + staffHeight / 2  // Center of staff

        let restSymbol: String
        switch noteInfo.noteheadType {
        case .whole:
            restSymbol = "\u{1D13B}"
        case .half:
            restSymbol = "\u{1D13C}"
        case .quarter:
            restSymbol = "\u{1D13D}"
        case .eighth:
            restSymbol = "\u{1D13E}"
        case .sixteenth:
            restSymbol = "\u{1D13F}"
        }

        let text = Text(restSymbol).font(.system(size: 24)).foregroundColor(staffSwiftUIColor)
        context.draw(context.resolve(text), at: CGPoint(x: centerX, y: centerY), anchor: .center)
    }

    // MARK: - Component Drawing

    /// Draw a note stem.
    private func drawStem(
        context: inout GraphicsContext,
        centerX: CGFloat,
        centerY: CGFloat,
        direction: StemDirection,
        color: Color
    ) {
        let stemX: CGFloat
        let stemStartY: CGFloat
        let stemEndY: CGFloat

        switch direction {
        case .up:
            stemX = centerX + noteheadWidth / 2 - stemWidth / 2
            stemStartY = centerY
            stemEndY = centerY - stemLength
        case .down:
            stemX = centerX - noteheadWidth / 2 + stemWidth / 2
            stemStartY = centerY
            stemEndY = centerY + stemLength
        }

        var path = Path()
        path.move(to: CGPoint(x: stemX, y: stemStartY))
        path.addLine(to: CGPoint(x: stemX, y: stemEndY))
        context.stroke(path, with: .color(color), lineWidth: stemWidth)
    }

    /// Draw flags on an unbeamed note.
    private func drawFlags(
        context: inout GraphicsContext,
        centerX: CGFloat,
        centerY: CGFloat,
        direction: StemDirection,
        flagCount: Int,
        color: Color
    ) {
        let stemX: CGFloat
        let stemEndY: CGFloat

        switch direction {
        case .up:
            stemX = centerX + noteheadWidth / 2 - stemWidth / 2
            stemEndY = centerY - stemLength
        case .down:
            stemX = centerX - noteheadWidth / 2 + stemWidth / 2
            stemEndY = centerY + stemLength
        }

        for flag in 0..<flagCount {
            let flagOffset = CGFloat(flag) * 6.0
            let flagY = direction == .up ? stemEndY + flagOffset : stemEndY - flagOffset
            let flagEndX = stemX + (direction == .up ? 8 : -8)
            let flagEndY = flagY + (direction == .up ? 10 : -10)

            var flagPath = Path()
            flagPath.move(to: CGPoint(x: stemX, y: flagY))
            flagPath.addQuadCurve(
                to: CGPoint(x: flagEndX, y: flagEndY),
                control: CGPoint(x: stemX + (direction == .up ? 12 : -12), y: flagY + (direction == .up ? 4 : -4))
            )
            context.stroke(flagPath, with: .color(color), lineWidth: 1.5)
        }
    }

    /// Draw ledger lines for notes above or below the staff.
    private func drawLedgerLines(
        context: inout GraphicsContext,
        noteInfo: StaffNoteInfo,
        staffTop: CGFloat,
        centerX: CGFloat
    ) {
        let ledgerCount = noteInfo.ledgerLines.count
        guard ledgerCount > 0 else { return }

        let halfWidth = noteheadWidth * 0.8
        let lineColor = staffColor

        if noteInfo.ledgerLines.isAbove {
            // Lines above staff: positions 10, 12, 14, ...
            for i in 0..<noteInfo.ledgerLines.count {
                let position = 10 + (i * 2)
                let y = yForStaffPosition(position, staffTop: staffTop)
                var path = Path()
                path.move(to: CGPoint(x: centerX - halfWidth, y: y))
                path.addLine(to: CGPoint(x: centerX + halfWidth, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.8)
            }
        } else {
            // Lines below staff: positions -2, -4, -6, ...
            for i in 0..<noteInfo.ledgerLines.count {
                let position = -2 - (i * 2)
                let y = yForStaffPosition(position, staffTop: staffTop)
                var path = Path()
                path.move(to: CGPoint(x: centerX - halfWidth, y: y))
                path.addLine(to: CGPoint(x: centerX + halfWidth, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.8)
            }
        }
    }

    /// Draw barlines at the specified x-positions.
    private func drawBarlines(context: inout GraphicsContext, staffTop: CGFloat, positions: [Double]) {
        let lineColor = staffColor
        let staffBottom = staffTop + staffHeight

        for xPos in positions {
            var path = Path()
            path.move(to: CGPoint(x: xPos, y: staffTop))
            path.addLine(to: CGPoint(x: xPos, y: staffBottom))
            context.stroke(path, with: .color(lineColor), lineWidth: 1.0)
        }
    }

    /// Draw a beam group connecting note stems.
    private func drawBeamGroup(
        context: inout GraphicsContext,
        group: BeamGroup,
        notes: [StaffNoteInfo],
        staffTop: CGFloat
    ) {
        guard group.noteIndices.count >= 2 else { return }

        let firstIndex = group.noteIndices.first!
        let lastIndex = group.noteIndices.last!
        let firstNote = notes[firstIndex]
        let lastNote = notes[lastIndex]

        let direction = firstNote.stemDirection
        let beamColor = staffSwiftUIColor

        for beamLevel in 0..<group.beamCount {
            let beamOffset = CGFloat(beamLevel) * 4.0

            let firstX: CGFloat
            let firstY: CGFloat
            let lastX: CGFloat
            let lastY: CGFloat

            let firstCenterY = yForStaffPosition(firstNote.staffYOffset, staffTop: staffTop)
            let lastCenterY = yForStaffPosition(lastNote.staffYOffset, staffTop: staffTop)

            switch direction {
            case .up:
                firstX = firstNote.xPosition + noteheadWidth / 2 - stemWidth / 2
                firstY = firstCenterY - stemLength + beamOffset
                lastX = lastNote.xPosition + noteheadWidth / 2 - stemWidth / 2
                lastY = lastCenterY - stemLength + beamOffset
            case .down:
                firstX = firstNote.xPosition - noteheadWidth / 2 + stemWidth / 2
                firstY = firstCenterY + stemLength - beamOffset
                lastX = lastNote.xPosition - noteheadWidth / 2 + stemWidth / 2
                lastY = lastCenterY + stemLength - beamOffset
            }

            var beamPath = Path()
            beamPath.move(to: CGPoint(x: firstX, y: firstY))
            beamPath.addLine(to: CGPoint(x: lastX, y: lastY))
            context.stroke(beamPath, with: .color(beamColor), lineWidth: 3.0)
        }
    }

    // MARK: - Helpers

    /// Convert a staff position to a Y coordinate.
    ///
    /// Position 0 = bottom line (E4). Position 8 = top line (F5).
    /// Higher positions have lower Y values (screen coordinates).
    private func yForStaffPosition(_ position: Int, staffTop: CGFloat) -> CGFloat {
        let topLinePosition = 8
        let halfSpace = staffSpacing / 2
        return staffTop + CGFloat(topLinePosition - position) * halfSpace
    }

    /// Foreground color adapted for current color scheme (for Canvas `.color()`).
    private var staffColor: Color {
        colorScheme == .dark ? .white.opacity(0.85) : .black.opacity(0.85)
    }

    /// SwiftUI Color for text elements within the canvas.
    private var staffSwiftUIColor: Color {
        colorScheme == .dark ? .white.opacity(0.85) : .black.opacity(0.85)
    }
}

// MARK: - Preview

#Preview("Staff Notation - C Major") {
    StaffNotationRenderer(
        notes: [
            WesternNote(note: "C4", duration: 1.0, midiNumber: 60),
            WesternNote(note: "D4", duration: 1.0, midiNumber: 62),
            WesternNote(note: "E4", duration: 1.0, midiNumber: 64),
            WesternNote(note: "F4", duration: 1.0, midiNumber: 65),
            WesternNote(note: "G4", duration: 1.0, midiNumber: 67),
            WesternNote(note: "A4", duration: 1.0, midiNumber: 69),
            WesternNote(note: "B4", duration: 1.0, midiNumber: 71),
            WesternNote(note: "C5", duration: 1.0, midiNumber: 72),
        ],
        currentNoteIndex: 2,
        keySignature: .cMajor,
        timeSignature: .fourFour,
        zoomScale: 1.0
    )
    .frame(height: 120)
    .padding()
}

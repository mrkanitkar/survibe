import SVAudio
import SVCore
import SwiftUI

// MARK: - Data Model

/// A single key on the 61-key piano, identified by its absolute MIDI note number.
struct PianoKey: Identifiable {
    /// MIDI note number (36–96) — unique across all octaves.
    let id: Int
    let swar: Swar
    let westernName: String
    let devanagari: String
    let isNatural: Bool
    let octave: Int
}

/// All 61 piano keys from C2 (MIDI 36) to C7 (MIDI 96).
let allPianoKeys: [PianoKey] = {
    let westernNames = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
    let devanagariNames = ["सा", "रे♭", "रे", "ग♭", "ग", "म", "म♯", "प", "ध♭", "ध", "नि♭", "नि"]
    let naturalOffsets: Set<Int> = [0, 2, 4, 5, 7, 9, 11]

    var keys: [PianoKey] = []
    // C2 (MIDI 36) through C7 (MIDI 96)
    for midiNote in 36...96 {
        let noteIndex = (midiNote - 60 + 120) % 12  // safe modulo for negative values
        let octave = (midiNote - 60) / 12 + 4
        // Correct octave for negative division: MIDI 36-47 = octave 2, 48-59 = 3, etc.
        let correctedOctave = Int(floor(Double(midiNote - 60) / 12.0)) + 4
        let swar = Swar.allCases[noteIndex]
        keys.append(PianoKey(
            id: midiNote,
            swar: swar,
            westernName: westernNames[noteIndex],
            devanagari: devanagariNames[noteIndex],
            isNatural: naturalOffsets.contains(noteIndex),
            octave: correctedOctave
        ))
    }
    return keys
}()

/// White keys only (36 total across 5 octaves + top C).
let whiteKeys: [PianoKey] = allPianoKeys.filter(\.isNatural)

/// Black keys only (25 total across 5 octaves).
let blackKeys: [PianoKey] = allPianoKeys.filter { !$0.isNatural }

// MARK: - Constants

private enum KeyboardLayout {
    static let whiteKeyWidth: CGFloat = 44
    static let whiteKeyHeight: CGFloat = 160
    static let blackKeyWidthRatio: CGFloat = 0.6
    static let blackKeyHeightRatio: CGFloat = 0.6

    static var blackKeyWidth: CGFloat { whiteKeyWidth * blackKeyWidthRatio }
    static var blackKeyHeight: CGFloat { whiteKeyHeight * blackKeyHeightRatio }
    static var totalWidth: CGFloat { CGFloat(whiteKeys.count) * whiteKeyWidth }
}

// MARK: - Piano Keyboard View

/// Full 61-key scrollable piano keyboard (C2–C7) with multi-note highlighting.
/// Supports both single-note (melody) and multi-note (chord) highlighting.
/// Auto-scrolls to the lowest detected note when the octave changes.
struct PianoKeyboardView: View {
    /// Set of MIDI note numbers currently detected (36–96), empty if none.
    let activeMidiNotes: Set<Int>

    /// Cents offset for tuning-accuracy color (uses root/primary note's offset).
    let activeCentsOffset: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Track the last scrolled-to octave to avoid jitter within the same octave.
    @State private var lastScrolledOctave: Int?

    /// The lowest active MIDI note, used for scrolling.
    private var scrollTarget: Int? {
        activeMidiNotes.min()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // White keys layer
                    HStack(spacing: 0) {
                        ForEach(whiteKeys) { key in
                            whiteKeyView(key)
                                .id(key.id)
                        }
                    }

                    // Black keys layer
                    ForEach(blackKeys) { key in
                        blackKeyView(key)
                            .offset(x: blackKeyXOffset(for: key))
                            .id(key.id)
                    }
                }
                .frame(
                    width: KeyboardLayout.totalWidth,
                    height: KeyboardLayout.whiteKeyHeight
                )
            }
            .frame(height: KeyboardLayout.whiteKeyHeight)
            .onChange(of: scrollTarget) { _, newValue in
                guard let midiNote = newValue else { return }
                let octave = Int(floor(Double(midiNote - 60) / 12.0)) + 4
                // Only scroll when the octave changes to avoid jitter
                if octave != lastScrolledOctave {
                    lastScrolledOctave = octave
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(midiNote, anchor: .center)
                    }
                }
            }
            .onAppear {
                // Scroll to the lowest active note if detected, otherwise center on C4
                let target = scrollTarget ?? 60
                proxy.scrollTo(target, anchor: .center)
                if let midiNote = scrollTarget {
                    lastScrolledOctave = Int(floor(Double(midiNote - 60) / 12.0)) + 4
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Piano keyboard, 61 keys")
    }

    // MARK: - White Key

    private func whiteKeyView(_ key: PianoKey) -> some View {
        let isActive = activeMidiNotes.contains(key.id)
        let fillColor = isActive ? centsColor(activeCentsOffset) : Color.white

        return VStack(spacing: 0) {
            Spacer()

            // Show octave number on C keys, just letter on others
            if key.swar == .sa {
                Text(verbatim: "\(key.westernName)\(key.octave)")
                    .font(.system(size: 11, weight: isActive ? .bold : .semibold))
                    .foregroundStyle(isActive ? .white : .primary)
            } else {
                Text(verbatim: key.westernName)
                    .font(.system(size: 11, weight: isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? .white : .primary)
            }

            Text(verbatim: key.devanagari)
                .font(.system(size: 9))
                .foregroundStyle(isActive ? .white.opacity(0.9) : .secondary)

            Spacer().frame(height: 6)
        }
        .frame(width: KeyboardLayout.whiteKeyWidth, height: KeyboardLayout.whiteKeyHeight)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(fillColor)
                .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.gray.opacity(0.25), lineWidth: 0.5)
        )
        .scaleEffect(isActive && !reduceMotion ? 1.04 : 1.0)
        .animation(
            reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7),
            value: isActive
        )
        .accessibilityLabel(
            "\(key.westernName)\(key.octave), \(AccessibilityHelper.swarLabel(for: key.swar.rawValue))"
        )
    }

    // MARK: - Black Key

    private func blackKeyView(_ key: PianoKey) -> some View {
        let isActive = activeMidiNotes.contains(key.id)
        let fillColor = isActive ? centsColor(activeCentsOffset) : Color(white: 0.12)

        return Rectangle()
            .fill(fillColor)
            .frame(
                width: KeyboardLayout.blackKeyWidth,
                height: KeyboardLayout.blackKeyHeight
            )
            .clipShape(
                UnevenRoundedRectangle(
                    bottomLeadingRadius: 3,
                    bottomTrailingRadius: 3
                )
            )
            .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
            .scaleEffect(isActive && !reduceMotion ? 1.06 : 1.0)
            .animation(
                reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7),
                value: isActive
            )
            .zIndex(1)
            .accessibilityLabel(
                "\(key.westernName)\(key.octave), \(AccessibilityHelper.swarLabel(for: key.swar.rawValue))"
            )
    }

    // MARK: - Layout Helpers

    /// Calculate the x-offset for a black key relative to the keyboard's leading edge.
    /// Uses the white key index positions to place black keys between their neighbors.
    private func blackKeyXOffset(for key: PianoKey) -> CGFloat {
        // Find which white key this black key sits after
        // The white key to the LEFT of each black key:
        let whiteKeysBefore = whiteKeys.filter { $0.id < key.id }
        let whiteIndex = CGFloat(whiteKeysBefore.count)
        // Black key sits at the boundary between two white keys
        return whiteIndex * KeyboardLayout.whiteKeyWidth - KeyboardLayout.blackKeyWidth / 2
    }

    /// Color based on tuning accuracy.
    private func centsColor(_ cents: Double) -> Color {
        let absCents = abs(cents)
        if absCents < 5 { return .green }
        if absCents < 15 { return .yellow }
        return .orange
    }
}

// MARK: - Previews

#Preview("61-Key Keyboard — Idle") {
    PianoKeyboardView(activeMidiNotes: [], activeCentsOffset: 0)
        .padding(.vertical)
}

#Preview("C4 Active (In Tune)") {
    PianoKeyboardView(activeMidiNotes: [60], activeCentsOffset: 2)
        .padding(.vertical)
}

#Preview("C Major Chord") {
    PianoKeyboardView(activeMidiNotes: [60, 64, 67], activeCentsOffset: 3)
        .padding(.vertical)
}

#Preview("Am Chord") {
    PianoKeyboardView(activeMidiNotes: [57, 60, 64], activeCentsOffset: -5)
        .padding(.vertical)
}

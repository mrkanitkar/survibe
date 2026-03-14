import SVAudio
import SVLearning
import SwiftUI

/// Auto-scrolling notation sheet for play-along mode.
///
/// Renders the correct notation renderer for the given `notationMode` and
/// passes `currentNoteIndex` through so each renderer can auto-scroll to
/// the active note. Each renderer (`SargamRenderer`, `WesternRenderer`,
/// `StaffNotationRenderer`) owns its own `ScrollViewReader`, so there is
/// no need for an outer scroll wrapper here.
///
/// Detected pitch is forwarded into `SargamRenderer` so key presses are
/// highlighted on the notation blocks in real time.
///
/// ## Why not NotationContainerView?
/// `NotationContainerView` reads `@AppStorage("notationDisplayMode")` on
/// its own, ignoring the `notationMode` argument passed from the toolbar.
/// It also adds a mode-picker and zoom-indicator that are inappropriate
/// for the compact play-along sheet. Rendering the renderers directly here
/// is simpler and correctly honours the toolbar's notation-mode selection.
///
/// ## Usage
/// ```swift
/// ScrollingSheetView(
///     song: song,
///     currentNoteIndex: viewModel.currentNoteIndex,
///     notationMode: viewModel.notationMode,
///     currentPitch: viewModel.currentPitch
/// )
/// ```
struct ScrollingSheetView: View {
    // MARK: - Properties

    /// The song whose notation should be displayed.
    let song: Song

    /// Index of the currently playing note, or nil when idle.
    let currentNoteIndex: Int?

    /// Which notation system to display (sargam, western, dual, etc.).
    let notationMode: NotationDisplayMode

    /// Live detected pitch from the microphone, or nil if silent.
    ///
    /// Forwarded into `SargamRenderer` for accuracy-colour highlighting
    /// (with cents badge) when the user sings or plays via mic.
    var currentPitch: PitchResult?

    /// Swar name + octave derived from a pressed MIDI/touch key, or nil if none.
    ///
    /// On-screen piano taps and hardware MIDI keyboard presses populate
    /// `detectedMidiNotes` — they never produce a `currentPitch`. This tuple
    /// is forwarded into `SargamRenderer` so the matching sargam block is
    /// highlighted even when mic input is inactive.
    ///
    /// When both `currentPitch` and `detectedSwarInfo` are non-nil (unlikely
    /// but possible during simultaneous mic + MIDI use), `currentPitch` wins
    /// because it carries an accuracy-cent value.
    var detectedSwarInfo: (name: String, octave: Int)?

    // MARK: - Private Helpers

    /// The effective note name to highlight in the notation, from any input source.
    private var activeDetectedName: String? {
        currentPitch?.noteName ?? detectedSwarInfo?.name
    }

    /// The effective octave to highlight in the notation, from any input source.
    private var activeDetectedOctave: Int? {
        currentPitch?.octave ?? detectedSwarInfo?.octave
    }

    /// Cents offset for the accuracy badge — only meaningful for mic input.
    private var activeDetectedCents: Double {
        currentPitch?.centsOffset ?? 0
    }

    // MARK: - Body

    var body: some View {
        let sargamNotes = song.decodedSargamNotes ?? []
        let westernNotes = song.decodedWesternNotes ?? []

        Group {
            switch notationMode {
            case .sargam:
                SargamRenderer(
                    notes: sargamNotes,
                    currentNoteIndex: currentNoteIndex,
                    zoomScale: 1.0,
                    labelOpacity: 1.0,
                    detectedNoteName: activeDetectedName,
                    detectedOctave: activeDetectedOctave,
                    detectedCents: activeDetectedCents
                )

            case .western:
                WesternRenderer(
                    notes: westernNotes,
                    currentNoteIndex: currentNoteIndex,
                    zoomScale: 1.0
                )

            case .dual:
                VStack(spacing: 16) {
                    SargamRenderer(
                        notes: sargamNotes,
                        currentNoteIndex: currentNoteIndex,
                        zoomScale: 1.0,
                        labelOpacity: 1.0,
                        detectedNoteName: activeDetectedName,
                        detectedOctave: activeDetectedOctave,
                        detectedCents: activeDetectedCents
                    )
                    Divider().padding(.horizontal, 16)
                    WesternRenderer(
                        notes: westernNotes,
                        currentNoteIndex: currentNoteIndex,
                        zoomScale: 1.0
                    )
                }

            case .sheetMusic:
                StaffNotationRenderer(
                    notes: westernNotes,
                    currentNoteIndex: currentNoteIndex,
                    keySignature: song.keySignatureEnum,
                    timeSignature: song.timeSignatureEnum,
                    zoomScale: 1.0
                )

            case .sargamPlusSheet:
                VStack(spacing: 16) {
                    SargamRenderer(
                        notes: sargamNotes,
                        currentNoteIndex: currentNoteIndex,
                        zoomScale: 1.0,
                        labelOpacity: 1.0,
                        detectedNoteName: activeDetectedName,
                        detectedOctave: activeDetectedOctave,
                        detectedCents: activeDetectedCents
                    )
                    Divider().padding(.horizontal, 16)
                    StaffNotationRenderer(
                        notes: westernNotes,
                        currentNoteIndex: currentNoteIndex,
                        keySignature: song.keySignatureEnum,
                        timeSignature: song.timeSignatureEnum,
                        zoomScale: 1.0
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Scrolling notation sheet")
        .accessibilityHint("Notation auto-scrolls to follow the current note during playback")
    }
}

// MARK: - Preview

#Preview("Scrolling Sheet — Sargam") {
    ScrollingSheetView(
        song: Song(title: "Preview Song", tempo: 120),
        currentNoteIndex: nil,
        notationMode: .sargam
    )
}

#Preview("Scrolling Sheet — Western") {
    ScrollingSheetView(
        song: Song(title: "Preview Song", tempo: 120),
        currentNoteIndex: 3,
        notationMode: .western
    )
}

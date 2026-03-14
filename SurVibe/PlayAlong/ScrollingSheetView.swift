import SwiftUI

/// Auto-scrolling notation sheet for play-along mode.
///
/// Wraps the existing ``NotationContainerView`` inside a ``ScrollViewReader``
/// so that the currently playing note is always visible. When `currentNoteIndex`
/// changes, the view smoothly scrolls to bring the active note into the center
/// of the viewport. Scroll animation respects the user's Reduce Motion setting.
///
/// ## Usage
/// ```swift
/// ScrollingSheetView(
///     song: song,
///     currentNoteIndex: engine.currentNoteIndex,
///     notationMode: .sargam
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

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                NotationContainerView(
                    song: song,
                    currentNoteIndex: currentNoteIndex,
                    labelOpacity: 1.0
                )
                .id("notation-container")
            }
            .onChange(of: currentNoteIndex) { _, newIndex in
                scrollToNote(newIndex, proxy: proxy)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Scrolling notation sheet")
        .accessibilityHint("Notation auto-scrolls to follow the current note during playback")
    }

    // MARK: - Private Methods

    /// Scroll the notation view to center the note at the given index.
    ///
    /// When Reduce Motion is enabled, the scroll happens instantly
    /// without animation to respect the user's accessibility preference.
    ///
    /// - Parameters:
    ///   - index: The note index to scroll to, or nil to do nothing.
    ///   - proxy: The ScrollViewReader proxy for programmatic scrolling.
    private func scrollToNote(_ index: Int?, proxy: ScrollViewProxy) {
        guard let index else { return }
        let anchor = UnitPoint.center
        if reduceMotion {
            proxy.scrollTo(index, anchor: anchor)
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(index, anchor: anchor)
            }
        }
    }
}

// MARK: - Preview

#Preview("Scrolling Sheet — Idle") {
    ScrollingSheetView(
        song: Song(title: "Preview Song", tempo: 120),
        currentNoteIndex: nil,
        notationMode: .sargam
    )
}

#Preview("Scrolling Sheet — Playing") {
    ScrollingSheetView(
        song: Song(title: "Preview Song", tempo: 120),
        currentNoteIndex: 3,
        notationMode: .western
    )
}

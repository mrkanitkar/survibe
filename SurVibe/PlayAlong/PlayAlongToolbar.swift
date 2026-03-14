import SwiftUI

/// Top toolbar providing play-along transport controls, tempo adjustment,
/// and display mode toggles.
///
/// All controls are driven by external state passed as `let` properties
/// with change callbacks. The toolbar adapts its layout horizontally and
/// provides full VoiceOver accessibility for every interactive element.
///
/// ## Layout
/// Two rows of controls:
/// 1. Transport row: Play/Pause, Stop, Tempo slider
/// 2. Options row: Wait Mode, Sound toggle, View Mode, Notation Mode
struct PlayAlongToolbar: View {
    // MARK: - Properties

    /// Current playback state driving button icons and enabled states.
    let playbackState: PlaybackState

    /// Tempo multiplier (0.25x to 1.5x) applied to the song's base tempo.
    let tempoScale: Double

    /// Whether wait mode is active (pauses until player hits the correct note).
    let isWaitModeEnabled: Bool

    /// Whether reference audio playback is enabled.
    let isSoundEnabled: Bool

    /// Current visual mode (falling notes or scrolling sheet).
    let viewMode: PlayAlongViewMode

    /// Current notation display mode (sargam, western, dual, etc.).
    let notationMode: NotationDisplayMode

    // MARK: - Callbacks

    /// Called when the user taps Play or Pause.
    var onPlayPause: () -> Void

    /// Called when the user taps Stop.
    var onStop: () -> Void

    /// Called when the user adjusts the tempo slider.
    var onTempoChange: (Double) -> Void

    /// Called when the user toggles wait mode.
    var onWaitModeToggle: () -> Void

    /// Called when the user toggles reference sound.
    var onSoundToggle: () -> Void

    /// Called when the user changes the view mode.
    var onViewModeChange: (PlayAlongViewMode) -> Void

    /// Called when the user changes the notation mode.
    var onNotationModeChange: (NotationDisplayMode) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            transportRow
            optionsRow
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Transport Row

    /// Play/Pause, Stop, and tempo slider in a horizontal row.
    private var transportRow: some View {
        HStack(spacing: 12) {
            playPauseButton
            stopButton
            tempoSlider
        }
    }

    /// Play/Pause toggle button with state-driven icon.
    private var playPauseButton: some View {
        Button(action: onPlayPause) {
            Image(systemName: playPauseIconName)
                .font(.title2)
                .frame(width: 44, height: 44)
        }
        .disabled(isPlayPauseDisabled)
        .accessibilityLabel(playPauseAccessibilityLabel)
        .accessibilityHint(playPauseAccessibilityHint)
    }

    /// Stop button that resets playback to the beginning.
    private var stopButton: some View {
        Button(action: onStop) {
            Image(systemName: "stop.fill")
                .font(.title2)
                .frame(width: 44, height: 44)
        }
        .disabled(isStopDisabled)
        .accessibilityLabel("Stop")
        .accessibilityHint("Stop playback and return to the beginning")
    }

    /// Tempo scale slider from 0.25x to 1.5x with current value label.
    private var tempoSlider: some View {
        HStack(spacing: 4) {
            Text(PlayAlongToolbar.formatTempoScale(tempoScale))
                .font(.caption)
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
                .accessibilityHidden(true)

            Slider(
                value: Binding(
                    get: { tempoScale },
                    set: { onTempoChange($0) }
                ),
                in: 0.25...1.5,
                step: 0.25
            )
            .accessibilityLabel("Tempo scale")
            .accessibilityValue(PlayAlongToolbar.formatTempoScale(tempoScale))
            .accessibilityHint("Adjust playback speed from 0.25 times to 1.5 times")
        }
    }

    // MARK: - Options Row

    /// Wait mode, sound toggle, view mode picker, and notation mode picker.
    private var optionsRow: some View {
        HStack(spacing: 12) {
            waitModeButton
            soundToggleButton
            Spacer()
            viewModePicker
            notationModePicker
        }
    }

    /// Toggle for wait mode (pauses until the player hits the correct note).
    private var waitModeButton: some View {
        Button(action: onWaitModeToggle) {
            Image(systemName: "hourglass")
                .font(.body)
                .frame(width: 36, height: 36)
                .foregroundStyle(isWaitModeEnabled ? .white : .primary)
                .background(isWaitModeEnabled ? Color.accentColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel("Wait mode")
        .accessibilityValue(isWaitModeEnabled ? "On" : "Off")
        .accessibilityHint("When enabled, playback pauses until you play the correct note")
    }

    /// Toggle for reference sound playback.
    private var soundToggleButton: some View {
        Button(action: onSoundToggle) {
            Image(systemName: isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.body)
                .frame(width: 36, height: 36)
        }
        .accessibilityLabel(isSoundEnabled ? "Sound on" : "Sound off")
        .accessibilityHint("Toggle reference audio playback")
    }

    /// Picker to switch between falling notes and scrolling sheet modes.
    private var viewModePicker: some View {
        Picker("View", selection: Binding(
            get: { viewMode },
            set: { onViewModeChange($0) }
        )) {
            ForEach(PlayAlongViewMode.allCases, id: \.self) { mode in
                Label(mode.label, systemImage: mode.iconName)
                    .tag(mode)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("View mode")
        .accessibilityHint("Switch between falling notes and sheet view")
    }

    /// Picker to switch notation display modes.
    private var notationModePicker: some View {
        Picker("Notation", selection: Binding(
            get: { notationMode },
            set: { onNotationModeChange($0) }
        )) {
            ForEach(NotationDisplayMode.allCases, id: \.self) { mode in
                Label(mode.label, systemImage: mode.iconName)
                    .tag(mode)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Notation mode")
        .accessibilityHint("Choose notation display style")
    }

    // MARK: - Computed Properties

    /// SF Symbol name for the play/pause button based on current playback state.
    static func playPauseIcon(for state: PlaybackState) -> String {
        switch state {
        case .playing:
            "pause.fill"
        default:
            "play.fill"
        }
    }

    /// Returns the SF Symbol name for the current playback state.
    private var playPauseIconName: String {
        Self.playPauseIcon(for: playbackState)
    }

    /// VoiceOver label for the play/pause button.
    private var playPauseAccessibilityLabel: String {
        switch playbackState {
        case .playing:
            "Pause"
        default:
            "Play"
        }
    }

    /// VoiceOver hint for the play/pause button.
    private var playPauseAccessibilityHint: String {
        switch playbackState {
        case .playing:
            "Pause song playback"
        case .paused:
            "Resume song playback"
        default:
            "Start playing the song"
        }
    }

    /// Whether the play/pause button should be disabled.
    private var isPlayPauseDisabled: Bool {
        switch playbackState {
        case .loading, .error:
            true
        default:
            false
        }
    }

    /// Whether the stop button should be disabled.
    private var isStopDisabled: Bool {
        switch playbackState {
        case .idle, .loading, .stopped, .error:
            true
        case .playing, .paused:
            false
        }
    }

    // MARK: - Static Helpers

    /// Format a tempo scale value as a human-readable string.
    ///
    /// Clamps the value to the valid range (0.25...1.5) before formatting.
    /// Values at whole or quarter increments display cleanly (e.g., "1.0x", "0.25x").
    ///
    /// - Parameter scale: The tempo multiplier value.
    /// - Returns: Formatted string like "0.75x" or "1.5x".
    static func formatTempoScale(_ scale: Double) -> String {
        let clamped = min(1.5, max(0.25, scale))
        if clamped == Double(Int(clamped)) {
            return String(format: "%.1fx", clamped)
        }
        return String(format: "%.2gx", clamped)
    }

    /// Clamp a tempo scale value to the valid range.
    ///
    /// - Parameter scale: The raw tempo multiplier.
    /// - Returns: Value clamped to 0.25...1.5.
    static func clampTempoScale(_ scale: Double) -> Double {
        min(1.5, max(0.25, scale))
    }
}

// MARK: - Preview

#Preview("Toolbar — Idle") {
    PlayAlongToolbar(
        playbackState: .idle,
        tempoScale: 1.0,
        isWaitModeEnabled: false,
        isSoundEnabled: true,
        viewMode: .fallingNotes,
        notationMode: .sargam,
        onPlayPause: {},
        onStop: {},
        onTempoChange: { _ in },
        onWaitModeToggle: {},
        onSoundToggle: {},
        onViewModeChange: { _ in },
        onNotationModeChange: { _ in }
    )
}

#Preview("Toolbar — Playing") {
    PlayAlongToolbar(
        playbackState: .playing,
        tempoScale: 0.75,
        isWaitModeEnabled: true,
        isSoundEnabled: false,
        viewMode: .scrollingSheet,
        notationMode: .dual,
        onPlayPause: {},
        onStop: {},
        onTempoChange: { _ in },
        onWaitModeToggle: {},
        onSoundToggle: {},
        onViewModeChange: { _ in },
        onNotationModeChange: { _ in }
    )
}

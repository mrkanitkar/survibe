import AudioKit
import AudioKitUI
import SVAudio
import SVCore
import SwiftUI

/// Container view that switches between four audio visualization modes.
///
/// Each mode provides a different visual representation of the audio signal:
/// - **Tuner**: Shows detected note name, cents offset, and frequency (existing pitch UI)
/// - **Waveform**: Real-time oscilloscope via `NodeOutputView`
/// - **Pitch Track**: Placeholder for future pitch-over-time graph
/// - **Spectrum**: Real-time spectrogram via `SpectrogramView`
///
/// Uses `AudioNodeAdapter.shared` to tap the engine's main mixer node
/// for visualization data. This coexists safely with the mic tap on inputNode.
struct AudioVisualizationView: View {
    // MARK: - Input Properties

    /// The current visualization mode.
    let mode: VisualizationMode

    /// The current pitch detection result (used by tuner mode).
    let currentResult: PitchResult?

    /// Live amplitude from mic input (used by tuner mode).
    let liveAmplitude: Double

    /// Whether the audio engine is actively listening.
    let isListening: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        Group {
            if isListening {
                switch mode {
                case .tuner:
                    tunerView
                case .waveform:
                    waveformView
                case .pitchTrack:
                    pitchTrackPlaceholder
                case .spectrum:
                    spectrumView
                }
            } else {
                visualizationPlaceholder
            }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(mode.displayName) visualization")
    }

    // MARK: - Tuner Mode

    /// Simple tuner showing note name and cents offset indicator.
    private var tunerView: some View {
        Group {
            if let result = currentResult {
                HStack(spacing: Spacing.lg) {
                    // Note name
                    VStack(spacing: 2) {
                        Text(verbatim: result.noteName)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                        Text(verbatim: "Octave \(result.octave)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(AccessibilityHelper.swarLabel(for: result.noteName)), octave \(result.octave)"
                    )

                    // Cents bar
                    VStack(spacing: Spacing.xs) {
                        centsBar(result.centsOffset)
                        Text(verbatim: "\(String(format: "%.1f", result.frequency)) Hz")
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.tertiary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        AccessibilityHelper.pitchAccuracyLabel(centsOffset: result.centsOffset)
                    )
                }
                .padding(.horizontal, Spacing.lg)
            } else {
                listeningIndicator
            }
        }
    }

    /// Cents offset bar visualization.
    private func centsBar(_ cents: Double) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let center = width / 2
            let clampedCents = max(-50, min(50, cents))
            let offset = (clampedCents / 50.0) * (width / 2) * 0.9

            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(height: 8)
                Rectangle()
                    .fill(.secondary)
                    .frame(width: 2, height: 16)
                    .position(x: center, y: 10)
                Circle()
                    .fill(centsColor(cents))
                    .frame(width: 14, height: 14)
                    .position(x: center + offset, y: 10)
            }
        }
        .frame(height: 20)
    }

    // MARK: - Waveform Mode

    /// Real-time oscilloscope powered by AudioKitUI NodeOutputView.
    private var waveformView: some View {
        NodeOutputView(AudioNodeAdapter.shared, color: .rangNeel, bufferSize: 1024)
            .accessibilityLabel("Live audio waveform")
            .accessibilityHint("Shows real-time oscilloscope of the mixed audio signal")
    }

    // MARK: - Spectrum Mode

    /// Real-time spectrogram powered by AudioKitUI SpectrogramView.
    private var spectrumView: some View {
        SpectrogramView(
            node: AudioNodeAdapter.shared,
            linearGradient: LinearGradient(
                gradient: Gradient(colors: [.blue, .green, .yellow, .red]),
                startPoint: .bottom,
                endPoint: .top
            ),
            backgroundColor: Color.black.opacity(0.9)
        )
        .accessibilityLabel("Live audio spectrogram")
        .accessibilityHint(
            "Shows frequency content over time. Steady notes appear as flat bands, ornaments appear as wavy bands."
        )
    }

    // MARK: - Pitch Track Placeholder

    /// Placeholder for future pitch-over-time visualization.
    private var pitchTrackPlaceholder: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Pitch Track")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Coming in a future update")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Placeholders

    /// Shown when listening but no note detected yet.
    private var listeningIndicator: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "waveform")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .symbolEffect(.variableColor.iterative)
                .accessibilityHidden(true)
            Text("Listening...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Shown when the engine is not listening.
    private var visualizationPlaceholder: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: mode.systemImage)
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            Text("Tap mic to start")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    /// Color based on tuning accuracy.
    private func centsColor(_ cents: Double) -> Color {
        let absCents = abs(cents)
        if absCents < 5 { return .green }
        if absCents < 15 { return .yellow }
        return .orange
    }
}

// MARK: - Previews

#Preview("Tuner Mode — Active") {
    AudioVisualizationView(
        mode: .tuner,
        currentResult: PitchResult(
            frequency: 261.63,
            amplitude: 0.5,
            noteName: "Sa",
            octave: 4,
            centsOffset: 3.2,
            confidence: 0.95
        ),
        liveAmplitude: 0.3,
        isListening: true
    )
    .padding()
}

#Preview("Waveform Mode — Idle") {
    AudioVisualizationView(
        mode: .waveform,
        currentResult: nil,
        liveAmplitude: 0,
        isListening: false
    )
    .padding()
}

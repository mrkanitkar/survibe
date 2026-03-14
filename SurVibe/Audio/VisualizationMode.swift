import Foundation

/// Audio visualization display modes for the practice tab.
///
/// Each mode renders the same audio data in a different visual representation.
/// The selected mode persists via @AppStorage across app launches.
enum VisualizationMode: String, CaseIterable, Sendable {
    /// Classic tuner: note name + cents indicator + frequency readout.
    case tuner

    /// Real-time audio waveform (oscilloscope) via NodeOutputView.
    case waveform

    /// 3D spectrogram waterfall for gamaka/meend visualization.
    case pitchTrack

    /// FFT frequency spectrum bars for overtone analysis.
    case spectrum

    /// Localized display name for the mode switcher.
    var displayName: String {
        switch self {
        case .tuner: String(localized: "Tuner")
        case .waveform: String(localized: "Wave")
        case .pitchTrack: String(localized: "Pitch")
        case .spectrum: String(localized: "Spectrum")
        }
    }

    /// SF Symbol for the mode icon.
    var systemImage: String {
        switch self {
        case .tuner: "tuningfork"
        case .waveform: "waveform"
        case .pitchTrack: "chart.xyaxis.line"
        case .spectrum: "chart.bar.fill"
        }
    }
}

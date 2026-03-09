import SwiftUI
import SVCore

/// View for riyaz (practice) mode with pitch feedback.
/// Full implementation in Sprint 1.
public struct PracticeModeView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Practice Mode")
                .font(.title2)
            Text("Real-time pitch feedback coming in Sprint 1")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .scaledPadding()
    }
}

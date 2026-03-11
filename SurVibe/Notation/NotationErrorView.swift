import SwiftUI

/// Error and empty state view shown when notation data is unavailable or invalid.
///
/// Displays a centered icon, title, and subtitle to inform the user why
/// notation cannot be rendered. Used as a fallback within
/// ``NotationContainerView`` when neither Sargam nor Western data is present.
struct NotationErrorView: View {
    // MARK: - Properties

    /// SF Symbol name for the error icon.
    let systemImage: String

    /// Primary message describing the issue.
    let title: String

    /// Secondary message with guidance or context.
    let subtitle: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Convenience Initializers

extension NotationErrorView {
    /// Creates an error view for missing notation data.
    static var noNotation: NotationErrorView {
        NotationErrorView(
            systemImage: "music.note.slash",
            title: "No Notation Available",
            subtitle: "This song does not have notation data yet."
        )
    }

    /// Creates an error view for a decoding failure.
    static var decodingError: NotationErrorView {
        NotationErrorView(
            systemImage: "exclamationmark.triangle",
            title: "Notation Error",
            subtitle: "Could not read the notation data for this song."
        )
    }
}

// MARK: - Preview

#Preview("No Notation") {
    NotationErrorView.noNotation
}

#Preview("Decoding Error") {
    NotationErrorView.decodingError
}

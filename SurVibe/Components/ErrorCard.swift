import SwiftUI

/// A reusable error display card with icon, message, and optional retry button.
///
/// Presents errors in a consistent, accessible format across the app.
/// The card uses a red-tinted background with a warning icon and supports
/// an optional retry action.
///
/// Usage:
/// ```swift
/// ErrorCard(
///     message: "Failed to load songs",
///     retryAction: { await loadSongs() }
/// )
/// ```
struct ErrorCard: View {
    // MARK: - Properties

    /// The error message to display.
    let message: String

    /// Optional retry action. When provided, a "Try Again" button is shown.
    var retryAction: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let retryAction {
                Button {
                    retryAction()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(Text("Try Again"))
                .accessibilityHint(Text("Double tap to retry the failed operation"))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Error: \(message)"))
    }
}

// MARK: - Preview

#Preview("With Retry") {
    ErrorCard(
        message: "Failed to load songs. Please check your connection.",
        retryAction: {}
    )
    .padding()
}

#Preview("Without Retry") {
    ErrorCard(message: "Something went wrong.")
        .padding()
}

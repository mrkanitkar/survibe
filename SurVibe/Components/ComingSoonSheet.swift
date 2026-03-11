import SwiftUI

/// A half-sheet modal displayed when the user taps a disabled Door on the Home tab.
///
/// Shows the door's icon, title, and a brief description explaining that the
/// feature is not yet available. Includes a "Got it" button to dismiss.
/// Uses `.presentationDetents([.medium])` for a compact half-sheet appearance.
///
/// ## Usage
/// ```swift
/// .sheet(item: $selectedDoor) { door in
///     ComingSoonSheet(
///         doorTitle: door.title,
///         doorIcon: door.icon,
///         doorDescription: door.description
///     )
/// }
/// ```
struct ComingSoonSheet: View {
    // MARK: - Properties

    /// Display title of the upcoming feature (e.g., "Moods", "Events").
    let doorTitle: String

    /// SF Symbol name for the feature icon.
    let doorIcon: String

    /// Brief description of what the feature will offer when available.
    let doorDescription: String

    /// Dismiss action provided by the presentation environment.
    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: doorIcon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(doorTitle)
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            Text(doorDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .accessibilityLabel(doorDescription)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
            .accessibilityLabel("Got it")
            .accessibilityHint("Double tap to dismiss this sheet")
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview("Coming Soon — Moods") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ComingSoonSheet(
                doorTitle: "Moods",
                doorIcon: "heart.fill",
                doorDescription:
                    "Play songs that match your mood. "
                    + "Relaxing ragas, energizing compositions, "
                    + "and everything in between."
            )
        }
}

#Preview("Coming Soon — Events") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ComingSoonSheet(
                doorTitle: "Events",
                doorIcon: "calendar",
                doorDescription:
                    "Seasonal collections for Diwali, Holi, "
                    + "and more. Play festive music "
                    + "when it matters most."
            )
        }
}

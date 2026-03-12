import SwiftUI

/// Reusable card displaying an icon, label, and value.
///
/// Used in practice summary grids to show individual statistics
/// like accuracy, streak, XP earned, and notes played.
struct StatCard: View {
    /// SF Symbol name for the card icon.
    let icon: String

    /// Short label describing the statistic.
    let label: String

    /// The statistic value to display.
    let value: String

    /// Optional tint color for the icon.
    var iconColor: Color = .accentColor

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            Text(value)
                .font(.title3.bold().monospacedDigit())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

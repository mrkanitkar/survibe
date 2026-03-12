import SwiftUI

/// A small badge displaying a song's difficulty level with color coding.
///
/// Maps the integer difficulty (1–5) to a human-readable label and
/// a color from the Rang color system (Neel → Sona).
///
/// Usage:
/// ```swift
/// DifficultyBadge(difficulty: song.difficulty)
/// ```
struct DifficultyBadge: View {
    // MARK: - Properties

    /// The difficulty level (1–5).
    let difficulty: Int

    // MARK: - Body

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(.white)
            .background(
                Capsule()
                    .fill(color)
            )
            .accessibilityLabel(Text("Difficulty: \(label)"))
    }

    // MARK: - Private Methods

    /// Human-readable label for the difficulty level.
    private var label: String {
        switch difficulty {
        case 1: "Beginner"
        case 2: "Easy"
        case 3: "Medium"
        case 4: "Hard"
        case 5: "Expert"
        default: "Level \(difficulty)"
        }
    }

    /// Color for the difficulty badge (Rang system).
    private var color: Color {
        switch difficulty {
        case 1: Color(red: 0.247, green: 0.318, blue: 0.710)  // Neel #3F51B5
        case 2: Color(red: 0.220, green: 0.557, blue: 0.235)  // Hara #388E3C
        case 3: Color(red: 0.757, green: 0.475, blue: 0.0)    // Peela Dark #C17900
        case 4: Color(red: 0.827, green: 0.184, blue: 0.184)  // Lal #D32F2F
        case 5: Color(red: 0.722, green: 0.467, blue: 0.0)    // Sona Dark #B87700
        default: Color.gray
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 8) {
        ForEach(1...5, id: \.self) { level in
            DifficultyBadge(difficulty: level)
        }
    }
    .padding()
}

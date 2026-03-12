import SwiftUI

/// Displays a 1–5 star rating with filled and empty stars.
///
/// Used in the practice session summary to show the overall performance grade.
struct StarRatingView: View {
    /// Number of filled stars (1–5).
    let rating: Int

    /// Maximum number of stars to display.
    let maxStars: Int

    init(rating: Int, maxStars: Int = 5) {
        self.rating = max(0, min(rating, maxStars))
        self.maxStars = maxStars
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxStars, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundStyle(index <= rating ? .yellow : .gray.opacity(0.3))
                    .font(.title2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rating) out of \(maxStars) stars")
    }
}

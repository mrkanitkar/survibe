import SwiftUI

/// A card view displaying a single song in the library grid.
///
/// Shows a raag-colored artwork area, premium lock badge (if locked),
/// favorite heart button, title, artist, difficulty badge, language badge,
/// and a mini notation preview.
///
/// Uses `@Environment(SongLibraryViewModel.self)` for favorite toggling
/// and premium lock checks.
struct SongCardView: View {
    // MARK: - Properties

    /// The song to display.
    let song: Song

    @Environment(SongLibraryViewModel.self) private var viewModel

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Artwork area with raag color
            artworkArea

            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: song.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(verbatim: song.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Badges row
                HStack(spacing: 6) {
                    DifficultyBadge(difficulty: song.difficulty)
                    LanguageBadge(languageCode: song.language)
                }

                // Mini notation preview
                MiniNotationPreview(song: song)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(songAccessibilityLabel)
        .accessibilityHint(
            viewModel.isPremiumLocked(song)
                ? Text("Premium song. Double tap to sign in.")
                : Text("Double tap to open this song.")
        )
    }

    // MARK: - Subviews

    /// Colored artwork area with favorite button and lock indicator.
    private var artworkArea: some View {
        ZStack(alignment: .topTrailing) {
            // Raag-based gradient background
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: artworkGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 100)

            // Raag name overlay (centered)
            if !song.ragaName.isEmpty {
                Text(verbatim: song.ragaName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }

            // Top-right controls: lock badge and favorite heart
            VStack(spacing: 6) {
                // Premium lock badge
                if viewModel.isPremiumLocked(song) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(.black.opacity(0.5)))
                        .accessibilityLabel(Text("Premium locked"))
                }

                // Favorite heart button
                Button {
                    viewModel.toggleFavorite(song)
                } label: {
                    Image(systemName: song.isFavorite ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundStyle(song.isFavorite ? .red : .white)
                        .padding(6)
                        .background(Circle().fill(.black.opacity(0.3)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(song.isFavorite ? Text("Remove from favorites") : Text("Add to favorites"))
                .accessibilityHint(Text("Double tap to toggle favorite"))
            }
            .padding(8)
        }
    }

    // MARK: - Private Methods

    /// Gradient colors for the artwork area based on the song's difficulty.
    private var artworkGradientColors: [Color] {
        switch song.difficulty {
        case 1:
            [Color(red: 0.247, green: 0.318, blue: 0.710), Color(red: 0.247, green: 0.318, blue: 0.710).opacity(0.7)]
        case 2:
            [Color(red: 0.220, green: 0.557, blue: 0.235), Color(red: 0.220, green: 0.557, blue: 0.235).opacity(0.7)]
        case 3:
            [Color(red: 0.757, green: 0.475, blue: 0.0), Color(red: 0.757, green: 0.475, blue: 0.0).opacity(0.7)]
        case 4:
            [Color(red: 0.827, green: 0.184, blue: 0.184), Color(red: 0.827, green: 0.184, blue: 0.184).opacity(0.7)]
        case 5:
            [Color(red: 0.722, green: 0.467, blue: 0.0), Color(red: 0.722, green: 0.467, blue: 0.0).opacity(0.7)]
        default:
            [Color.gray, Color.gray.opacity(0.7)]
        }
    }

    /// Combined accessibility label for the song card.
    private var songAccessibilityLabel: Text {
        var parts = [song.title, "by \(song.artist)"]

        if !song.ragaName.isEmpty {
            parts.append("Raag \(song.ragaName)")
        }

        if song.isFavorite {
            parts.append("Favorite")
        }

        if viewModel.isPremiumLocked(song) {
            parts.append("Premium")
        }

        return Text(parts.joined(separator: ", "))
    }
}

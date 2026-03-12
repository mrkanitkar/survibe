import SwiftData
import SwiftUI
import SVLearning

/// Summary view shown after completing a practice session.
///
/// Displays the score circle, star rating, stats grid, XP earned,
/// and action buttons for practicing again or going back.
struct PracticeSessionSummaryView: View {
    let viewModel: PracticeSessionViewModel
    let onPracticeAgain: () -> Void
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext

    /// Currently selected summary tab.
    @State private var selectedTab: SummaryTab = .overview

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score circle
                scoreCircle

                // Star rating
                StarRatingView(rating: viewModel.starRating)

                // XP badge
                xpBadge

                // Tab picker
                Picker("View", selection: $selectedTab) {
                    ForEach(SummaryTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .accessibilityLabel("Summary view selector")

                // Tab content
                switch selectedTab {
                case .overview:
                    overviewContent
                case .sections:
                    SectionBreakdownView(noteScores: viewModel.noteScores)
                case .notes:
                    NoteDetailListView(noteScores: viewModel.noteScores)
                case .history:
                    PracticeHistoryView(entries: practiceEntries)
                }

                // Action buttons
                actionButtons
            }
            .padding()
        }
    }

    // MARK: - Score Circle

    private var scoreCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
            Circle()
                .trim(from: 0, to: reduceMotion ? viewModel.sessionAccuracy : viewModel.sessionAccuracy)
                .stroke(accuracyColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(Int(viewModel.sessionAccuracy * 100))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text("%")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 160, height: 160)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Score: \(Int(viewModel.sessionAccuracy * 100)) percent")
    }

    // MARK: - XP Badge

    private var xpBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)
            Text("+\(viewModel.xpEarned) XP")
                .font(.headline)
                .foregroundStyle(.yellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.yellow.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(viewModel.xpEarned) experience points earned")
    }

    // MARK: - Overview Content

    private var overviewContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "target",
                label: "Accuracy",
                value: "\(Int(viewModel.sessionAccuracy * 100))%",
                iconColor: accuracyColor
            )
            StatCard(
                icon: "flame.fill",
                label: "Best Streak",
                value: "\(viewModel.longestStreak)",
                iconColor: .orange
            )
            StatCard(
                icon: "music.note",
                label: "Notes Played",
                value: "\(viewModel.noteScores.count)",
                iconColor: .blue
            )
            StatCard(
                icon: "clock",
                label: "Duration",
                value: formattedDuration,
                iconColor: .purple
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                onPracticeAgain()
            } label: {
                Label("Practice Again", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Practice again")
            .accessibilityHint("Restart the practice session from the beginning")

            Button {
                onDone()
            } label: {
                Label("Done", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Done")
            .accessibilityHint("Return to the song detail screen")
        }
        .padding(.horizontal)
    }

    // MARK: - Data Fetching

    /// Recent practice entries for the history chart.
    ///
    /// Fetches the 30 most recent entries sorted by date descending,
    /// then reverses the result so entries display in chronological order.
    private var practiceEntries: [RiyazEntry] {
        let descriptor = FetchDescriptor<RiyazEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let entries = (try? modelContext.fetch(descriptor)) ?? []
        return Array(entries.prefix(30)).reversed()
    }

    // MARK: - Helpers

    private var accuracyColor: Color {
        let accuracy = viewModel.sessionAccuracy
        if accuracy >= 0.9 { return .green }
        if accuracy >= 0.7 { return .blue }
        if accuracy >= 0.5 { return .orange }
        return .red
    }

    private var formattedDuration: String {
        let totalSeconds = Int(viewModel.elapsedPracticeTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Tabs for the practice session summary.
enum SummaryTab: String, CaseIterable, Identifiable {
    case overview
    case sections
    case notes
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .sections: "Sections"
        case .notes: "Notes"
        case .history: "History"
        }
    }
}

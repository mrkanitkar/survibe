import Charts
import SwiftUI

/// Practice history view showing an accuracy trend chart and aggregate session statistics.
///
/// Plots a smooth line chart of accuracy over time using the Charts framework,
/// with a trend indicator showing whether the player is improving or declining.
/// Below the chart, a stats grid summarizes total sessions, average accuracy,
/// total practice minutes, and total XP earned.
struct PracticeHistoryView: View {
    /// Practice session entries fetched from SwiftData, ordered by date.
    let entries: [RiyazEntry]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if entries.isEmpty {
                emptyStateView
            } else {
                accuracyChartSection
                statsGridSection
            }
        }
    }

    // MARK: - Empty State

    /// Placeholder displayed when no practice entries exist.
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)

            Text("No practice history yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Complete a practice session to see your progress")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No practice history yet. Complete a practice session to see your progress.")
    }

    // MARK: - Accuracy Chart Section

    /// Header and line chart showing accuracy percentage over time.
    private var accuracyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            chartHeader
            accuracyChart
                .frame(height: 200)
        }
    }

    /// Chart header with title and trend indicator.
    private var chartHeader: some View {
        HStack {
            Text("Accuracy Trend")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            Spacer()

            trendIndicator
        }
    }

    /// Arrow indicator showing whether accuracy is improving or declining.
    ///
    /// Compares the average accuracy of the first half of entries to the
    /// second half. An upward arrow indicates improvement, while a downward
    /// arrow indicates decline. Requires at least two entries to display.
    private var trendIndicator: some View {
        Group {
            if entries.count >= 2 {
                let trend = computeTrend()
                HStack(spacing: 4) {
                    Image(
                        systemName: trend.isImproving
                            ? "arrow.up.right"
                            : "arrow.down.right"
                    )
                    .font(.subheadline.bold())
                    .foregroundStyle(trend.isImproving ? .green : .red)

                    Text(trend.isImproving ? "Improving" : "Declining")
                        .font(.caption)
                        .foregroundStyle(trend.isImproving ? .green : .red)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    trend.isImproving
                        ? "Trend: improving"
                        : "Trend: declining"
                )
            }
        }
    }

    /// Line chart plotting accuracy percentage over session dates.
    ///
    /// Uses `LineMark` with Catmull-Rom interpolation for smooth curves
    /// and `PointMark` to highlight individual data points. The Y axis
    /// is fixed from 0% to 100%.
    private var accuracyChart: some View {
        Chart(sortedEntries) { entry in
            LineMark(
                x: .value("Date", entry.date),
                y: .value("Accuracy", entry.accuracyPercent)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.accentColor.gradient)

            PointMark(
                x: .value("Date", entry.date),
                y: .value("Accuracy", entry.accuracyPercent)
            )
            .foregroundStyle(Color.accentColor)
            .symbolSize(30)
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)%")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(chartAccessibilityLabel)
    }

    // MARK: - Stats Grid Section

    /// Grid of summary statistics below the chart.
    ///
    /// Displays four `StatCard` views in a 2x2 grid showing total sessions,
    /// average accuracy, total practice minutes, and total XP earned.
    private var statsGridSection: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            StatCard(
                icon: "number",
                label: "Sessions",
                value: "\(entries.count)",
                iconColor: .blue
            )

            StatCard(
                icon: "target",
                label: "Avg Accuracy",
                value: formattedAverageAccuracy,
                iconColor: averageAccuracyColor
            )

            StatCard(
                icon: "clock",
                label: "Total Minutes",
                value: "\(totalMinutes)",
                iconColor: .purple
            )

            StatCard(
                icon: "sparkles",
                label: "Total XP",
                value: "\(totalXP)",
                iconColor: .yellow
            )
        }
    }

    // MARK: - Computed Properties

    /// Entries sorted by date ascending for chart plotting.
    private var sortedEntries: [RiyazEntry] {
        entries.sorted { $0.date < $1.date }
    }

    /// Sum of all practice session durations in minutes.
    private var totalMinutes: Int {
        entries.reduce(0) { $0 + $1.durationMinutes }
    }

    /// Sum of all XP earned across sessions.
    private var totalXP: Int {
        entries.reduce(0) { $0 + $1.xpEarned }
    }

    /// Average accuracy across all sessions, formatted as a percentage string.
    private var formattedAverageAccuracy: String {
        guard !entries.isEmpty else { return "0%" }
        let average = entries.reduce(0.0) { $0 + $1.accuracyPercent } / Double(entries.count)
        return "\(Int(average))%"
    }

    /// Color for the average accuracy stat card based on overall performance.
    private var averageAccuracyColor: Color {
        guard !entries.isEmpty else { return .secondary }
        let average = entries.reduce(0.0) { $0 + $1.accuracyPercent } / Double(entries.count)
        if average >= 90 { return .green }
        if average >= 70 { return .blue }
        if average >= 50 { return .orange }
        return .red
    }

    /// Accessibility label summarizing the chart data for VoiceOver.
    private var chartAccessibilityLabel: String {
        guard !entries.isEmpty else {
            return "Accuracy trend chart with no data"
        }
        let sessionCount = entries.count
        let average = entries.reduce(0.0) { $0 + $1.accuracyPercent } / Double(sessionCount)
        return "Accuracy trend chart showing \(sessionCount) sessions with an average of \(Int(average)) percent"
    }

    // MARK: - Helpers

    /// Compute whether the player's accuracy trend is improving or declining.
    ///
    /// Splits the sorted entries into first half and second half, then
    /// compares their average accuracies. If the second half is equal to
    /// or higher than the first, the trend is considered improving.
    ///
    /// - Returns: A `TrendResult` indicating direction.
    private func computeTrend() -> TrendResult {
        let sorted = sortedEntries
        guard sorted.count >= 2 else { return TrendResult(isImproving: true) }

        let midpoint = sorted.count / 2
        let firstHalf = sorted.prefix(midpoint)
        let secondHalf = sorted.suffix(from: midpoint)

        let firstAvg =
            firstHalf.reduce(0.0) { $0 + $1.accuracyPercent }
            / Double(firstHalf.count)
        let secondAvg =
            secondHalf.reduce(0.0) { $0 + $1.accuracyPercent }
            / Double(secondHalf.count)

        return TrendResult(isImproving: secondAvg >= firstAvg)
    }
}

// MARK: - Supporting Types

/// Result of a trend calculation comparing first-half and second-half averages.
private struct TrendResult {
    /// Whether the second half average is equal to or greater than the first half.
    let isImproving: Bool
}

// MARK: - Previews

#Preview("With History") {
    ScrollView {
        PracticeHistoryView(
            entries: previewRiyazEntries()
        )
        .padding()
    }
}

#Preview("Empty State") {
    PracticeHistoryView(entries: [])
        .padding()
}

/// Generate sample practice entries for Xcode previews.
///
/// Creates a sequence of entries over the past two weeks with
/// gradually improving accuracy to demonstrate the chart trend.
///
/// - Returns: Array of sample `RiyazEntry` values.
private func previewRiyazEntries() -> [RiyazEntry] {
    let calendar = Calendar.current
    let baseAccuracies: [Double] = [45, 52, 58, 55, 65, 72, 68, 75, 80, 78, 85, 88]

    return baseAccuracies.enumerated().map { index, accuracy in
        let date =
            calendar.date(
                byAdding: .day,
                value: -baseAccuracies.count + index + 1,
                to: Date()
            ) ?? Date()

        return RiyazEntry(
            date: date,
            durationMinutes: Int.random(in: 10...30),
            notesPlayed: Int.random(in: 20...80),
            accuracyPercent: accuracy,
            xpEarned: Int(accuracy) * 2,
            raagPracticed: ["Yaman", "Bhairav", "Kafi", "Bilawal"][index % 4]
        )
    }
}

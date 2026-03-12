import SwiftUI

/// Full-screen step-by-step lesson experience.
///
/// Presents lesson steps one at a time with navigation controls (back/next),
/// a progress bar, and step counter. Each step type renders differently:
/// - `intro`: Text card with lesson overview
/// - `listen`: Audio placeholder
/// - `read`: Text content display
/// - `exercise`: Interactive placeholder
/// - `practice`: Practice placeholder
/// - `quiz`: Quiz placeholder
///
/// On the final step, shows a "Complete Lesson" button that triggers the
/// completion callback and dismisses the view.
struct LessonStepView: View {
    // MARK: - Properties

    /// The lesson being studied.
    let lesson: Lesson

    /// The decoded steps to present.
    let steps: [LessonStep]

    /// Callback invoked when the lesson is completed.
    let onComplete: () -> Void

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    /// The current step index (0-based).
    @State
    private var currentStepIndex = 0

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                progressBar

                // Step content
                ScrollView {
                    stepContent
                        .padding()
                        .id(currentStepIndex)
                }

                Divider()

                // Navigation controls
                navigationControls
                    .padding()
            }
            .navigationTitle(lesson.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("Close lesson"))
                    .accessibilityHint(Text("Double tap to exit the lesson"))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(currentStepIndex + 1) of \(steps.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(
                            Text("Step \(currentStepIndex + 1) of \(steps.count)")
                        )
                }
            }
        }
    }

    // MARK: - Subviews

    /// Progress bar showing step completion.
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))

                Rectangle()
                    .fill(Color.accentColor)
                    .frame(
                        width: geometry.size.width * progressFraction
                    )
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }

    /// Content area for the current step.
    @ViewBuilder
    private var stepContent: some View {
        let step = steps[currentStepIndex]

        VStack(alignment: .leading, spacing: 16) {
            // Step type badge
            HStack {
                Image(systemName: stepTypeIcon(step.stepType))
                    .foregroundStyle(stepTypeColor(step.stepType))
                Text(stepTypeLabel(step.stepType))
                    .fontWeight(.semibold)
                    .foregroundStyle(stepTypeColor(step.stepType))
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(stepTypeColor(step.stepType).opacity(0.15))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Step type: \(stepTypeLabel(step.stepType))"))

            // Main content
            Text(verbatim: step.content)
                .font(.body)
                .lineSpacing(6)

            // Duration indicator (if available)
            if let seconds = step.durationSeconds {
                Label(
                    durationLabel(seconds),
                    systemImage: "timer"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Step-type-specific placeholder
            stepTypePlaceholder(step.stepType)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Navigation buttons (Previous / Next / Complete).
    private var navigationControls: some View {
        HStack {
            // Previous button
            Button {
                navigateToPreviousStep()
            } label: {
                Label("Previous", systemImage: "chevron.left")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .disabled(currentStepIndex == 0)
            .accessibilityLabel(Text("Previous step"))
            .accessibilityHint(Text("Double tap to go to the previous step"))

            Spacer()

            // Next / Complete button
            if isLastStep {
                Button {
                    onComplete()
                    dismiss()
                } label: {
                    Text("Complete Lesson")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.green)
                        )
                }
                .accessibilityLabel(Text("Complete lesson"))
                .accessibilityHint(
                    Text("Double tap to mark this lesson as completed and close")
                )
            } else {
                Button {
                    navigateToNextStep()
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .font(.body)
                        .fontWeight(.medium)
                        .labelStyle(.titleAndIcon)
                }
                .accessibilityLabel(Text("Next step"))
                .accessibilityHint(Text("Double tap to go to the next step"))
            }
        }
    }

    /// Placeholder content for step types that need special UI.
    @ViewBuilder
    private func stepTypePlaceholder(_ type: String) -> some View {
        switch type {
        case "listen":
            placeholderCard(
                icon: "headphones",
                title: "Audio Playback",
                description: "Audio playback coming soon"
            )

        case "exercise":
            placeholderCard(
                icon: "hand.tap",
                title: "Interactive Exercise",
                description: "Interactive exercises coming soon"
            )

        case "practice":
            placeholderCard(
                icon: "music.mic",
                title: "Practice Mode",
                description: "Practice mode integration coming soon"
            )

        case "quiz":
            placeholderCard(
                icon: "questionmark.circle",
                title: "Quiz",
                description: "Quizzes coming soon"
            )

        case "sing":
            placeholderCard(
                icon: "waveform",
                title: "Sing Along",
                description: "Sing along mode coming soon"
            )

        default:
            EmptyView()
        }
    }

    /// A placeholder card for unimplemented step features.
    private func placeholderCard(
        icon: String,
        title: String,
        description: String
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(description)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title): \(description)"))
    }

    // MARK: - Computed Properties

    /// Progress as a fraction (0.0–1.0).
    private var progressFraction: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(currentStepIndex + 1) / Double(steps.count)
    }

    /// Whether the current step is the last one.
    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    // MARK: - Private Methods

    /// Navigate to the previous step with animation.
    private func navigateToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        if reduceMotion {
            currentStepIndex -= 1
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStepIndex -= 1
            }
        }
    }

    /// Navigate to the next step with animation.
    private func navigateToNextStep() {
        guard currentStepIndex < steps.count - 1 else { return }
        if reduceMotion {
            currentStepIndex += 1
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStepIndex += 1
            }
        }
    }

    /// Human-readable label for a step type.
    private func stepTypeLabel(_ type: String) -> String {
        switch type {
        case "intro": "Introduction"
        case "listen": "Listen"
        case "read": "Read"
        case "exercise": "Exercise"
        case "practice": "Practice"
        case "quiz": "Quiz"
        case "sing": "Sing Along"
        default: type.capitalized
        }
    }

    /// SF Symbol icon for a step type.
    private func stepTypeIcon(_ type: String) -> String {
        switch type {
        case "intro": "text.book.closed"
        case "listen": "headphones"
        case "read": "doc.text"
        case "exercise": "hand.tap"
        case "practice": "music.mic"
        case "quiz": "questionmark.circle"
        case "sing": "waveform"
        default: "circle"
        }
    }

    /// Color for a step type.
    private func stepTypeColor(_ type: String) -> Color {
        switch type {
        case "intro": .blue
        case "listen": .purple
        case "read": .orange
        case "exercise": .green
        case "practice": .red
        case "quiz": .yellow
        case "sing": .pink
        default: .gray
        }
    }

    /// Format seconds into a human-readable duration.
    private func durationLabel(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remaining = seconds % 60
        if remaining == 0 {
            return "\(minutes) min"
        }
        return "\(minutes)m \(remaining)s"
    }
}

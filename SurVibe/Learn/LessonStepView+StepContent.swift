import SwiftUI

// MARK: - Step Type Views

extension LessonStepView {
    /// Content view for intro and read step types.
    ///
    /// Displays the step content as readable text. These steps are always
    /// unlocked and require no interaction to advance.
    ///
    /// - Parameter step: The lesson step to display.
    /// - Returns: A text content view.
    func introReadContent(step: LessonStep) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: step.content)
                .font(.body)
                .lineSpacing(6)
        }
    }

    /// Content view for listen step type.
    ///
    /// Displays the step content with an audio playback placeholder.
    /// The gate unlocks when the learner taps the "Mark as Listened" button.
    ///
    /// - Parameters:
    ///   - step: The lesson step to display.
    ///   - viewModel: The view model for gate callbacks.
    /// - Returns: A view with text and audio controls.
    func listenContent(step: LessonStep, viewModel: LessonPlayerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: step.content)
                .font(.body)
                .lineSpacing(6)

            placeholderCard(
                icon: "headphones",
                title: "Audio Playback",
                description: "Audio playback will be available soon"
            )

            if viewModel.gateStatus != .unlocked {
                Button {
                    viewModel.listenCompleted()
                } label: {
                    Label("Mark as Listened", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.purple)
                        )
                }
                .accessibilityLabel(Text("Mark as listened"))
                .accessibilityHint(
                    Text("Double tap to mark this step as listened and unlock the next step")
                )
            }
        }
    }

    /// Content view for sing step type.
    ///
    /// Displays the step content with a singing placeholder.
    /// The gate unlocks when accuracy >= 0.60 or the learner taps "Skip".
    ///
    /// - Parameters:
    ///   - step: The lesson step to display.
    ///   - viewModel: The view model for gate callbacks.
    /// - Returns: A view with text and singing controls.
    func singContent(step: LessonStep, viewModel: LessonPlayerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: step.content)
                .font(.body)
                .lineSpacing(6)

            placeholderCard(
                icon: "waveform",
                title: "Sing Along",
                description: "Sing along mode will be available soon"
            )

            if viewModel.gateStatus != .unlocked {
                HStack(spacing: 12) {
                    Button {
                        viewModel.singManualAdvance()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(.secondary)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                    }
                    .accessibilityLabel(Text("Skip singing"))
                    .accessibilityHint(
                        Text("Double tap to skip the singing step and continue")
                    )

                    Button {
                        viewModel.singCompleted(accuracy: 1.0)
                    } label: {
                        Label("Done Singing", systemImage: "checkmark.circle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.pink)
                            )
                    }
                    .accessibilityLabel(Text("Done singing"))
                    .accessibilityHint(
                        Text("Double tap to mark singing as complete")
                    )
                }
            }
        }
    }

    /// Content view for exercise and practice step types.
    ///
    /// Displays the step content with an exercise placeholder.
    /// The gate unlocks when the learner completes the exercise.
    ///
    /// - Parameters:
    ///   - step: The lesson step to display.
    ///   - viewModel: The view model for gate callbacks.
    /// - Returns: A view with text and exercise controls.
    func exerciseContent(
        step: LessonStep,
        viewModel: LessonPlayerViewModel
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: step.content)
                .font(.body)
                .lineSpacing(6)

            placeholderCard(
                icon: step.stepType == "practice" ? "music.mic" : "hand.tap",
                title: step.stepType == "practice" ? "Practice Mode" : "Interactive Exercise",
                description: step.stepType == "practice"
                    ? "Practice mode will be available soon"
                    : "Interactive exercises will be available soon"
            )

            if viewModel.gateStatus != .unlocked {
                Button {
                    viewModel.exerciseCompleted()
                } label: {
                    Label("Mark as Complete", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green)
                        )
                }
                .accessibilityLabel(Text("Mark exercise as complete"))
                .accessibilityHint(
                    Text("Double tap to mark the exercise as complete and unlock the next step")
                )
            }
        }
    }

    /// Content view for quiz step type.
    ///
    /// Displays the step content with a quiz placeholder.
    /// The gate unlocks when the learner completes the quiz.
    ///
    /// - Parameters:
    ///   - step: The lesson step to display.
    ///   - viewModel: The view model for gate callbacks.
    /// - Returns: A view with text and quiz controls.
    func quizContent(step: LessonStep, viewModel: LessonPlayerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: step.content)
                .font(.body)
                .lineSpacing(6)

            placeholderCard(
                icon: "questionmark.circle",
                title: "Quiz",
                description: "Quizzes will be available soon"
            )

            if viewModel.gateStatus != .unlocked {
                Button {
                    viewModel.quizCompleted(score: 1.0)
                } label: {
                    Label("Complete Quiz", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.yellow)
                        )
                }
                .accessibilityLabel(Text("Complete quiz"))
                .accessibilityHint(
                    Text("Double tap to mark the quiz as complete and unlock the next step")
                )
            }
        }
    }
}

// MARK: - Helper Views & Utilities

extension LessonStepView {
    /// A placeholder card for unimplemented step features.
    ///
    /// - Parameters:
    ///   - icon: SF Symbol name for the card icon.
    ///   - title: Headline text.
    ///   - description: Caption text.
    /// - Returns: A styled card view.
    func placeholderCard(
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

    /// Human-readable label for a step type.
    ///
    /// - Parameter type: The step type string identifier.
    /// - Returns: A display-friendly label.
    func stepTypeLabel(_ type: String) -> String {
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

    /// SF Symbol icon name for a step type.
    ///
    /// - Parameter type: The step type string identifier.
    /// - Returns: An SF Symbol name.
    func stepTypeIcon(_ type: String) -> String {
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

    /// Color associated with a step type.
    ///
    /// - Parameter type: The step type string identifier.
    /// - Returns: A color for the step badge and icon.
    func stepTypeColor(_ type: String) -> Color {
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

    /// Format seconds into a human-readable duration string.
    ///
    /// - Parameter seconds: Duration in seconds.
    /// - Returns: A formatted string like "30s", "2 min", or "1m 30s".
    func durationLabel(_ seconds: Int) -> String {
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

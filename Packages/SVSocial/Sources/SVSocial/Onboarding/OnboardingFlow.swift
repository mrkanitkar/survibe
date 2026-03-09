import SwiftUI
import SVCore

/// Onboarding flow for new users.
/// Full implementation in Sprint 1.
public struct OnboardingFlow: View {
    public init() {}

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "music.mic")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Welcome to SurVibe")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Learn Indian classical music with real-time feedback")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .scaledPadding(Spacing.xl)
    }
}

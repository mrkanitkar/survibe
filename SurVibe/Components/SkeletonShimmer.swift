import SwiftUI

/// A shimmer animation modifier for loading/skeleton states.
///
/// Overlays a gradient that animates horizontally to indicate content is loading.
/// Respects `accessibilityReduceMotion` — when enabled, shows a static
/// semi-transparent overlay instead of an animation.
///
/// Usage:
/// ```swift
/// RoundedRectangle(cornerRadius: 8)
///     .fill(Color.gray.opacity(0.2))
///     .frame(height: 44)
///     .modifier(SkeletonShimmer())
/// ```
struct SkeletonShimmer: ViewModifier {
    // MARK: - Properties

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    // MARK: - Body

    func body(content: Content) -> some View {
        if reduceMotion {
            content
                .overlay(
                    Color(.systemGray4)
                        .opacity(0.3)
                        .allowsHitTesting(false)
                )
        } else {
            content
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.4),
                            .clear,
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase * 300)
                    .allowsHitTesting(false)
                )
                .clipped()
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies a shimmer animation for loading/skeleton states.
    ///
    /// - Returns: The view with a shimmer overlay.
    func shimmer() -> some View {
        modifier(SkeletonShimmer())
    }
}

// MARK: - Preview

#Preview("Shimmer") {
    VStack(spacing: 16) {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(height: 44)
            .shimmer()

        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(height: 20)
            .shimmer()

        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(height: 20)
            .shimmer()
    }
    .padding()
}

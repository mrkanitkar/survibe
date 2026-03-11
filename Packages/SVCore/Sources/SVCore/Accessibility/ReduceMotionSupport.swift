import SwiftUI

/// View modifier that respects the Reduce Motion accessibility setting.
///
/// Intercepts ALL animations in the subtree — not just changes to the
/// `reduceMotion` environment value itself — by using `.transaction`.
/// When the user has enabled Reduce Motion, every animation in the
/// modified view hierarchy is replaced with `nil` (instant transition).
public struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func body(content: Content) -> some View {
        content.transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
            }
        }
    }
}

extension View {
    /// Intercepts all animations in the subtree and removes them when
    /// the system Reduce Motion setting is enabled.
    ///
    /// Uses `.transaction` to suppress animations globally within the
    /// modified view hierarchy, unlike `.animation(value:)` which only
    /// watches a single value. Prefer this over manual
    /// `@Environment(\.accessibilityReduceMotion)` checks when you want
    /// blanket animation suppression for an entire subtree.
    ///
    /// - Returns: A view that respects the Reduce Motion accessibility setting.
    public func respectsReduceMotion() -> some View {
        modifier(ReduceMotionModifier())
    }

    /// Conditionally applies an animation only when Reduce Motion is OFF.
    ///
    /// Use this when you need a specific animation on a specific value
    /// transition but want to respect the accessibility setting.
    /// For blanket subtree suppression, use `.respectsReduceMotion()` instead.
    ///
    /// - Parameters:
    ///   - animation: The animation to apply when Reduce Motion is OFF.
    ///   - value: The value to observe for changes.
    /// - Returns: A view with conditional animation applied.
    public func conditionalAnimation<V: Equatable>(
        _ animation: Animation = .default,
        value: V
    ) -> some View {
        modifier(ConditionalAnimationModifier(animation: animation, value: value))
    }
}

/// View modifier that applies an animation to a specific value only when
/// the system Reduce Motion setting is disabled.
///
/// When Reduce Motion is enabled, state changes are applied instantly
/// without animation, satisfying WCAG 2.1 Success Criterion 2.3.3.
public struct ConditionalAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    public func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

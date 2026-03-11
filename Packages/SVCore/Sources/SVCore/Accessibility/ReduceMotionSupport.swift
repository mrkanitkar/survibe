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
    public func respectsReduceMotion() -> some View {
        modifier(ReduceMotionModifier())
    }
}

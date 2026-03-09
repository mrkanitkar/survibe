import SwiftUI

/// View modifier that respects Reduce Motion accessibility setting.
public struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : .default, value: reduceMotion)
    }
}

extension View {
    public func respectsReduceMotion() -> some View {
        modifier(ReduceMotionModifier())
    }
}

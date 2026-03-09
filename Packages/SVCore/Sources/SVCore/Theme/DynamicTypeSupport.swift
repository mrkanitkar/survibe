import SwiftUI

/// View modifier for Dynamic Type support with scaled padding.
public struct ScaledPadding: ViewModifier {
    @ScaledMetric private var scaledValue: CGFloat

    public init(_ value: CGFloat) {
        _scaledValue = ScaledMetric(wrappedValue: value)
    }

    public func body(content: Content) -> some View {
        content.padding(scaledValue)
    }
}

/// View modifier for scaled spacing in stacks.
public struct ScaledSpacing: ViewModifier {
    @ScaledMetric private var scaledValue: CGFloat

    public init(_ value: CGFloat) {
        _scaledValue = ScaledMetric(wrappedValue: value)
    }

    public func body(content: Content) -> some View {
        content.padding(.vertical, scaledValue / 2)
    }
}

extension View {
    /// Apply padding that scales with Dynamic Type.
    public func scaledPadding(_ value: CGFloat = Spacing.md) -> some View {
        modifier(ScaledPadding(value))
    }

    /// Apply scaled spacing between items.
    public func scaledSpacing(_ value: CGFloat = Spacing.sm) -> some View {
        modifier(ScaledSpacing(value))
    }
}

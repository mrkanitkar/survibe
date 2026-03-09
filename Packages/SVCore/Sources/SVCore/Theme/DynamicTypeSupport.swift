import SwiftUI

/// View modifier for Dynamic Type support.
public struct ScaledPadding: ViewModifier {
    @ScaledMetric private var scaledValue: CGFloat

    public init(_ value: CGFloat) {
        _scaledValue = ScaledMetric(wrappedValue: value)
    }

    public func body(content: Content) -> some View {
        content.padding(scaledValue)
    }
}

extension View {
    public func scaledPadding(_ value: CGFloat = Spacing.md) -> some View {
        modifier(ScaledPadding(value))
    }
}

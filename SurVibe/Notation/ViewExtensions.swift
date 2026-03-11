import SwiftUI

extension View {
    /// Conditionally applies a view transformation.
    ///
    /// Uses `@ViewBuilder` to avoid `AnyView` type erasure, preserving
    /// SwiftUI's static type information for better rendering performance.
    ///
    /// - Parameters:
    ///   - condition: Whether to apply the transform.
    ///   - transform: The transformation to apply when condition is true.
    /// - Returns: Either the transformed view or the original view.
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        @ViewBuilder transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

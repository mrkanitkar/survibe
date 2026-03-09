import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Haptic feedback engine for musical interaction.
/// Full implementation in Batch 3.
public final class HapticEngine: @unchecked Sendable {
    public static let shared = HapticEngine()

    private init() {}

    /// Light tap for non-sam beats.
    public func lightTap() {
        // Batch 3: UIImpactFeedbackGenerator(style: .light)
    }

    /// Heavy tap for sam beats.
    public func heavyTap() {
        // Batch 3: UIImpactFeedbackGenerator(style: .heavy)
    }

    /// Success notification feedback.
    public func success() {
        // Batch 3: UINotificationFeedbackGenerator .success
    }

    /// Error notification feedback.
    public func error() {
        // Batch 3: UINotificationFeedbackGenerator .error
    }
}

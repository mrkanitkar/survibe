import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Haptic feedback engine for musical interaction.
/// MainActor-isolated since UIKit feedback generators require main thread.
@MainActor
public final class HapticEngine {
    public static let shared = HapticEngine()

    #if canImport(UIKit)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    #endif

    private init() {
        #if canImport(UIKit)
        lightGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        #endif
    }

    /// Light tap for non-sam beats.
    public func lightTap() {
        #if canImport(UIKit)
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
        #endif
    }

    /// Heavy tap for sam beats (first beat of a taal cycle).
    public func heavyTap() {
        #if canImport(UIKit)
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
        #endif
    }

    /// Success notification feedback (correct note, achievement unlocked).
    public func success() {
        #if canImport(UIKit)
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
        #endif
    }

    /// Error notification feedback (wrong note, session failed).
    public func error() {
        #if canImport(UIKit)
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
        #endif
    }
}

import SwiftUI

/// Manages the label opacity of Sargam notes based on user accuracy.
///
/// As the user's accuracy improves, note labels become more visible.
/// This creates a progressive reveal effect that encourages practice.
/// Thresholds follow the Rang level progression:
/// - >90% accuracy: full opacity (1.0)
/// - 70–90%: moderate opacity (0.7)
/// - 50–70%: reduced opacity (0.5)
/// - <50%: minimal opacity (0.25)
///
/// Transitions are animated with a 0.5-second ease-in-out curve.
@Observable
@MainActor
final class SargamFadeManager {
    // MARK: - Properties

    /// Current label opacity (0.0–1.0).
    private(set) var labelOpacity: Double = 1.0

    /// The most recent accuracy value that was applied.
    private(set) var currentAccuracy: Double = 1.0

    // MARK: - Public Methods

    /// Updates the label opacity based on the user's playing accuracy.
    ///
    /// The opacity is determined by accuracy thresholds that correspond
    /// to the Rang level system. Higher accuracy yields higher opacity,
    /// rewarding the user visually for better performance.
    ///
    /// - Parameter accuracy: A value from 0.0 (no accuracy) to 1.0 (perfect).
    ///   Values outside this range are clamped.
    func updateOpacity(accuracy: Double) {
        let clampedAccuracy = min(1.0, max(0.0, accuracy))
        currentAccuracy = clampedAccuracy

        let newOpacity: Double
        switch clampedAccuracy {
        case 0.9...1.0:
            newOpacity = 1.0
        case 0.7..<0.9:
            newOpacity = 0.7
        case 0.5..<0.7:
            newOpacity = 0.5
        default:
            newOpacity = 0.25
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            labelOpacity = newOpacity
        }
    }

    /// Resets opacity to full (1.0) without animation.
    ///
    /// Called when starting a new practice session or switching songs
    /// to ensure the user sees all labels from the beginning.
    func reset() {
        labelOpacity = 1.0
        currentAccuracy = 1.0
    }
}

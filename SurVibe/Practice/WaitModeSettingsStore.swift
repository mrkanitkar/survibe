import Foundation
import SVLearning

/// Persists Wait Mode user preferences via @AppStorage.
///
/// Reads/writes to UserDefaults and exposes a computed
/// `WaitModeConfiguration` for consumption by the practice VM.
@Observable
@MainActor
final class WaitModeSettingsStore {
    /// Whether Wait Mode is enabled.
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "com.survibe.waitMode.enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "com.survibe.waitMode.enabled") }
    }

    /// Selected wait criteria raw value.
    var waitCriteriaRawValue: String {
        get {
            UserDefaults.standard.string(forKey: "com.survibe.waitMode.criteria")
                ?? WaitCriteria.correctPitch.rawValue
        }
        set { UserDefaults.standard.set(newValue, forKey: "com.survibe.waitMode.criteria") }
    }

    /// Patience timeout in seconds (0 = unlimited).
    var patienceSeconds: Double {
        get {
            let value = UserDefaults.standard.double(forKey: "com.survibe.waitMode.patience")
            return value > 0 ? value : 10.0
        }
        set { UserDefaults.standard.set(newValue, forKey: "com.survibe.waitMode.patience") }
    }

    /// Pitch tolerance in cents.
    var pitchToleranceCents: Double {
        get {
            let value = UserDefaults.standard.double(forKey: "com.survibe.waitMode.tolerance")
            return value > 0 ? value : 25.0
        }
        set { UserDefaults.standard.set(newValue, forKey: "com.survibe.waitMode.tolerance") }
    }

    /// The selected wait criteria as a typed enum.
    var waitCriteria: WaitCriteria {
        get { WaitCriteria(rawValue: waitCriteriaRawValue) ?? .correctPitch }
        set { waitCriteriaRawValue = newValue.rawValue }
    }

    /// Build a `WaitModeConfiguration` from the current settings.
    var configuration: WaitModeConfiguration {
        WaitModeConfiguration(
            isEnabled: isEnabled,
            waitCriteria: waitCriteria,
            patienceSeconds: patienceSeconds,
            pitchToleranceCents: pitchToleranceCents
        )
    }
}

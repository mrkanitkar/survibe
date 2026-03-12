import SwiftUI
import SVLearning

/// Settings form for configuring Wait Mode behavior.
///
/// Allows the student to toggle Wait Mode, select criteria,
/// adjust patience timeout, and set pitch tolerance.
struct WaitModeSettingsView: View {
    @Bindable var store: WaitModeSettingsStore

    var body: some View {
        Form {
            Section {
                Toggle("Enable Wait Mode", isOn: $store.isEnabled)
                    .accessibilityLabel("Wait Mode")
                    .accessibilityHint("When enabled, practice pauses at each note until you play it correctly")
            } header: {
                Text("Wait Mode")
            } footer: {
                Text("Wait Mode pauses at each note and waits for you to play the correct pitch before advancing.")
            }

            if store.isEnabled {
                Section("Criteria") {
                    Picker("Advance when", selection: $store.waitCriteria) {
                        Text("Correct pitch").tag(WaitCriteria.correctPitch)
                        Text("Within tolerance").tag(WaitCriteria.withinTolerance)
                        Text("Pitch + duration").tag(WaitCriteria.pitchAndDuration)
                    }
                    .accessibilityLabel("Wait criteria")
                    .accessibilityHint("Choose what you need to match before advancing to the next note")
                }

                Section("Patience") {
                    HStack {
                        Text("Timeout")
                        Spacer()
                        Text(patienceText)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Patience timeout: \(patienceText)")

                    Slider(
                        value: $store.patienceSeconds,
                        in: 0...30,
                        step: 1
                    )
                    .accessibilityLabel("Patience timeout slider")
                    .accessibilityValue(patienceText)
                }

                if store.waitCriteria == .withinTolerance {
                    Section("Pitch Tolerance") {
                        HStack {
                            Text("Tolerance")
                            Spacer()
                            Text("\(Int(store.pitchToleranceCents)) cents")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Pitch tolerance: \(Int(store.pitchToleranceCents)) cents")

                        Slider(
                            value: $store.pitchToleranceCents,
                            in: 5...50,
                            step: 5
                        )
                        .accessibilityLabel("Pitch tolerance slider")
                        .accessibilityValue("\(Int(store.pitchToleranceCents)) cents")
                    }
                }
            }
        }
        .navigationTitle("Wait Mode Settings")
    }

    private var patienceText: String {
        if store.patienceSeconds == 0 {
            return "Unlimited"
        }
        return "\(Int(store.patienceSeconds))s"
    }
}

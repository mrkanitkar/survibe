import Testing

@testable import SVAudio

@Suite("AudioSessionManager Tests")
struct AudioSessionManagerTests {
    @Test("Singleton exists")
    @MainActor
    func singletonExists() {
        let manager = AudioSessionManager.shared
        #expect(manager != nil)
    }

    @Test("Sample rate returns a positive value")
    @MainActor
    func sampleRateIsPositive() {
        #expect(AudioSessionManager.shared.sampleRate > 0)
    }

    @Test("deactivate does not crash on unconfigured session")
    @MainActor
    func deactivateOnUnconfiguredSession() {
        // Calling deactivate without prior configure should log a warning
        // but not crash or throw.
        AudioSessionManager.shared.deactivate()
    }

    @Test("Interruption callbacks default to nil")
    @MainActor
    func interruptionCallbacksDefaultNil() {
        let manager = AudioSessionManager.shared
        #expect(manager.onInterruptionBegan == nil)
        #expect(manager.onInterruptionEnded == nil)
    }

    @Test("Route change callback defaults to nil")
    @MainActor
    func routeChangeCallbackDefaultsNil() {
        let manager = AudioSessionManager.shared
        #expect(manager.onRouteChange == nil)
    }

    @Test("Callbacks can be assigned and cleared")
    @MainActor
    func callbacksAssignableAndClearable() {
        let manager = AudioSessionManager.shared

        // Assign callbacks
        manager.onInterruptionBegan = { }
        manager.onInterruptionEnded = { _ in }
        manager.onRouteChange = { }

        #expect(manager.onInterruptionBegan != nil)
        #expect(manager.onInterruptionEnded != nil)
        #expect(manager.onRouteChange != nil)

        // Clear callbacks
        manager.onInterruptionBegan = nil
        manager.onInterruptionEnded = nil
        manager.onRouteChange = nil

        #expect(manager.onInterruptionBegan == nil)
        #expect(manager.onInterruptionEnded == nil)
        #expect(manager.onRouteChange == nil)
    }
}

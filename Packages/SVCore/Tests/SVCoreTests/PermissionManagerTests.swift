import Testing

@testable import SVCore

@Suite("PermissionManager Tests")
struct PermissionManagerTests {
    @Test("MicrophonePermissionStatus has four distinct cases")
    func statusCasesAreDistinct() {
        let statuses: Set<String> = [
            "\(MicrophonePermissionStatus.notDetermined)",
            "\(MicrophonePermissionStatus.authorized)",
            "\(MicrophonePermissionStatus.denied)",
            "\(MicrophonePermissionStatus.restricted)",
        ]
        #expect(statuses.count == 4)
    }

    @Test("Initial state is not authorized in test environment")
    @MainActor
    func initialStateIsNotAuthorized() {
        let manager = PermissionManager.shared
        #expect(manager.microphoneStatus != .authorized)
    }

    @Test("hasShownDeniedMessage defaults to false")
    @MainActor
    func deniedMessageDefaultsFalse() {
        #expect(PermissionManager.shared.hasShownDeniedMessage == false)
    }

    @Test("settingsURL produces a valid URL with a scheme")
    @MainActor
    func settingsURLIsValid() {
        let url = PermissionManager.shared.settingsURL
        #expect(url != nil)
        #expect(url?.scheme != nil)
    }

    @Test("updateMicrophoneStatus sets a valid state")
    @MainActor
    func updateStatusSetsValidState() {
        let manager = PermissionManager.shared
        manager.updateMicrophoneStatus()
        switch manager.microphoneStatus {
        case .notDetermined, .authorized, .denied, .restricted:
            break
        }
    }

    @Test("requestMicrophoneAccess returns false in test environment")
    @MainActor
    func requestMicrophoneAccessReturnsFalse() async {
        let manager = PermissionManager.shared
        // In the test runner, mic permission is never granted.
        // This exercises the full requestMicrophoneAccess() code path:
        // - If .notDetermined: calls AVAudioApplication.requestRecordPermission()
        //   which is denied in the test sandbox, then updates status.
        // - If already .denied: returns false via the guard early-return.
        let granted = await manager.requestMicrophoneAccess()
        #expect(granted == false)
        // After the call, status should reflect the sandbox reality
        #expect(manager.microphoneStatus != .authorized)
    }
}

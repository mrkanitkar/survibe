import Testing
@testable import SVCore

@Suite("PermissionManager Tests")
struct PermissionManagerTests {
    @Test("MicrophonePermissionStatus has all expected cases")
    func testStatusCases() {
        let statuses: [MicrophonePermissionStatus] = [
            .notDetermined,
            .authorized,
            .denied,
            .restricted
        ]
        #expect(statuses.count == 4)
    }

    @Test("PermissionManager singleton exists")
    @MainActor
    func testSingleton() {
        let manager = PermissionManager.shared
        #expect(manager != nil)
    }
}

import Testing

@testable import SVCore

@Suite("AuthManager Tests")
struct AuthManagerTests {
    @Test("isAuthenticated defaults to false")
    @MainActor
    func defaultNotAuthenticated() {
        let manager = AuthManager.shared
        #expect(manager.isAuthenticated == false)
    }

    @Test("signOut sets isAuthenticated to false")
    @MainActor
    func signOutResetsState() async throws {
        let manager = AuthManager.shared
        try await manager.signOut()
        #expect(manager.isAuthenticated == false)
    }

    @Test("signIn is a no-op in Sprint 0")
    @MainActor
    func signInNoOp() async throws {
        let manager = AuthManager.shared
        // signIn is not implemented — should not throw or crash
        try await manager.signIn()
        // State should remain unchanged (still false in Sprint 0)
        #expect(manager.isAuthenticated == false)
    }
}

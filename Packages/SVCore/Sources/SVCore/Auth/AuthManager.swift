import Foundation

/// Protocol defining authentication operations.
public protocol AuthManagerProtocol: Sendable {
    func signIn() async throws
    func signOut() async throws
    var isAuthenticated: Bool { get }
}

/// Placeholder auth manager for Sprint 0.
public final class AuthManager: AuthManagerProtocol, @unchecked Sendable {
    public static let shared = AuthManager()
    public var isAuthenticated: Bool = false

    private init() {}

    public func signIn() async throws {
        // Sprint 1+: Implement Sign in with Apple
    }

    public func signOut() async throws {
        isAuthenticated = false
    }
}

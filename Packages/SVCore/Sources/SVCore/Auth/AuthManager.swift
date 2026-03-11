import Foundation
import Observation
import os

/// Protocol defining authentication operations.
/// Conforming types should be @MainActor-isolated for UI-safe state access.
public protocol AuthManagerProtocol: Sendable {
    @MainActor func signIn() async throws
    @MainActor func signOut() async throws
    @MainActor var isAuthenticated: Bool { get }
}

/// Placeholder auth manager for Sprint 0.
/// Uses @Observable + @MainActor for thread-safe, SwiftUI-reactive state.
@MainActor
@Observable
public final class AuthManager: AuthManagerProtocol {
    public static let shared = AuthManager()
    public private(set) var isAuthenticated: Bool = false

    private static let logger = Logger(
        subsystem: "com.survibe",
        category: "Auth"
    )

    private init() {}

    /// Sign in using Sign in with Apple.
    ///
    /// - Important: **Not implemented in Sprint 0.** This is a placeholder that no-ops.
    ///   Sprint 1 will add Sign in with Apple via `AuthenticationServices`.
    ///   Until then, `isAuthenticated` remains `false` and all features are available
    ///   in offline/anonymous mode.
    public func signIn() async throws {
        Self.logger.info("signIn() called — not yet implemented (Sprint 1).")
        #warning("AuthManager.signIn() not implemented — Sprint 1")
    }

    /// Sign out and reset authentication state.
    public func signOut() async throws {
        isAuthenticated = false
        Self.logger.info("User signed out.")
    }
}

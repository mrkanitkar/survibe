import Foundation

/// Represents the current authentication state of the user.
///
/// Transitions flow: `anonymous` → `authenticating` → `authenticated` or `error`.
/// Sign-out transitions: `authenticated` → `signedOut`.
/// Credential revocation: `authenticated` → `error(.credentialRevoked)`.
public enum AuthState: Sendable {
    /// User has not signed in (default state on fresh install).
    case anonymous
    /// Sign in with Apple flow is in progress.
    case authenticating
    /// User is authenticated with a valid Apple ID credential.
    case authenticated(AppleUser)
    /// User explicitly signed out.
    case signedOut
    /// An error occurred during authentication.
    case error(AuthError)
}

// MARK: - Equatable

extension AuthState: Equatable {
    public static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.anonymous, .anonymous):
            return true
        case (.authenticating, .authenticating):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser == rhsUser
        case (.signedOut, .signedOut):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

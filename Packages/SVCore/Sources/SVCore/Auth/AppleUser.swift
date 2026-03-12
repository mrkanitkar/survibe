import Foundation

/// Represents an authenticated Apple ID user.
///
/// Created from `ASAuthorizationAppleIDCredential` during the Sign in with Apple flow.
/// The `displayName` is formatted from `PersonNameComponents` at creation time
/// (since `PersonNameComponents` is not directly `Codable`).
///
/// Stored in Keychain for session restoration across app launches.
public struct AppleUser: Codable, Sendable, Equatable {
    /// The unique Apple ID identifier (stable across sign-ins).
    public let userIdentifier: String

    /// The user's formatted display name (may be empty if user withholds it).
    public let displayName: String

    /// The user's email address (may be nil if user uses Hide My Email or withholds it).
    public let email: String?

    /// Creates a new Apple user record.
    ///
    /// - Parameters:
    ///   - userIdentifier: The stable Apple ID identifier from `ASAuthorizationAppleIDCredential`.
    ///   - displayName: Pre-formatted display name string.
    ///   - email: Optional email address.
    public init(userIdentifier: String, displayName: String, email: String? = nil) {
        self.userIdentifier = userIdentifier
        self.displayName = displayName
        self.email = email
    }
}

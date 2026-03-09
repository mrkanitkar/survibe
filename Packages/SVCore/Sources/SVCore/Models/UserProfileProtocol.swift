import Foundation

/// Protocol defining the shape of a user profile for cross-package use.
public protocol UserProfileProtocol {
    var id: UUID { get }
    var displayName: String { get }
    var currentRang: Int { get }
    var totalXP: Int { get }
    var preferredLanguage: String { get }
}

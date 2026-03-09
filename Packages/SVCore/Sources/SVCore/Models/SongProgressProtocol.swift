import Foundation

/// Protocol for song progress tracking (bestScore uses max-wins).
public protocol SongProgressProtocol {
    var id: UUID { get }
    var songId: String { get }
    var bestScore: Int { get }
    var timesPlayed: Int { get }
}

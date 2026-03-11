import Foundation

/// Represents the state of song playback in SongPlaybackEngine.
///
/// The state machine transitions follow a well-defined lifecycle:
/// ```
/// idle → loading → (idle or error)
/// idle → playing ↔ paused
/// playing → stopped → idle
/// ```
///
/// When playback reaches the end of the song, the engine
/// transitions from `.playing` back to `.idle` automatically.
enum PlaybackState: Equatable, Sendable {
    /// No song loaded or playback finished.
    case idle

    /// Song data is being loaded and parsed.
    case loading

    /// Song is actively playing.
    case playing

    /// Playback is paused at current position.
    case paused

    /// Playback has been stopped (position resets to 0).
    case stopped

    /// An error occurred during loading or playback.
    case error(String)
}

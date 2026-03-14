import Foundation

/// Protocol abstracting SoundFont note playback for testability.
///
/// The production implementation is `SoundFontManager`, which plays
/// notes through `AVAudioUnitSampler`. Test doubles can record
/// calls without requiring audio hardware.
@MainActor
public protocol SoundFontPlaying: AnyObject {
    /// Whether a SoundFont instrument is currently loaded.
    var isLoaded: Bool { get }

    /// Play a MIDI note with the specified velocity.
    /// - Parameters:
    ///   - midiNote: MIDI note number (0–127).
    ///   - velocity: Key velocity (0–127, default: 100).
    ///   - channel: MIDI channel (0–15, default: 0).
    func playNote(midiNote: UInt8, velocity: UInt8, channel: UInt8)

    /// Stop a playing MIDI note.
    /// - Parameters:
    ///   - midiNote: MIDI note number to stop.
    ///   - channel: MIDI channel (0–15, default: 0).
    func stopNote(midiNote: UInt8, channel: UInt8)

    /// Stop all currently playing notes.
    func stopAllNotes()
}

import AVFoundation

/// Manages SoundFont instrument loading and MIDI note playback
/// via AVAudioUnitSampler.
/// Full implementation in Batch 7.
public final class SoundFontManager: @unchecked Sendable {
    public static let shared = SoundFontManager()

    private init() {}

    /// Load a SoundFont bank instrument.
    public func loadSoundFont(at url: URL, program: UInt8 = 0) throws {
        // Batch 7: AVAudioUnitSampler.loadSoundBankInstrument
    }

    /// Play a MIDI note with given velocity.
    public func playNote(midiNote: UInt8, velocity: UInt8 = 100, channel: UInt8 = 0) {
        // Batch 7: sampler.startNote
    }

    /// Stop a MIDI note.
    public func stopNote(midiNote: UInt8, channel: UInt8 = 0) {
        // Batch 7: sampler.stopNote
    }
}

import AVFoundation

/// Manages SoundFont instrument loading and MIDI note playback
/// via AVAudioUnitSampler connected to AudioEngineManager's engine.
public final class SoundFontManager: @unchecked Sendable {
    public static let shared = SoundFontManager()

    /// Reference to the engine's sampler node.
    private var sampler: AVAudioUnitSampler {
        AudioEngineManager.shared.sampler
    }

    /// Whether a SoundFont is currently loaded.
    public private(set) var isLoaded: Bool = false

    private init() {}

    /// Load a SoundFont bank instrument into the sampler.
    /// - Parameters:
    ///   - url: URL to the .sf2 SoundFont file
    ///   - program: MIDI program number (default: 0 = Piano)
    ///   - bankMSB: Bank MSB (default: kAUSampler_DefaultMelodicBankMSB)
    ///   - bankLSB: Bank LSB (default: 0)
    public func loadSoundFont(
        at url: URL,
        program: UInt8 = 0,
        bankMSB: UInt8 = UInt8(kAUSampler_DefaultMelodicBankMSB),
        bankLSB: UInt8 = 0
    ) throws {
        try sampler.loadSoundBankInstrument(
            at: url,
            program: program,
            bankMSB: bankMSB,
            bankLSB: bankLSB
        )
        isLoaded = true
    }

    /// Play a MIDI note with given velocity on the sampler.
    /// - Parameters:
    ///   - midiNote: MIDI note number (0-127)
    ///   - velocity: Key velocity (0-127, default: 100)
    ///   - channel: MIDI channel (0-15, default: 0)
    public func playNote(midiNote: UInt8, velocity: UInt8 = 100, channel: UInt8 = 0) {
        sampler.startNote(midiNote, withVelocity: velocity, onChannel: channel)
    }

    /// Stop a playing MIDI note.
    /// - Parameters:
    ///   - midiNote: MIDI note number to stop
    ///   - channel: MIDI channel (0-15, default: 0)
    public func stopNote(midiNote: UInt8, channel: UInt8 = 0) {
        sampler.stopNote(midiNote, onChannel: channel)
    }

    /// Stop all currently playing notes.
    public func stopAllNotes() {
        for note: UInt8 in 0...127 {
            sampler.stopNote(note, onChannel: 0)
        }
    }
}

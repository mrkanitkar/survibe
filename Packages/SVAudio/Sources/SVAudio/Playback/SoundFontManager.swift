import AVFoundation

/// Manages SoundFont instrument loading and MIDI note playback
/// via AVAudioUnitSampler connected to AudioEngineManager's engine.
@MainActor
public final class SoundFontManager {
    // MARK: - Properties

    public static let shared = SoundFontManager()

    /// Reference to the engine's sampler node.
    private var sampler: AVAudioUnitSampler {
        AudioEngineManager.shared.sampler
    }

    /// Whether a SoundFont is currently loaded.
    public private(set) var isLoaded: Bool = false

    /// Currently active (playing) MIDI notes, keyed by (note, channel).
    ///
    /// Used by `stopAllNotes()` to iterate only active notes instead of
    /// all 128 MIDI values. Encoded as `UInt16(channel) << 8 | UInt16(note)`.
    private var activeNotes: Set<UInt16> = []

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

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
        activeNotes.insert(Self.noteKey(note: midiNote, channel: channel))
    }

    /// Stop a playing MIDI note.
    /// - Parameters:
    ///   - midiNote: MIDI note number to stop
    ///   - channel: MIDI channel (0-15, default: 0)
    public func stopNote(midiNote: UInt8, channel: UInt8 = 0) {
        sampler.stopNote(midiNote, onChannel: channel)
        activeNotes.remove(Self.noteKey(note: midiNote, channel: channel))
    }

    /// Stop all currently playing notes.
    ///
    /// Iterates only notes that were started via `playNote`, not all 128 MIDI values.
    public func stopAllNotes() {
        for key in activeNotes {
            let (note, channel) = Self.decodeKey(key)
            sampler.stopNote(note, onChannel: channel)
        }
        activeNotes.removeAll()
    }

    // MARK: - Private Methods

    /// Encode a MIDI note and channel into a single UInt16 key.
    private static func noteKey(note: UInt8, channel: UInt8) -> UInt16 {
        UInt16(channel) << 8 | UInt16(note)
    }

    /// Decode a UInt16 key back into MIDI note and channel.
    private static func decodeKey(_ key: UInt16) -> (UInt8, UInt8) {
        let note = UInt8(key & 0xFF)
        let channel = UInt8(key >> 8)
        return (note, channel)
    }
}

import Foundation

/// Swar (note) enum representing the 12 notes in Indian classical music.
/// Each swar maps to a semitone offset from Sa (the tonic).
public enum Swar: String, CaseIterable, Sendable {
    case sa = "Sa"
    case komalRe = "Komal Re"
    case re = "Re"
    case komalGa = "Komal Ga"
    case ga = "Ga"
    case ma = "Ma"
    case tivraMa = "Tivra Ma"
    case pa = "Pa"
    case komalDha = "Komal Dha"
    case dha = "Dha"
    case komalNi = "Komal Ni"
    case ni = "Ni"

    /// Semitone offset from Sa (C4 = MIDI 60 by convention).
    public var midiOffset: Int {
        switch self {
        case .sa: 0
        case .komalRe: 1
        case .re: 2
        case .komalGa: 3
        case .ga: 4
        case .ma: 5
        case .tivraMa: 6
        case .pa: 7
        case .komalDha: 8
        case .dha: 9
        case .komalNi: 10
        case .ni: 11
        }
    }

    /// Calculate the frequency of this swar at a given octave.
    /// Uses equal temperament: f = referencePitch * 2^((midiNote - 69) / 12)
    /// where midiNote = 60 + octaveOffset * 12 + midiOffset.
    public func frequency(octave: Int = 4, referencePitch: Double = 440.0) -> Double {
        let midiNote = 60 + (octave - 4) * 12 + midiOffset
        return referencePitch * pow(2.0, Double(midiNote - 69) / 12.0)
    }

    /// MIDI note number for this swar at a given octave.
    public func midiNote(octave: Int = 4) -> UInt8 {
        UInt8(clamping: 60 + (octave - 4) * 12 + midiOffset)
    }
}

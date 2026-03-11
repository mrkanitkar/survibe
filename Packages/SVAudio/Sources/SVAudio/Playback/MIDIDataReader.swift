import Foundation

/// A simple sequential binary data reader for parsing MIDI files.
///
/// Provides methods to read integers in big-endian format and
/// variable-length quantities as defined by the MIDI specification.
struct MIDIDataReader: Sendable {
    let data: Data
    var position: Int

    /// Read a single byte, advancing the position.
    mutating func readByte() -> UInt8 {
        guard position < data.count else { return 0 }
        let byte = data[position]
        position += 1
        return byte
    }

    /// Read N bytes as an array, advancing the position.
    mutating func readBytes(_ count: Int) -> [UInt8] {
        let end = min(position + count, data.count)
        let bytes = [UInt8](data[position..<end])
        position = end
        return bytes
    }

    /// Read a big-endian UInt16, advancing the position by 2.
    mutating func readUInt16BE() -> UInt16 {
        let high = UInt16(readByte())
        let low = UInt16(readByte())
        return (high << 8) | low
    }

    /// Read a big-endian UInt32, advancing the position by 4.
    mutating func readUInt32BE() -> UInt32 {
        let b0 = UInt32(readByte())
        let b1 = UInt32(readByte())
        let b2 = UInt32(readByte())
        let b3 = UInt32(readByte())
        return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    }

    /// Read a MIDI variable-length quantity.
    ///
    /// Variable-length quantities use 7 bits per byte, with the high bit
    /// indicating continuation (1 = more bytes follow, 0 = last byte).
    mutating func readVariableLength() -> Int {
        var value = 0
        var byte: UInt8
        var bytesRead = 0

        repeat {
            byte = readByte()
            value = (value << 7) | Int(byte & 0x7F)
            bytesRead += 1
            if bytesRead > 4 { break }
        } while (byte & 0x80) != 0

        return value
    }

    /// Skip N bytes, advancing the position.
    mutating func skip(_ count: Int) {
        position = min(position + count, data.count)
    }
}

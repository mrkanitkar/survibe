import Testing
@testable import SVAudio

struct SPSCRingBufferTests {

    // MARK: - Basic Write / Read

    @Test func roundTripExactFit() {
        let buf = SPSCRingBuffer(capacity: 256)
        let samples: [Float] = (0..<256).map { Float($0) }
        samples.withUnsafeBufferPointer { buf.write($0) }

        var dest = [Float](repeating: 0, count: 256)
        let ok = dest.withUnsafeMutableBufferPointer { buf.readLatest(count: 256, into: $0) }

        #expect(ok == true)
        #expect(dest == samples)
    }

    @Test func roundTripPartialRead() {
        let buf = SPSCRingBuffer(capacity: 256)
        let samples: [Float] = (0..<256).map { Float($0) }
        samples.withUnsafeBufferPointer { buf.write($0) }

        // Read only the last 64 samples
        var dest = [Float](repeating: 0, count: 64)
        let ok = dest.withUnsafeMutableBufferPointer { buf.readLatest(count: 64, into: $0) }

        #expect(ok == true)
        // Last 64 of 256 values: indices 192…255
        let expected: [Float] = (192..<256).map { Float($0) }
        #expect(dest == expected)
    }

    @Test func readReturnsFalseWhenInsufficientData() {
        let buf = SPSCRingBuffer(capacity: 256)
        let samples: [Float] = [1.0, 2.0, 3.0]
        samples.withUnsafeBufferPointer { buf.write($0) }

        var dest = [Float](repeating: 0, count: 64)
        let ok = dest.withUnsafeMutableBufferPointer { buf.readLatest(count: 64, into: $0) }

        #expect(ok == false)
    }

    // MARK: - Wrap-around

    @Test func wrapAroundWrite() {
        // Capacity rounds up to 256. Write 200 samples, then 100 more — wraps.
        let buf = SPSCRingBuffer(capacity: 200)  // rounds to 256
        let first: [Float] = (0..<200).map { Float($0) }
        first.withUnsafeBufferPointer { buf.write($0) }

        let second: [Float] = (200..<300).map { Float($0) }
        second.withUnsafeBufferPointer { buf.write($0) }

        // Latest 100 samples should be 200…299
        var dest = [Float](repeating: 0, count: 100)
        let ok = dest.withUnsafeMutableBufferPointer { buf.readLatest(count: 100, into: $0) }
        #expect(ok == true)
        let expected: [Float] = (200..<300).map { Float($0) }
        #expect(dest == expected)
    }

    @Test func wrapAroundMultipleTimes() {
        let buf = SPSCRingBuffer(capacity: 64)
        // Write 4× the capacity to ensure multiple wraps
        for batch in 0..<4 {
            let samples: [Float] = (0..<64).map { Float(batch * 64 + $0) }
            samples.withUnsafeBufferPointer { buf.write($0) }
        }

        // The latest 64 samples should be the last batch: 192…255
        var dest = [Float](repeating: 0, count: 64)
        let ok = dest.withUnsafeMutableBufferPointer { buf.readLatest(count: 64, into: $0) }
        #expect(ok == true)
        let expected: [Float] = (192..<256).map { Float($0) }
        #expect(dest == expected)
    }

    // MARK: - Capacity Rounding

    @Test func capacityRoundsUpToPowerOfTwo() {
        // SPSCRingBuffer rounds up — write capacity+1 samples should not crash
        let buf = SPSCRingBuffer(capacity: 100)  // rounds to 128
        let samples = [Float](repeating: 1.0, count: 128)
        samples.withUnsafeBufferPointer { buf.write($0) }
        #expect(buf.totalSamplesWritten == 128)
    }

    // MARK: - Diagnostics

    @Test func totalSamplesWrittenAccumulates() {
        let buf = SPSCRingBuffer(capacity: 256)
        let batch: [Float] = [1, 2, 3, 4]

        for _ in 0..<10 {
            batch.withUnsafeBufferPointer { buf.write($0) }
        }

        #expect(buf.totalSamplesWritten == 40)
    }

    @Test func emptyBufferReadReturnsFalse() {
        let buf = SPSCRingBuffer(capacity: 256)
        var dest = [Float](repeating: 0, count: 1)
        let ok = dest.withUnsafeMutableBufferPointer { buf.readLatest(count: 1, into: $0) }
        #expect(ok == false)
    }

    // MARK: - Edge Cases

    @Test func zeroCountWriteIsNoOp() {
        let buf = SPSCRingBuffer(capacity: 256)
        let empty: [Float] = []
        empty.withUnsafeBufferPointer { buf.write($0) }
        #expect(buf.totalSamplesWritten == 0)
    }

    @Test func oversizeWriteClampedToCapacity() {
        // Writing more than capacity: only last `capacity` samples are retained
        let buf = SPSCRingBuffer(capacity: 64)
        let large: [Float] = (0..<200).map { Float($0) }
        large.withUnsafeBufferPointer { buf.write($0) }

        // write() clamps to capacity (64), so only 64 samples written
        #expect(buf.totalSamplesWritten == 64)
    }

    // MARK: - Concurrent Producer/Consumer

    @Test func concurrentWriteReadDoesNotCrash() async {
        // Basic TSan-compatible concurrent access test.
        // Producer writes at ~44100 Hz rate simulation; consumer reads periodically.
        let buf = SPSCRingBuffer(capacity: 4096)
        let iterations = 1000

        await withTaskGroup(of: Void.self) { group in
            // Producer
            group.addTask {
                let samples: [Float] = (0..<512).map { Float($0) }
                for _ in 0..<iterations {
                    samples.withUnsafeBufferPointer { buf.write($0) }
                }
            }

            // Consumer
            group.addTask {
                var dest = [Float](repeating: 0, count: 512)
                for _ in 0..<iterations {
                    dest.withUnsafeMutableBufferPointer { buf.readLatest(count: 512, into: $0) }
                }
            }
        }

        // If we reach here without crashing, the test passes.
        #expect(buf.totalSamplesWritten >= 512)
    }
}

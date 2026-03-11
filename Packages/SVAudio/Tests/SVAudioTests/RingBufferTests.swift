import Testing

@testable import SVAudio

struct RingBufferTests {
    // MARK: - Basic Write and Read

    @Test
    func writeAndReadContiguous() {
        let ring = AudioRingBuffer(capacity: 8)
        ring.write([1, 2, 3, 4])
        let result = ring.read(count: 4)
        #expect(result == [1, 2, 3, 4])
    }

    @Test
    func readReturnsNilWhenInsufficientData() {
        let ring = AudioRingBuffer(capacity: 8)
        ring.write([1, 2])
        let result = ring.read(count: 4)
        #expect(result == nil)
    }

    @Test
    func readReturnsNilOnEmptyBuffer() {
        let ring = AudioRingBuffer(capacity: 8)
        let result = ring.read(count: 1)
        #expect(result == nil)
    }

    @Test
    func readExactlyCapacity() {
        let ring = AudioRingBuffer(capacity: 4)
        ring.write([10, 20, 30, 40])
        let result = ring.read(count: 4)
        #expect(result == [10, 20, 30, 40])
    }

    @Test
    func readMoreThanCapacityReturnsNil() {
        let ring = AudioRingBuffer(capacity: 4)
        ring.write([1, 2, 3, 4])
        let result = ring.read(count: 5)
        #expect(result == nil)
    }

    // MARK: - Wrap-Around

    @Test
    func writeWrapsAround() {
        let ring = AudioRingBuffer(capacity: 8)
        // Write 6 samples, then 4 more — second write wraps around
        ring.write([1, 2, 3, 4, 5, 6])
        ring.write([7, 8, 9, 10])
        // Most recent 8 samples should be [3..10]
        let result = ring.read(count: 8)
        #expect(result == [3, 4, 5, 6, 7, 8, 9, 10])
    }

    @Test
    func readWrapsAround() {
        let ring = AudioRingBuffer(capacity: 6)
        // Fill buffer to wrap writeIndex
        ring.write([1, 2, 3, 4])  // writeIndex = 4
        ring.write([5, 6, 7])  // writeIndex = 1 (wraps)
        // Read last 5 — must wrap around the buffer end
        let result = ring.read(count: 5)
        #expect(result == [3, 4, 5, 6, 7])
    }

    @Test
    func multipleSmallWritesThenRead() {
        let ring = AudioRingBuffer(capacity: 8)
        ring.write([1, 2])
        ring.write([3, 4])
        ring.write([5, 6])
        ring.write([7, 8])
        let result = ring.read(count: 8)
        #expect(result == [1, 2, 3, 4, 5, 6, 7, 8])
    }

    // MARK: - Overflow (Write More Than Capacity)

    @Test
    func overflowKeepsLastCapacitySamples() {
        let ring = AudioRingBuffer(capacity: 4)
        // Write 6 samples into capacity-4 buffer
        ring.write([10, 20, 30, 40, 50, 60])
        let result = ring.read(count: 4)
        #expect(result == [30, 40, 50, 60])
    }

    @Test
    func overflowExactlyDoubleCapacity() {
        let ring = AudioRingBuffer(capacity: 4)
        ring.write([1, 2, 3, 4, 5, 6, 7, 8])
        let result = ring.read(count: 4)
        #expect(result == [5, 6, 7, 8])
    }

    @Test
    func overflowAfterPriorWrites() {
        let ring = AudioRingBuffer(capacity: 4)
        ring.write([1, 2])
        ring.write([10, 20, 30, 40, 50])  // overflow
        let result = ring.read(count: 4)
        #expect(result == [20, 30, 40, 50])
    }

    // MARK: - totalSamplesWritten

    @Test
    func totalSamplesWrittenTracksAccumulation() {
        let ring = AudioRingBuffer(capacity: 8)
        #expect(ring.totalSamplesWritten == 0)

        ring.write([1, 2, 3])
        #expect(ring.totalSamplesWritten == 3)

        ring.write([4, 5])
        #expect(ring.totalSamplesWritten == 5)
    }

    @Test
    func totalSamplesWrittenCountsOverflow() {
        let ring = AudioRingBuffer(capacity: 4)
        ring.write([1, 2, 3, 4, 5, 6])
        // All 6 samples counted even though only 4 fit
        #expect(ring.totalSamplesWritten == 6)
    }

    @Test
    func totalSamplesWrittenMonotonicallyIncreases() {
        let ring = AudioRingBuffer(capacity: 4)
        for i in 0..<10 {
            ring.write([Float(i)])
            #expect(ring.totalSamplesWritten == i + 1)
        }
    }

    // MARK: - Reset

    @Test
    func resetClearsAllState() {
        let ring = AudioRingBuffer(capacity: 8)
        ring.write([1, 2, 3, 4, 5])
        ring.reset()

        #expect(ring.totalSamplesWritten == 0)
        #expect(ring.read(count: 1) == nil)
    }

    @Test
    func writeAfterResetWorksCorrectly() {
        let ring = AudioRingBuffer(capacity: 4)
        ring.write([10, 20, 30, 40])
        ring.reset()
        ring.write([1, 2])
        let result = ring.read(count: 2)
        #expect(result == [1, 2])
        #expect(ring.totalSamplesWritten == 2)
    }

    // MARK: - Edge Cases

    @Test
    func capacityClampedToMinimumOne() {
        let ring = AudioRingBuffer(capacity: 0)
        ring.write([42])
        let result = ring.read(count: 1)
        #expect(result == [42])
    }

    @Test
    func emptyWriteIsNoOp() {
        let ring = AudioRingBuffer(capacity: 4)
        ring.write([])
        #expect(ring.totalSamplesWritten == 0)
        #expect(ring.read(count: 1) == nil)
    }

    @Test
    func repeatedReadsReturnSameData() {
        let ring = AudioRingBuffer(capacity: 8)
        ring.write([1, 2, 3, 4])
        let first = ring.read(count: 4)
        let second = ring.read(count: 4)
        #expect(first == second)
    }

    @Test
    func partialReadAfterFull() {
        let ring = AudioRingBuffer(capacity: 8)
        ring.write([1, 2, 3, 4, 5, 6, 7, 8])
        // Read fewer than written
        let result = ring.read(count: 3)
        #expect(result == [6, 7, 8])
    }
}

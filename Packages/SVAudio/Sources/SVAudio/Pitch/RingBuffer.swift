import Foundation

/// Single-producer, single-consumer ring buffer for accumulating audio samples.
///
/// The audio thread writes 1024 samples per callback. The DSP queue reads
/// 2048/4096/8192 samples with overlap for FFT analysis.
///
/// Thread safety: NSLock-based, matching the project's AtomicFlag/AtomicCounter pattern.
/// Lock hold time is minimal (~4KB memcpy for writes, pointer arithmetic for reads).
///
/// @unchecked Sendable rationale: All mutable state (`buffer`, `writeIndex`, `totalWritten`)
/// is protected by NSLock. @MainActor isolation is impossible — written from audio render
/// thread, read from DSP queue. Lock hold time is sub-microsecond.
public final class AudioRingBuffer: @unchecked Sendable {
    // MARK: - Properties

    private var buffer: [Float]
    private var writeIndex: Int = 0
    private var totalWritten: Int = 0
    private let capacity: Int
    private let lock = NSLock()

    // MARK: - Initialization

    /// Create a ring buffer with the specified capacity.
    ///
    /// - Parameter capacity: Maximum number of Float samples the buffer holds.
    ///   Recommended: 2× the largest read size to ensure reads never overlap with writes.
    public init(capacity: Int) {
        self.capacity = max(capacity, 1)
        self.buffer = [Float](repeating: 0, count: self.capacity)
    }

    // MARK: - Public Methods

    /// Write samples into the ring buffer.
    ///
    /// Called from the audio render thread. The write is a fast memcpy
    /// protected by an NSLock with sub-microsecond hold time.
    ///
    /// - Parameter samples: Audio samples to append. Typically 1024 frames per tap callback.
    public func write(_ samples: [Float]) {
        lock.lock()
        defer { lock.unlock() }

        let count = samples.count
        if count >= capacity {
            // If writing more than capacity, keep only the last `capacity` samples
            let start = count - capacity
            buffer = Array(samples[start...])
            writeIndex = 0
            totalWritten += count
            return
        }

        let spaceToEnd = capacity - writeIndex
        if count <= spaceToEnd {
            // Contiguous write
            buffer.replaceSubrange(writeIndex..<(writeIndex + count), with: samples)
        } else {
            // Wrap around
            buffer.replaceSubrange(writeIndex..<capacity, with: samples[0..<spaceToEnd])
            let remaining = count - spaceToEnd
            buffer.replaceSubrange(0..<remaining, with: samples[spaceToEnd..<count])
        }
        writeIndex = (writeIndex + count) % capacity
        totalWritten += count
    }

    /// Read the most recent `count` samples for FFT analysis.
    ///
    /// Called from the DSP queue. Returns nil if not enough samples
    /// have been accumulated yet.
    ///
    /// - Parameter count: Number of samples to read. Must be ≤ capacity.
    /// - Returns: Array of the most recent `count` samples, or nil if insufficient data.
    public func read(count: Int) -> [Float]? {
        lock.lock()
        defer { lock.unlock() }

        guard count <= capacity, totalWritten >= count else { return nil }

        var result = [Float](repeating: 0, count: count)
        let readStart = (writeIndex - count + capacity) % capacity
        let spaceToEnd = capacity - readStart

        if count <= spaceToEnd {
            // Contiguous read
            result.replaceSubrange(0..<count, with: buffer[readStart..<(readStart + count)])
        } else {
            // Wrap around
            result.replaceSubrange(0..<spaceToEnd, with: buffer[readStart..<capacity])
            let remaining = count - spaceToEnd
            result.replaceSubrange(spaceToEnd..<count, with: buffer[0..<remaining])
        }

        return result
    }

    /// Total number of samples written since creation or last reset.
    ///
    /// Monotonically increasing. Used to determine when a new hop's worth
    /// of data has arrived (check if totalSamplesWritten increased by ≥ hopSize).
    public var totalSamplesWritten: Int {
        lock.lock()
        defer { lock.unlock() }
        return totalWritten
    }

    /// Reset the buffer state.
    ///
    /// Called when stopping detection or changing latency preset.
    /// Zeros the buffer and resets write index and total count.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        buffer = [Float](repeating: 0, count: capacity)
        writeIndex = 0
        totalWritten = 0
    }
}

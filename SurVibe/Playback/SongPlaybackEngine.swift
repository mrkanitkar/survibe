import Foundation
import SVAudio
import SVCore
import os.log

/// Drives song playback by scheduling MIDI notes through SoundFontManager
/// and tracking position for notation highlighting.
///
/// SongPlaybackEngine loads MIDI data from a Song model, parses it into
/// timed note events, and schedules playback using Task-based delays.
/// A 30 Hz Timer updates the current position and note index for UI
/// consumers (e.g., notation scroll views, progress bars).
///
/// ## Lifecycle
/// ```
/// load(song:) → play() → pause()/resume() → stop()
/// ```
///
/// ## Note Scheduling Strategy
/// Rather than using audio-thread scheduling, the engine creates
/// individual Swift Tasks that sleep until each note's scheduled time.
/// This trades sub-millisecond accuracy for simplicity and full
/// integration with Swift concurrency. For piano learning purposes,
/// the resulting timing accuracy (~10ms) is more than sufficient.
///
/// ## Thread Safety
/// All mutable state is isolated to `@MainActor`. The only off-main
/// work is the `Task.sleep` inside note-scheduling tasks, which
/// re-enters MainActor for SoundFontManager calls.
@Observable
@MainActor
final class SongPlaybackEngine {
    // MARK: - Public Properties

    /// Current playback state.
    private(set) var playbackState: PlaybackState = .idle

    /// Current playback position in seconds from song start.
    private(set) var currentPosition: TimeInterval = 0

    /// Index of the MIDI event currently being played (note whose
    /// `timestamp <= currentPosition < timestamp + duration`).
    /// `nil` when no note is active at the current position.
    private(set) var currentNoteIndex: Int?

    /// Index of the next MIDI event to be played after the current position.
    /// `nil` when there are no remaining events.
    private(set) var nextNoteIndex: Int?

    /// Total duration of the loaded song in seconds.
    private(set) var duration: TimeInterval = 0

    /// Parsed MIDI events for the loaded song, sorted by timestamp.
    private(set) var midiEvents: [MIDIEvent] = []

    /// Title of the currently loaded song (used for analytics).
    private(set) var songTitle: String = ""

    /// Whether the loaded song has MIDI events available for audio playback.
    /// Returns `false` for notation-only songs that lack binary MIDI data.
    var hasPlayableContent: Bool {
        !midiEvents.isEmpty
    }

    // MARK: - Private Properties

    /// Wall-clock reference for computing elapsed playback time.
    /// Adjusted on resume to account for time spent paused.
    private var playbackStartTime: Date?

    /// Accumulated playback time before the most recent pause.
    /// Used to offset `playbackStartTime` on resume so the position
    /// continues seamlessly.
    private var pauseOffset: TimeInterval = 0

    /// Timer that fires at ~30 Hz to update `currentPosition`,
    /// `currentNoteIndex`, and `nextNoteIndex` for UI consumers.
    private var displayLinkTimer: Timer?

    /// Tasks responsible for scheduling individual MIDI note playback.
    /// Cancelled on pause/stop to silence pending notes.
    private var scheduledNoteTasks: [Task<Void, Never>] = []

    private static let logger = Logger(
        subsystem: "com.survibe",
        category: "SongPlayback"
    )

    // MARK: - Initialization

    init() {}

    // Note: Cleanup is handled by stop() called from SongDetailView.onDisappear.
    // deinit cannot access @MainActor-isolated properties under strict concurrency.

    // MARK: - Public Methods

    /// Load a song's MIDI data and prepare for playback.
    ///
    /// Parses the song's binary MIDI data via `MIDIParser`, populates
    /// `midiEvents` and `duration`, and transitions to `.idle` on success
    /// or `.error` on failure.
    ///
    /// - Parameter song: The Song model whose `midiData` will be parsed.
    ///   If `midiData` is nil or empty, stays in `.idle` (notation-only mode).
    func load(song: Song) async {
        playbackState = .loading
        songTitle = song.title

        Self.logger.info("Loading song: \(song.title)")

        // Songs may not have MIDI binary data (seed songs use sargam/western
        // notation arrays instead). Treat nil/empty MIDI as "no playback
        // available" — stay idle so the notation is still viewable.
        guard let midiData = song.midiData, !midiData.isEmpty else {
            midiEvents = []
            duration = TimeInterval(song.durationSeconds)
            currentPosition = 0
            currentNoteIndex = nil
            nextNoteIndex = nil
            pauseOffset = 0
            playbackState = .idle

            Self.logger.info(
                "Song '\(song.title)' has no MIDI data — notation-only mode"
            )
            return
        }

        let result = MIDIParser.parse(data: midiData)

        switch result {
        case .success(let events):
            midiEvents = events
            if let lastEvent = events.last {
                duration = lastEvent.timestamp + lastEvent.duration
            } else {
                duration = 0
            }
            currentPosition = 0
            currentNoteIndex = nil
            nextNoteIndex = events.isEmpty ? nil : 0
            pauseOffset = 0

            // Start the audio engine and load the bundled piano SoundFont
            // so that playNote() calls actually produce sound.
            do {
                try SoundFontManager.shared.loadBundledPiano()
            } catch {
                Self.logger.error(
                    "SoundFont load failed: \(error.localizedDescription)"
                )
            }

            playbackState = .idle

            Self.logger.info(
                "Song loaded: \(events.count) events, duration=\(String(format: "%.1f", self.duration))s"
            )

        case .failure(let error):
            midiEvents = []
            duration = 0
            playbackState = .error(
                error.errorDescription ?? "Unknown MIDI parse error"
            )

            Self.logger.error(
                "Failed to load song '\(song.title)': \(error.localizedDescription)"
            )
        }
    }

    /// Begin playback from the current position.
    ///
    /// Transitions from `.idle` or `.stopped` to `.playing`.
    /// Records a wall-clock start time, starts the 30 Hz display timer,
    /// and schedules all MIDI notes from the current offset.
    ///
    /// Fires `songPlaybackStarted` analytics event.
    func play() {
        guard playbackState == .idle || playbackState == .stopped else {
            Self.logger.warning(
                "play() called in invalid state: \(String(describing: self.playbackState))"
            )
            return
        }
        guard !midiEvents.isEmpty else {
            Self.logger.warning("play() called with no MIDI events loaded")
            return
        }

        pauseOffset = 0
        playbackStartTime = Date()
        playbackState = .playing

        startDisplayLink()
        scheduleNotes(from: 0)

        AnalyticsManager.shared.track(
            .songPlaybackStarted,
            properties: ["song_title": songTitle]
        )

        Self.logger.info("Playback started: \(self.songTitle)")
    }

    /// Pause playback at the current position.
    ///
    /// Records the elapsed time in `pauseOffset`, cancels all pending
    /// note tasks, and stops all sounding notes. The position is preserved
    /// so `resume()` can continue from where playback left off.
    ///
    /// Fires `songPlaybackPaused` analytics event.
    func pause() {
        guard playbackState == .playing else {
            Self.logger.warning(
                "pause() called in invalid state: \(String(describing: self.playbackState))"
            )
            return
        }

        if let startTime = playbackStartTime {
            pauseOffset = Date().timeIntervalSince(startTime)
        }

        playbackState = .paused

        stopDisplayLink()
        cancelScheduledNotes()
        SoundFontManager.shared.stopAllNotes()

        AnalyticsManager.shared.track(
            .songPlaybackPaused,
            properties: ["song_title": songTitle]
        )

        Self.logger.info(
            "Playback paused at \(String(format: "%.1f", self.pauseOffset))s"
        )
    }

    /// Resume playback from the paused position.
    ///
    /// Adjusts the wall-clock start time to account for the pause duration,
    /// restarts the display timer, and reschedules remaining MIDI notes.
    func resume() {
        guard playbackState == .paused else {
            Self.logger.warning(
                "resume() called in invalid state: \(String(describing: self.playbackState))"
            )
            return
        }

        playbackStartTime = Date().addingTimeInterval(-pauseOffset)
        playbackState = .playing

        startDisplayLink()
        scheduleNotes(from: pauseOffset)

        Self.logger.info(
            "Playback resumed from \(String(format: "%.1f", self.pauseOffset))s"
        )
    }

    /// Stop playback and reset position to the beginning.
    ///
    /// Cancels all pending note tasks, stops all sounding notes,
    /// and resets the position to zero.
    func stop() {
        guard playbackState == .playing || playbackState == .paused else {
            Self.logger.warning(
                "stop() called in invalid state: \(String(describing: self.playbackState))"
            )
            return
        }

        stopDisplayLink()
        cancelScheduledNotes()
        SoundFontManager.shared.stopAllNotes()

        currentPosition = 0
        currentNoteIndex = nil
        nextNoteIndex = midiEvents.isEmpty ? nil : 0
        pauseOffset = 0
        playbackStartTime = nil
        playbackState = .stopped

        Self.logger.info("Playback stopped")
    }

    // MARK: - Private Methods — Display Link

    /// Start a 30 Hz repeating timer to update playback position and note indices.
    private func startDisplayLink() {
        stopDisplayLink()
        displayLinkTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePlaybackPosition()
            }
        }
    }

    /// Invalidate and release the display timer.
    private func stopDisplayLink() {
        displayLinkTimer?.invalidate()
        displayLinkTimer = nil
    }

    /// Compute the current playback position from wall-clock elapsed time,
    /// update `currentNoteIndex` and `nextNoteIndex` for UI highlighting,
    /// and detect playback completion.
    private func updatePlaybackPosition() {
        guard playbackState == .playing,
            let startTime = playbackStartTime
        else {
            return
        }

        let elapsed = Date().timeIntervalSince(startTime)
        currentPosition = min(elapsed, duration)

        // Find the current note: last event where timestamp <= position
        // AND position < timestamp + duration (note is still sounding).
        var foundCurrent: Int?
        var foundNext: Int?

        for (index, event) in midiEvents.enumerated() {
            if event.timestamp <= currentPosition,
                currentPosition < event.timestamp + event.duration
            {
                foundCurrent = index
            }
            if event.timestamp > currentPosition, foundNext == nil {
                foundNext = index
            }
        }

        currentNoteIndex = foundCurrent
        nextNoteIndex = foundNext

        // Detect playback completion.
        if elapsed >= duration {
            handlePlaybackCompletion()
        }
    }

    /// Handle natural end-of-song: fire analytics, clean up, transition to idle.
    private func handlePlaybackCompletion() {
        stopDisplayLink()
        cancelScheduledNotes()
        SoundFontManager.shared.stopAllNotes()

        currentPosition = duration
        currentNoteIndex = nil
        nextNoteIndex = nil
        pauseOffset = 0
        playbackStartTime = nil
        playbackState = .idle

        AnalyticsManager.shared.track(
            .songPlaybackCompleted,
            properties: [
                "song_title": songTitle,
                "duration_seconds": Int(duration),
            ]
        )

        Self.logger.info(
            "Playback completed: \(self.songTitle) (\(Int(self.duration))s)"
        )
    }

    // MARK: - Private Methods — Note Scheduling

    /// Schedule MIDI note playback from the given time offset.
    ///
    /// Creates one Swift Task per MIDI event that sleeps until the event's
    /// scheduled time, then triggers `playMIDINote(_:)`. Events with
    /// timestamps before `offset` are skipped (already played).
    ///
    /// - Parameter offset: Time offset in seconds. Events before this
    ///   point are not scheduled.
    private func scheduleNotes(from offset: TimeInterval) {
        cancelScheduledNotes()

        for event in midiEvents {
            guard event.timestamp >= offset else { continue }
            let delay = event.timestamp - offset
            let task = Task { [weak self] in
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                self?.playMIDINote(event)
            }
            scheduledNoteTasks.append(task)
        }
    }

    /// Play a single MIDI note through SoundFontManager, then schedule
    /// note-off after the event's duration.
    ///
    /// - Parameter event: The MIDI event to play.
    private func playMIDINote(_ event: MIDIEvent) {
        guard playbackState == .playing else { return }
        SoundFontManager.shared.playNote(
            midiNote: event.noteNumber,
            velocity: event.velocity
        )

        // Schedule note-off after the note's duration.
        let noteOffTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(event.duration))
            guard !Task.isCancelled else { return }
            guard self != nil else { return }
            SoundFontManager.shared.stopNote(midiNote: event.noteNumber)
        }
        scheduledNoteTasks.append(noteOffTask)
    }

    /// Cancel all pending note-scheduling tasks.
    private func cancelScheduledNotes() {
        for task in scheduledNoteTasks {
            task.cancel()
        }
        scheduledNoteTasks.removeAll()
    }
}

import Testing
import Foundation
import SVAudio
import SVLearning

@testable import SurVibe

// MARK: - PlayAlongWaitController Tests

/// Tests for PlayAlongWaitController — the wait-mode adapter for play-along.
///
/// Critical regression tests verify that Komal/Tivra note variants are
/// compared using their full swar names (e.g., "Komal Re"), preventing
/// false matches between base notes and their modified forms.
@MainActor
struct PlayAlongWaitControllerTests {

    // MARK: - Helpers

    /// Create a controller with a standard Sa-Re-Ga-Ma sequence.
    private func makeBasicController() -> PlayAlongWaitController {
        let events = NoteEventFactory.sequence(
            swarNames: ["Sa", "Re", "Ga", "Ma"]
        )
        return PlayAlongWaitController(noteEvents: events)
    }

    /// Create a controller with Komal and Tivra notes for regression tests.
    private func makeKomalTivraController() -> PlayAlongWaitController {
        let events = NoteEventFactory.sequence(
            swarNames: ["Sa", "Komal Re", "Tivra Ma", "Pa", "Komal Dha", "Komal Ni"]
        )
        return PlayAlongWaitController(noteEvents: events)
    }

    // MARK: - setCurrentNoteIndex Tests

    @Test("setCurrentNoteIndex sets isWaitingForNote to true")
    func setCurrentNoteIndexSetsWaiting() {
        let controller = makeBasicController()

        controller.setCurrentNoteIndex(0)

        #expect(controller.isWaitingForNote == true)
        #expect(controller.currentNoteIndex == 0)
    }

    @Test("setCurrentNoteIndex updates the index")
    func setCurrentNoteIndexUpdatesIndex() {
        let controller = makeBasicController()

        controller.setCurrentNoteIndex(2)

        #expect(controller.currentNoteIndex == 2)
        #expect(controller.isWaitingForNote == true)
    }

    // MARK: - evaluateAttempt Basic Tests

    @Test("evaluateAttempt with correct note returns true and clears waiting")
    func evaluateAttemptCorrectNoteReturnsTrue() {
        let controller = makeBasicController()
        controller.setCurrentNoteIndex(0) // Expecting "Sa"

        let result = controller.evaluateAttempt(detectedNoteName: "Sa")

        #expect(result == true)
        #expect(controller.isWaitingForNote == false)
    }

    @Test("evaluateAttempt with wrong note returns false and keeps waiting")
    func evaluateAttemptWrongNoteReturnsFalse() {
        let controller = makeBasicController()
        controller.setCurrentNoteIndex(0) // Expecting "Sa"

        let result = controller.evaluateAttempt(detectedNoteName: "Re")

        #expect(result == false)
        #expect(controller.isWaitingForNote == true)
    }

    @Test("evaluateAttempt with out-of-bounds index returns false")
    func evaluateAttemptOutOfBoundsReturnsFalse() {
        let controller = makeBasicController()
        controller.setCurrentNoteIndex(99) // Beyond note count

        let result = controller.evaluateAttempt(detectedNoteName: "Sa")

        #expect(result == false)
    }

    // MARK: - Komal/Tivra Regression Tests (CRITICAL)

    @Test("evaluateAttempt with correct full Komal Re name returns true")
    func evaluateAttemptKomalReCorrectFullName() {
        let controller = makeKomalTivraController()
        controller.setCurrentNoteIndex(1) // Expecting "Komal Re"

        let result = controller.evaluateAttempt(detectedNoteName: "Komal Re")

        #expect(result == true)
        #expect(controller.isWaitingForNote == false)
    }

    @Test("evaluateAttempt with base Re when expecting Komal Re returns false")
    func evaluateAttemptBaseReWhenExpectingKomalReReturnsFalse() {
        let controller = makeKomalTivraController()
        controller.setCurrentNoteIndex(1) // Expecting "Komal Re"

        let result = controller.evaluateAttempt(detectedNoteName: "Re")

        #expect(result == false)
        #expect(controller.isWaitingForNote == true)
    }

    @Test("evaluateAttempt with correct full Tivra Ma name returns true")
    func evaluateAttemptTivraMaCorrectFullName() {
        let controller = makeKomalTivraController()
        controller.setCurrentNoteIndex(2) // Expecting "Tivra Ma"

        let result = controller.evaluateAttempt(detectedNoteName: "Tivra Ma")

        #expect(result == true)
        #expect(controller.isWaitingForNote == false)
    }

    @Test("evaluateAttempt with base Ma when expecting Tivra Ma returns false")
    func evaluateAttemptBaseMaWhenExpectingTivraMaReturnsFalse() {
        let controller = makeKomalTivraController()
        controller.setCurrentNoteIndex(2) // Expecting "Tivra Ma"

        let result = controller.evaluateAttempt(detectedNoteName: "Ma")

        #expect(result == false)
        #expect(controller.isWaitingForNote == true)
    }

    @Test("evaluateAttempt with correct Komal Dha returns true")
    func evaluateAttemptKomalDhaCorrect() {
        let controller = makeKomalTivraController()
        controller.setCurrentNoteIndex(4) // Expecting "Komal Dha"

        let result = controller.evaluateAttempt(detectedNoteName: "Komal Dha")

        #expect(result == true)
    }

    @Test("evaluateAttempt with base Dha when expecting Komal Dha returns false")
    func evaluateAttemptBaseDhaWhenExpectingKomalDhaReturnsFalse() {
        let controller = makeKomalTivraController()
        controller.setCurrentNoteIndex(4) // Expecting "Komal Dha"

        let result = controller.evaluateAttempt(detectedNoteName: "Dha")

        #expect(result == false)
    }

    @Test("evaluateAttempt with correct Komal Ni returns true")
    func evaluateAttemptKomalNiCorrect() {
        let controller = makeKomalTivraController()
        controller.setCurrentNoteIndex(5) // Expecting "Komal Ni"

        let result = controller.evaluateAttempt(detectedNoteName: "Komal Ni")

        #expect(result == true)
    }

    @Test("evaluateAttempt with base Ni when expecting Komal Ni returns false")
    func evaluateAttemptBaseNiWhenExpectingKomalNiReturnsFalse() {
        let controller = makeKomalTivraController()
        controller.setCurrentNoteIndex(5) // Expecting "Komal Ni"

        let result = controller.evaluateAttempt(detectedNoteName: "Ni")

        #expect(result == false)
    }

    // MARK: - reset Tests

    @Test("reset clears index and waiting state")
    func resetClearsState() {
        let controller = makeBasicController()
        controller.setCurrentNoteIndex(2)
        _ = controller.evaluateAttempt(detectedNoteName: "Ga")

        controller.reset()

        #expect(controller.currentNoteIndex == 0)
        #expect(controller.isWaitingForNote == false)
    }

    @Test("reset allows starting a new session")
    func resetAllowsNewSession() {
        let controller = makeBasicController()
        controller.setCurrentNoteIndex(3)
        controller.reset()

        controller.setCurrentNoteIndex(0)
        let result = controller.evaluateAttempt(detectedNoteName: "Sa")

        #expect(result == true)
        #expect(controller.isWaitingForNote == false)
    }
}

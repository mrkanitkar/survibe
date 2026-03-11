import Foundation
import Testing

@testable import SVLearning

@Suite("RiyazStreak Tests")
struct RiyazStreakTests {
    @Test("Default streak is zero")
    func defaultStreakIsZero() {
        let streak = RiyazStreak()
        #expect(streak.currentStreak == 0)
        #expect(streak.longestStreak == 0)
        #expect(streak.lastPracticeDate == nil)
    }

    @Test("recordPractice increments current streak")
    func recordPracticeIncrements() {
        var streak = RiyazStreak()
        streak.recordPractice()
        #expect(streak.currentStreak == 1)
    }

    @Test("recordPractice updates longestStreak via max-wins")
    func longestStreakTracksMaximum() {
        var streak = RiyazStreak(currentStreak: 5, longestStreak: 10)
        streak.recordPractice()
        // currentStreak becomes 6, but longestStreak stays 10 (max-wins)
        #expect(streak.currentStreak == 6)
        #expect(streak.longestStreak == 10)
    }

    @Test("longestStreak updates when current exceeds it")
    func longestStreakUpdatesWhenExceeded() {
        var streak = RiyazStreak(currentStreak: 9, longestStreak: 9)
        streak.recordPractice()
        #expect(streak.currentStreak == 10)
        #expect(streak.longestStreak == 10)
    }

    @Test("recordPractice sets lastPracticeDate")
    func recordPracticeSetsDate() {
        var streak = RiyazStreak()
        let date = Date(timeIntervalSince1970: 1_000_000)
        streak.recordPractice(on: date)
        #expect(streak.lastPracticeDate == date)
    }

    @Test("Multiple practices accumulate")
    func multiplePracticesAccumulate() {
        var streak = RiyazStreak()
        for _ in 0..<5 {
            streak.recordPractice()
        }
        #expect(streak.currentStreak == 5)
        #expect(streak.longestStreak == 5)
    }

    @Test("Custom initial values preserved")
    func customInitialValues() {
        let date = Date()
        let streak = RiyazStreak(currentStreak: 3, longestStreak: 7, lastPracticeDate: date)
        #expect(streak.currentStreak == 3)
        #expect(streak.longestStreak == 7)
        #expect(streak.lastPracticeDate == date)
    }

    @Test("RiyazStreak is Sendable")
    func isSendable() {
        func requireSendable<T: Sendable>(_: T) {}
        requireSendable(RiyazStreak())
    }
}

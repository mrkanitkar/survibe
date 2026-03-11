import Foundation
import Testing

@testable import SVCore

@Suite("Model Protocol Sendable Conformance Tests")
struct ModelProtocolSendableTests {
    // These tests verify at compile-time that model protocols conform to Sendable
    // by using them as generic constraints requiring Sendable.

    /// Compile-time verification helper: accepts any Sendable type.
    nonisolated private static func requireSendable<T: Sendable>(_ type: T.Type) {
        // Intentionally empty — the constraint is the test
    }

    @Test("UserProfileProtocol conforms to Sendable")
    func userProfileIsSendable() {
        Self.requireSendable((any UserProfileProtocol).self)
    }

    @Test("RiyazEntryProtocol conforms to Sendable")
    func riyazEntryIsSendable() {
        Self.requireSendable((any RiyazEntryProtocol).self)
    }

    @Test("AchievementProtocol conforms to Sendable")
    func achievementIsSendable() {
        Self.requireSendable((any AchievementProtocol).self)
    }

    @Test("SongProgressProtocol conforms to Sendable")
    func songProgressIsSendable() {
        Self.requireSendable((any SongProgressProtocol).self)
    }

    @Test("LessonProgressProtocol conforms to Sendable")
    func lessonProgressIsSendable() {
        Self.requireSendable((any LessonProgressProtocol).self)
    }

    @Test("SubscriptionStateProtocol conforms to Sendable")
    func subscriptionStateIsSendable() {
        Self.requireSendable((any SubscriptionStateProtocol).self)
    }
}

import Foundation
import SwiftData

/// Daily practice (riyaz) session entry.
/// Additive-only: one new entry per day, never overwrite previous entries.
@Model
final class RiyazEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var durationMinutes: Int = 0
    var notesPlayed: Int = 0
    var accuracyPercent: Double = 0.0
    var xpEarned: Int = 0
    var raagPracticed: String = ""

    init(
        date: Date = Date(),
        durationMinutes: Int = 0,
        notesPlayed: Int = 0,
        accuracyPercent: Double = 0.0,
        xpEarned: Int = 0,
        raagPracticed: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.durationMinutes = durationMinutes
        self.notesPlayed = notesPlayed
        self.accuracyPercent = accuracyPercent
        self.xpEarned = xpEarned
        self.raagPracticed = raagPracticed
    }
}

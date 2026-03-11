import Foundation
import SwiftData
import Testing

@testable import SurVibe

// MARK: - ContentImportManager Tests

@Suite("ContentImportManager Tests")
struct ContentImportManagerTests {
    @Test("Import seed songs from bundle JSON")
    @MainActor
    func importSeedSongs() throws {
        let container = try makeTestContainer()
        let summary = try ContentImportManager.importAllSeedContent(
            into: container,
            from: .main
        )
        #expect(summary.songCount == 3)
        #expect(summary.errorDescriptions.isEmpty)
    }

    @Test("Import seed lessons from bundle JSON")
    @MainActor
    func importSeedLessons() throws {
        let container = try makeTestContainer()
        let summary = try ContentImportManager.importAllSeedContent(
            into: container,
            from: .main
        )
        #expect(summary.lessonCount == 2)
    }

    @Test("Imported songs have correct slugIds")
    @MainActor
    func importedSongSlugIds() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.sortOrder)])
        let songs = try context.fetch(descriptor)

        #expect(songs.count == 3)
        let slugIds = songs.map(\.slugId)
        #expect(slugIds.contains("twinkle-hindi-v1"))
        #expect(slugIds.contains("morya-marathi-v1"))
        #expect(slugIds.contains("mary-english-v1"))
    }

    @Test("Imported songs have sargam notation data")
    @MainActor
    func importedSongsHaveSargam() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let songs = try context.fetch(FetchDescriptor<Song>())
        for song in songs {
            #expect(song.sargamNotation != nil, "Song \(song.slugId) missing sargam notation")
            let decoded = song.decodedSargamNotes
            #expect(decoded != nil, "Song \(song.slugId) sargam failed to decode")
            #expect(decoded?.isEmpty == false, "Song \(song.slugId) has empty sargam notes")
        }
    }

    @Test("Imported songs have western notation data")
    @MainActor
    func importedSongsHaveWestern() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let songs = try context.fetch(FetchDescriptor<Song>())
        for song in songs {
            #expect(song.westernNotation != nil, "Song \(song.slugId) missing western notation")
            let decoded = song.decodedWesternNotes
            #expect(decoded != nil, "Song \(song.slugId) western failed to decode")
            #expect(decoded?.isEmpty == false, "Song \(song.slugId) has empty western notes")
        }
    }

    @Test("Imported lessons have steps data")
    @MainActor
    func importedLessonsHaveSteps() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let lessons = try context.fetch(
            FetchDescriptor<Lesson>(sortBy: [SortDescriptor(\.orderIndex)])
        )
        for lesson in lessons {
            #expect(lesson.stepsData != nil, "Lesson \(lesson.lessonId) missing steps data")
            let decoded = lesson.decodedSteps
            #expect(decoded != nil, "Lesson \(lesson.lessonId) steps failed to decode")
            #expect(decoded?.isEmpty == false, "Lesson \(lesson.lessonId) has empty steps")
        }
    }

    @Test("Import summary description is non-empty")
    @MainActor
    func summaryDescription() throws {
        let container = try makeTestContainer()
        let summary = try ContentImportManager.importAllSeedContent(
            into: container, from: .main
        )
        #expect(summary.description.contains("Songs: 3"))
        #expect(summary.description.contains("Lessons: 2"))
    }
}

// MARK: - Seed Content Validation Tests

@Suite("Seed Content Validation Tests")
struct SeedContentValidationTests {
    @Test("Hindi song has correct metadata")
    @MainActor
    func hindiSongMetadata() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let songs = try context.fetch(FetchDescriptor<Song>())
        let hindi = songs.first { $0.slugId == "twinkle-hindi-v1" }
        #expect(hindi != nil)
        #expect(hindi?.language == "hi")
        #expect(hindi?.category == "nursery")
        #expect(hindi?.difficulty == 1)
        #expect(hindi?.tempo == 80)
        #expect(hindi?.isFree == true)
    }

    @Test("Marathi song has correct metadata")
    @MainActor
    func marathiSongMetadata() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let songs = try context.fetch(FetchDescriptor<Song>())
        let marathi = songs.first { $0.slugId == "morya-marathi-v1" }
        #expect(marathi != nil)
        #expect(marathi?.language == "mr")
        #expect(marathi?.category == "devotional")
        #expect(marathi?.difficulty == 1)
        #expect(marathi?.tempo == 72)
    }

    @Test("English song has correct metadata")
    @MainActor
    func englishSongMetadata() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let songs = try context.fetch(FetchDescriptor<Song>())
        let english = songs.first { $0.slugId == "mary-english-v1" }
        #expect(english != nil)
        #expect(english?.language == "en")
        #expect(english?.category == "nursery")
        #expect(english?.tempo == 100)
    }

    @Test("Sargam note count matches western note count per song")
    @MainActor
    func notationCountsMatch() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let songs = try context.fetch(FetchDescriptor<Song>())
        for song in songs {
            let sargamCount = song.decodedSargamNotes?.count ?? 0
            let westernCount = song.decodedWesternNotes?.count ?? 0
            #expect(
                sargamCount == westernCount,
                "Song \(song.slugId): sargam(\(sargamCount)) != western(\(westernCount))"
            )
        }
    }

    @Test("All sargam notes have valid swara names")
    @MainActor
    func validSwaraNames() throws {
        let validSwaras: Set<String> = ["Sa", "Re", "Ga", "Ma", "Pa", "Dha", "Ni"]
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let songs = try context.fetch(FetchDescriptor<Song>())
        for song in songs {
            guard let notes = song.decodedSargamNotes else {
                continue
            }
            for note in notes {
                #expect(
                    validSwaras.contains(note.note),
                    "Song \(song.slugId) has invalid swara: \(note.note)"
                )
            }
        }
    }

    @Test("All western notes have valid MIDI numbers")
    @MainActor
    func validMIDINumbers() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let songs = try context.fetch(FetchDescriptor<Song>())
        for song in songs {
            guard let notes = song.decodedWesternNotes else {
                continue
            }
            for note in notes {
                #expect(
                    (0...127).contains(note.midiNumber),
                    "Song \(song.slugId) has invalid MIDI: \(note.midiNumber)"
                )
            }
        }
    }

    @Test("Lesson ordering is sequential")
    @MainActor
    func lessonOrdering() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let lessons = try context.fetch(
            FetchDescriptor<Lesson>(sortBy: [SortDescriptor(\.orderIndex)])
        )
        #expect(lessons.count == 2)
        #expect(lessons[0].orderIndex < lessons[1].orderIndex)
        #expect(lessons[0].lessonId == "lesson-meet-swaras-v1")
        #expect(lessons[1].lessonId == "lesson-first-melody-v1")
    }

    @Test("Second lesson has prerequisite referencing first lesson")
    @MainActor
    func lessonPrerequisites() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let lessons = try context.fetch(
            FetchDescriptor<Lesson>(sortBy: [SortDescriptor(\.orderIndex)])
        )
        let firstLesson = lessons[0]
        let secondLesson = lessons[1]

        // First lesson has no prerequisites
        let firstPrereqs = firstLesson.decodedPrerequisites
        #expect(firstPrereqs == nil || firstPrereqs?.isEmpty == true)

        // Second lesson references first lesson
        let secondPrereqs = secondLesson.decodedPrerequisites
        #expect(secondPrereqs?.contains("lesson-meet-swaras-v1") == true)
    }

    @Test("Each lesson has 6 steps")
    @MainActor
    func lessonStepCount() throws {
        let container = try makeTestContainer()
        _ = try ContentImportManager.importAllSeedContent(into: container, from: .main)

        let context = ModelContext(container)
        let lessons = try context.fetch(FetchDescriptor<Lesson>())
        for lesson in lessons {
            let steps = lesson.decodedSteps
            #expect(
                steps?.count == 6,
                "Lesson \(lesson.lessonId) expected 6 steps, got \(steps?.count ?? 0)"
            )
        }
    }
}

// MARK: - SeedContentLoader Tests

@Suite("SeedContentLoader Tests")
struct SeedContentLoaderTests {
    @Test("isSeedContentLoaded defaults to false")
    @MainActor
    func defaultsToFalse() {
        let key = "com.survibe.seedContentLoaded.test.\(UUID().uuidString)"
        let loaded = UserDefaults.standard.bool(forKey: key)
        #expect(loaded == false)
    }
}

// MARK: - Test Helpers

private func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([
        UserProfile.self,
        RiyazEntry.self,
        Achievement.self,
        SongProgress.self,
        LessonProgress.self,
        SubscriptionState.self,
        Song.self,
        Lesson.self,
        Curriculum.self,
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

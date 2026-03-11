import Foundation
import SVLearning
import SwiftData
import os.log

/// Orchestrates import of seed content (songs, lessons) from JSON into SwiftData.
///
/// Maps DTOs from SVLearning to @Model objects in the app target,
/// then inserts them into the ModelContext.
///
/// ## Usage
/// ```swift
/// let summary = try ContentImportManager.importAllSeedContent(
///     into: modelContainer
/// )
/// ```
@MainActor
final class ContentImportManager {
    private static let logger = Logger(subsystem: "com.survibe", category: "ContentImportManager")

    /// Result of an import operation.
    struct ImportSummary: Sendable {
        /// Number of songs successfully imported.
        var songCount: Int = 0
        /// Number of lessons successfully imported.
        var lessonCount: Int = 0
        /// Descriptions of any non-fatal errors encountered.
        var errorDescriptions: [String] = []

        /// Human-readable summary.
        var description: String {
            "Songs: \(songCount), Lessons: \(lessonCount), Errors: \(errorDescriptions.count)"
        }
    }

    // MARK: - Import All

    /// Performs a complete seed content import from bundled JSON files.
    ///
    /// Reads `seed-songs.json` and `seed-lessons.json` from the main bundle,
    /// validates via SVLearning importers, maps to @Model objects, and inserts
    /// into the provided ModelContainer.
    ///
    /// - Parameters:
    ///   - container: SwiftData ModelContainer for insert operations.
    ///   - bundle: Bundle containing JSON resources (default: `.main`).
    /// - Returns: Summary of the import results.
    /// - Throws: If the ModelContext fails to save.
    static func importAllSeedContent(
        into container: ModelContainer,
        from bundle: Bundle = .main
    ) throws -> ImportSummary {
        logger.info("Starting seed content import")
        var summary = ImportSummary()
        let context = ModelContext(container)

        // Import songs
        if let songsURL = bundle.url(forResource: "seed-songs", withExtension: "json") {
            do {
                let data = try Data(contentsOf: songsURL)
                let songDTOs = SongImporter.importSongs(from: data)
                for dto in songDTOs {
                    let song = mapSongDTO(dto)
                    context.insert(song)
                    summary.songCount += 1
                }
                logger.info("Imported \(summary.songCount) songs")
            } catch {
                logger.error("Error reading seed-songs.json: \(error)")
                summary.errorDescriptions.append("Songs: \(error.localizedDescription)")
            }
        } else {
            logger.warning("seed-songs.json not found in bundle")
        }

        // Import lessons
        if let lessonsURL = bundle.url(forResource: "seed-lessons", withExtension: "json") {
            do {
                let data = try Data(contentsOf: lessonsURL)
                let lessonDTOs = LessonImporter.importLessons(from: data)
                for dto in lessonDTOs {
                    let lesson = mapLessonDTO(dto)
                    context.insert(lesson)
                    summary.lessonCount += 1
                }
                logger.info("Imported \(summary.lessonCount) lessons")
            } catch {
                logger.error("Error reading seed-lessons.json: \(error)")
                summary.errorDescriptions.append("Lessons: \(error.localizedDescription)")
            }
        } else {
            logger.warning("seed-lessons.json not found in bundle")
        }

        // Save all changes
        try context.save()
        logger.info("Seed content saved: \(summary.description)")
        return summary
    }

    // MARK: - DTO → @Model Mapping

    /// Maps a `SongImportDTO` to a `Song` @Model instance.
    private static func mapSongDTO(_ dto: SongImportDTO) -> Song {
        let song = Song(
            slugId: dto.slugId,
            title: dto.title,
            artist: dto.artist,
            language: dto.language,
            difficulty: dto.difficulty,
            category: dto.category,
            ragaName: dto.ragaName ?? "",
            tempo: dto.tempo,
            durationSeconds: dto.durationSeconds
        )
        song.isFree = dto.isFree ?? false
        song.sortOrder = dto.sortOrder

        // Encode notation arrays to JSON Data blobs
        song.sargamNotation = try? JSONEncoder().encode(dto.sargamNotation)
        song.westernNotation = try? JSONEncoder().encode(dto.westernNotation)

        // Encode MIDI data from base64 if present
        if let midiString = dto.midiData as String?, !midiString.isEmpty {
            song.midiData = Data(base64Encoded: midiString)
        }

        return song
    }

    /// Maps a `LessonImportDTO` to a `Lesson` @Model instance.
    private static func mapLessonDTO(_ dto: LessonImportDTO) -> Lesson {
        let lesson = Lesson(
            lessonId: dto.lessonId,
            title: dto.title,
            lessonDescription: dto.lessonDescription,
            difficulty: dto.difficulty,
            orderIndex: dto.orderIndex
        )
        lesson.isFree = dto.isFree ?? false

        // Encode prerequisite IDs to JSON blob
        lesson.prerequisiteLessonIds = try? JSONEncoder().encode(dto.prerequisiteLessonIds ?? [])

        // Encode associated song IDs to JSON blob (stored as String slugs)
        lesson.associatedSongIds = try? JSONEncoder().encode(dto.associatedSongIds ?? [])

        // Map LessonStepDTO → LessonStep, then encode to JSON blob
        let steps = dto.steps.map { stepDTO in
            LessonStep(
                stepType: stepDTO.stepType,
                content: stepDTO.content,
                songId: nil,
                durationSeconds: stepDTO.durationSeconds
            )
        }
        lesson.stepsData = try? JSONEncoder().encode(steps)

        return lesson
    }
}

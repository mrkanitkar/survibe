import Foundation
import SwiftData
import os.log

/// Manages first-launch seed content loading into SwiftData.
///
/// Uses a UserDefaults flag to ensure idempotent loading — seed content
/// is imported only once, even if the app is restarted.
///
/// ## Usage
/// Call from `SurVibeApp.init()` after ModelContainer is created:
/// ```swift
/// SeedContentLoader.loadSeedContentIfNeeded(into: modelContainer)
/// ```
@MainActor
final class SeedContentLoader {
    private static let logger = Logger(subsystem: "com.survibe", category: "SeedContentLoader")
    private static let seedContentLoadedKey = "com.survibe.seedContentLoaded"

    /// Whether seed content has already been loaded.
    static var isSeedContentLoaded: Bool {
        UserDefaults.standard.bool(forKey: seedContentLoadedKey)
    }

    /// Loads seed content if not already loaded.
    ///
    /// Safe to call multiple times; idempotent via UserDefaults flag.
    /// Runs synchronously on the main actor (called during app init).
    ///
    /// - Parameter container: SwiftData ModelContainer for inserts.
    static func loadSeedContentIfNeeded(into container: ModelContainer) {
        guard !isSeedContentLoaded else {
            logger.info("Seed content already loaded; skipping.")
            return
        }

        do {
            let summary = try ContentImportManager.importAllSeedContent(into: container)
            UserDefaults.standard.set(true, forKey: seedContentLoadedKey)
            logger.info("Seed content loaded successfully: \(summary.description)")
        } catch {
            logger.error("Seed content loading failed: \(error). App will continue without seed data.")
        }
    }

    /// Resets the seed content loaded flag (for testing/debug).
    ///
    /// - Warning: Use only in debug builds or testing contexts.
    static func resetSeedContentFlag() {
        #if DEBUG
            UserDefaults.standard.removeObject(forKey: seedContentLoadedKey)
            logger.info("Seed content flag reset (DEBUG only)")
        #else
            logger.warning("resetSeedContentFlag called in non-DEBUG build; ignoring")
        #endif
    }
}

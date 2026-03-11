import SVAI
import SVAdvanced
import SVAudio
import SVBilling
import SVCore
import SVLearning
import SVSocial
import SwiftData
import SwiftUI
import os.log

/// SurVibe app entry point — Indian music learning platform.
@main
struct SurVibeApp: App {
    // MARK: - Properties

    /// ModelContainer with all 9 SwiftData models and CloudKit automatic sync.
    /// Falls back to in-memory store if persistent container fails.
    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        // Configure ModelContainer with CloudKit automatic database
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
        let appLogger = Logger(subsystem: "com.survibe", category: "App")
        let isTestHost = ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil

        if isTestHost {
            // Test host: use in-memory store, no CloudKit.
            // Tests must not depend on persistent storage or CloudKit entitlements.
            do {
                let testConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: schema, configurations: [testConfig])
            } catch {
                fatalError("Test ModelContainer failed: \(error)")
            }
        } else {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .automatic
            )

            // Proactive store reset: if the schema version has changed, delete the
            // old persistent store BEFORE creating the container. This prevents
            // SIGABRT crashes inside Core Data/CloudKit when encountering an
            // incompatible schema (versioned-schema migration is banned per CloudKit rules).
            let currentSchemaVersion = 2  // v2: Added Song, Lesson, Curriculum (Day 2)
            let previousSchemaVersion = UserDefaults.standard.integer(forKey: "survibe_schema_version")
            if previousSchemaVersion != 0, previousSchemaVersion < currentSchemaVersion {
                appLogger.info(
                    "Schema version changed (\(previousSchemaVersion) → \(currentSchemaVersion)). Resetting store."
                )
                Self.deleteSwiftDataStore()
            }
            UserDefaults.standard.set(currentSchemaVersion, forKey: "survibe_schema_version")

            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                appLogger.error(
                    "ModelContainer creation failed: \(error.localizedDescription). Attempting store reset."
                )
                Self.deleteSwiftDataStore()

                do {
                    modelContainer = try ModelContainer(
                        for: schema,
                        configurations: [modelConfiguration]
                    )
                    appLogger.info("ModelContainer created after store reset.")
                } catch {
                    appLogger.error(
                        "Retry failed: \(error.localizedDescription). Falling back to in-memory store."
                    )
                    do {
                        let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
                        modelContainer = try ModelContainer(for: schema, configurations: [fallback])
                    } catch {
                        fatalError("Failed to create even in-memory ModelContainer: \(error)")
                    }
                }
            }
        }

        // Initialize analytics — API key sourced from Info.plist (set via xcconfig)
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_API_KEY") as? String ?? ""
        #if DEBUG
        if apiKey.isEmpty || apiKey.contains("PLACEHOLDER") {
            Logger(subsystem: "com.survibe", category: "App")
                .warning("PostHog API key not configured. Analytics disabled.")
        }
        #endif
        if !apiKey.isEmpty, !apiKey.contains("PLACEHOLDER") {
            AnalyticsManager.shared.configure(apiKey: apiKey)
        }
        AnalyticsManager.shared.track(.appScaffoldingLoaded)

        // Activate MetricKit crash reporting and diagnostics
        CrashReportingManager.shared.activate()

        // Load seed content on first launch (idempotent).
        // Skip in test host — tests create their own containers and seed data.
        if !isTestHost {
            SeedContentLoader.loadSeedContentIfNeeded(into: modelContainer)
        }
    }

    // MARK: - Store Management

    /// Deletes all SwiftData/Core Data store files to recover from schema mismatches.
    ///
    /// During early development, new `@Model` types change the schema.
    /// SwiftData with CloudKit cannot use versioned-schema migration, so the safest
    /// recovery is to delete the local store and let CloudKit re-sync.
    /// Scans Application Support for all `.store` / `.sqlite` files and their
    /// WAL/SHM companions.
    private static func deleteSwiftDataStore() {
        let appLogger = Logger(subsystem: "com.survibe", category: "App")
        guard
            let appSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else { return }

        let fm = FileManager.default
        let storeExtensions: Set<String> = ["store", "store-shm", "store-wal", "sqlite", "sqlite-shm", "sqlite-wal"]

        guard let contents = try? fm.contentsOfDirectory(
            at: appSupportURL,
            includingPropertiesForKeys: nil
        ) else { return }

        for file in contents where storeExtensions.contains(file.pathExtension) {
            do {
                try fm.removeItem(at: file)
                appLogger.info("Deleted store file: \(file.lastPathComponent)")
            } catch {
                appLogger.error("Failed to delete \(file.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

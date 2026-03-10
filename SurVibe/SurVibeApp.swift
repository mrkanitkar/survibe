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

    /// ModelContainer with all 6 SwiftData models and CloudKit automatic sync.
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
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // Log error and fall back to in-memory store so the app can still launch
            Logger(subsystem: "com.survibe", category: "App")
                .error("ModelContainer creation failed: \(error.localizedDescription). Falling back to in-memory store.")
            do {
                let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: schema, configurations: [fallback])
            } catch {
                // If even in-memory fails, this is truly unrecoverable
                fatalError("Failed to create even in-memory ModelContainer: \(error)")
            }
        }

        // Store schema version for manual migration tracking
        UserDefaults.standard.set(1, forKey: "survibe_schema_version")

        // Initialize analytics — configure PostHog before first track call
        AnalyticsManager.shared.configure(apiKey: "phc_PLACEHOLDER_KEY")
        AnalyticsManager.shared.track(.appScaffoldingLoaded)
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

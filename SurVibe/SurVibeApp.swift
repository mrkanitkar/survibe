import SwiftUI
import SwiftData
import SVCore
import SVAudio
import SVLearning
import SVAI
import SVSocial
import SVBilling
import SVAdvanced

/// SurVibe app entry point — Indian music learning platform.
@main
struct SurVibeApp: App {
    /// ModelContainer with all 6 SwiftData models and CloudKit automatic sync.
    let modelContainer: ModelContainer

    init() {
        // Configure ModelContainer with CloudKit automatic database
        let schema = Schema([
            UserProfile.self,
            RiyazEntry.self,
            Achievement.self,
            SongProgress.self,
            LessonProgress.self,
            SubscriptionState.self
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
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Store schema version for manual migration tracking
        UserDefaults.standard.set(1, forKey: "survibe_schema_version")

        // Initialize analytics
        AnalyticsManager.shared.track(.appScaffoldingLoaded)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

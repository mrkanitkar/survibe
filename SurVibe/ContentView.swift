import SVCore
import SwiftUI

/// Root content view with 5-tab navigation.
///
/// Each tab maintains its own NavigationStack internally.
/// The AppRouter provides programmatic tab switching and navigation.
struct ContentView: View {
    // MARK: - Properties

    @State
    private var selectedTab: AppTab = .home
    @State
    private var router = AppRouter()

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.label, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeTab()
            }

            Tab(AppTab.learn.label, systemImage: AppTab.learn.systemImage, value: AppTab.learn) {
                LearnTab()
            }

            Tab(
                AppTab.practice.label,
                systemImage: AppTab.practice.systemImage,
                value: AppTab.practice
            ) {
                PracticeTab()
            }

            Tab(AppTab.songs.label, systemImage: AppTab.songs.systemImage, value: AppTab.songs) {
                SongsTab()
            }

            Tab(
                AppTab.profile.label,
                systemImage: AppTab.profile.systemImage,
                value: AppTab.profile
            ) {
                ProfileTab()
            }
        }
        .environment(router)
        .onChange(of: selectedTab) { _, newTab in
            router.switchTab(to: newTab)
            AnalyticsManager.shared.track(.tabSelected, properties: ["tab": newTab.label])
        }
    }
}

#Preview {
    ContentView()
}

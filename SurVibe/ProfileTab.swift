import SVCore
import SwiftUI

/// Profile tab — user profile and app settings.
struct ProfileTab: View {
    // MARK: - Properties

    @State private var languageManager = LanguageManager()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                profileSection
                settingsSection
            }
            .navigationTitle("Profile")
            .navigationDestination(for: String.self) { destination in
                if destination == "languages" {
                    LanguageSelectorView()
                }
            }
        }
        .accessibilityLabel(AccessibilityHelper.tabLabel(for: "Profile"))
    }

    // MARK: - Sections

    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("User profile coming in Sprint 1")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var settingsSection: some View {
        Section(header: Text("Settings")) {
            NavigationLink(value: "languages") {
                HStack {
                    Label("App Language", systemImage: "globe")
                    Spacer()
                    Text(verbatim: languageManager.currentLanguageDisplayName)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel(Text("App Language"))
            .accessibilityHint(
                Text("Current language: \(languageManager.currentLanguageDisplayName). Double tap to change.")
            )
        }
    }
}

#Preview {
    ProfileTab()
}

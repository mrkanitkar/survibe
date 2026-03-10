import SwiftUI

/// Full-screen language picker displaying all 23 supported languages.
///
/// Each language row shows the native script name (primary) and English name (secondary).
/// Selecting a language writes the `AppleLanguages` UserDefaults key and prompts the user
/// to restart the app for the change to take effect.
struct LanguageSelectorView: View {
    // MARK: - Properties

    @State private var languageManager = LanguageManager()
    @State private var showRestartAlert = false

    /// Tracks the currently selected code for immediate UI feedback.
    @State private var selectedCode: String?

    // MARK: - Body

    var body: some View {
        List {
            systemDefaultSection
            languagesSection
        }
        .navigationTitle("Languages")
        .alert(
            String(localized: "Restart Required"),
            isPresented: $showRestartAlert
        ) {
            Button(String(localized: "Restart Now"), role: .destructive) {
                exit(0)
            }
            Button(String(localized: "Later"), role: .cancel) {}
        } message: {
            Text("SurVibe needs to restart to apply the new language.")
        }
        .onAppear {
            selectedCode = languageManager.selectedLanguageCode
        }
    }

    // MARK: - Sections

    private var systemDefaultSection: some View {
        Section {
            Button {
                selectLanguage(nil)
            } label: {
                HStack {
                    Text("System Default")
                        .foregroundStyle(.primary)
                    Spacer()
                    if selectedCode == nil {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                    }
                }
            }
            .accessibilityLabel(Text("System Default"))
            .accessibilityHint(Text(systemDefaultHint))
        }
    }

    private var languagesSection: some View {
        Section {
            ForEach(SupportedLanguage.all) { language in
                languageRow(language)
            }
        }
    }

    private func languageRow(_ language: SupportedLanguage) -> some View {
        let isSelected = selectedCode == language.id
        return Button {
            selectLanguage(language.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: language.nativeName)
                        .foregroundStyle(.primary)
                    Text(verbatim: language.englishName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityLabel(
            Text(verbatim: "\(language.englishName), \(language.nativeName)")
        )
        .accessibilityHint(
            Text(verbatim: languageRowHint(language.englishName, isSelected: isSelected))
        )
    }

    // MARK: - Private Methods

    /// Accessibility hint for the system default row.
    private var systemDefaultHint: String {
        if selectedCode == nil {
            return ""
        }
        return String(localized: "Double tap to use system language")
    }

    /// Accessibility hint for a language row.
    private func languageRowHint(_ englishName: String, isSelected: Bool) -> String {
        if isSelected {
            return ""
        }
        return String(localized: "Double tap to switch to \(englishName)")
    }

    /// Updates the language selection and triggers the restart alert.
    private func selectLanguage(_ code: String?) {
        guard code != selectedCode else { return }
        selectedCode = code
        languageManager.setLanguage(code)
        showRestartAlert = true
    }
}

#Preview {
    NavigationStack {
        LanguageSelectorView()
    }
}

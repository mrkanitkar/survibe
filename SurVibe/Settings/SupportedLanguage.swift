import SwiftUI

/// A language supported by SurVibe for in-app localization.
///
/// Each entry pairs an ISO 639 language code with the language's native script name,
/// English name, and text direction. Native names are hardcoded (not localized) so they
/// always render in their own script regardless of the current app locale.
struct SupportedLanguage: Identifiable, Hashable, Sendable {
    /// ISO 639 language code matching the project's `knownRegions`.
    let id: String

    /// The language name in its own script (e.g. "हिन्दी", "தமிழ்").
    let nativeName: String

    /// The English name for secondary display.
    let englishName: String

    /// Text direction: `.leftToRight` for most, `.rightToLeft` for Urdu, Kashmiri, Sindhi.
    let scriptDirection: LayoutDirection

    // MARK: - All Supported Languages

    /// The 23 languages SurVibe supports (English + 22 Indian), sorted by English name.
    static let all: [SupportedLanguage] = [
        SupportedLanguage(id: "as", nativeName: "অসমীয়া", englishName: "Assamese", scriptDirection: .leftToRight),
        SupportedLanguage(id: "bn", nativeName: "বাংলা", englishName: "Bengali", scriptDirection: .leftToRight),
        SupportedLanguage(id: "brx", nativeName: "बड़ो", englishName: "Bodo", scriptDirection: .leftToRight),
        SupportedLanguage(id: "doi", nativeName: "डोगरी", englishName: "Dogri", scriptDirection: .leftToRight),
        SupportedLanguage(id: "en", nativeName: "English", englishName: "English", scriptDirection: .leftToRight),
        SupportedLanguage(id: "gu", nativeName: "ગુજરાતી", englishName: "Gujarati", scriptDirection: .leftToRight),
        SupportedLanguage(id: "hi", nativeName: "हिन्दी", englishName: "Hindi", scriptDirection: .leftToRight),
        SupportedLanguage(id: "kn", nativeName: "ಕನ್ನಡ", englishName: "Kannada", scriptDirection: .leftToRight),
        SupportedLanguage(id: "ks", nativeName: "کٲشُر", englishName: "Kashmiri", scriptDirection: .rightToLeft),
        SupportedLanguage(id: "kok", nativeName: "कोंकणी", englishName: "Konkani", scriptDirection: .leftToRight),
        SupportedLanguage(id: "mai", nativeName: "मैथिली", englishName: "Maithili", scriptDirection: .leftToRight),
        SupportedLanguage(id: "ml", nativeName: "മലയാളം", englishName: "Malayalam", scriptDirection: .leftToRight),
        SupportedLanguage(id: "mni", nativeName: "মৈতৈলোন্", englishName: "Manipuri", scriptDirection: .leftToRight),
        SupportedLanguage(id: "mr", nativeName: "मराठी", englishName: "Marathi", scriptDirection: .leftToRight),
        SupportedLanguage(id: "ne", nativeName: "नेपाली", englishName: "Nepali", scriptDirection: .leftToRight),
        SupportedLanguage(id: "or", nativeName: "ଓଡ଼ିଆ", englishName: "Odia", scriptDirection: .leftToRight),
        SupportedLanguage(id: "pa", nativeName: "ਪੰਜਾਬੀ", englishName: "Punjabi", scriptDirection: .leftToRight),
        SupportedLanguage(id: "sa", nativeName: "संस्कृतम्", englishName: "Sanskrit", scriptDirection: .leftToRight),
        SupportedLanguage(id: "sat", nativeName: "ᱥᱟᱱᱛᱟᱲᱤ", englishName: "Santali", scriptDirection: .leftToRight),
        SupportedLanguage(id: "sd", nativeName: "سنڌي", englishName: "Sindhi", scriptDirection: .rightToLeft),
        SupportedLanguage(id: "ta", nativeName: "தமிழ்", englishName: "Tamil", scriptDirection: .leftToRight),
        SupportedLanguage(id: "te", nativeName: "తెలుగు", englishName: "Telugu", scriptDirection: .leftToRight),
        SupportedLanguage(id: "ur", nativeName: "اردو", englishName: "Urdu", scriptDirection: .rightToLeft),
    ]
}

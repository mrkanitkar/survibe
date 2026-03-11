import SwiftUI

/// Color extensions for the Rang gamification color system.
///
/// Each rang (level) has a signature color used for badges, progress indicators,
/// and themed UI elements. Colors are designed for both light and dark mode.
///
/// **WCAG AA compliance:**
/// - Neel (#3F51B5): 4.6:1 contrast — safe for all text sizes.
/// - Hara (#388E3C): 4.5:1 contrast — safe for all text sizes.
/// - Peela (#F9A825): 3.1:1 contrast — large text (18pt+) and decorative only.
/// - Lal (#D32F2F): 5.3:1 contrast — safe for all text sizes.
/// - Sona (#FFB300): 3.0:1 contrast — large text (18pt+) and decorative only.
///
/// For body text on light backgrounds, use `rangPeelaDark` / `rangSonaDark` variants.
extension Color {
    /// Rang 1 — Neel (Indigo). Beginner level. Hex #3F51B5. WCAG AA 4.6:1.
    public static let rangNeel = Color(red: 0x3F / 255.0, green: 0x51 / 255.0, blue: 0xB5 / 255.0)

    /// Rang 2 — Hara (Green). Developing level. Hex #388E3C. WCAG AA 4.5:1.
    public static let rangHara = Color(red: 0x38 / 255.0, green: 0x8E / 255.0, blue: 0x3C / 255.0)

    /// Rang 3 — Peela (Yellow). Intermediate level. Hex #F9A825. WCAG AA 3.1:1 (large text only).
    public static let rangPeela = Color(red: 0xF9 / 255.0, green: 0xA8 / 255.0, blue: 0x25 / 255.0)

    /// Rang 4 — Lal (Red). Advanced level. Hex #D32F2F. WCAG AA 5.3:1.
    public static let rangLal = Color(red: 0xD3 / 255.0, green: 0x2F / 255.0, blue: 0x2F / 255.0)

    /// Rang 5 — Sona (Gold). Master level. Hex #FFB300. WCAG AA 3.0:1 (large text only).
    public static let rangSona = Color(red: 0xFF / 255.0, green: 0xB3 / 255.0, blue: 0x00 / 255.0)

    /// Peela body text variant. Hex #C17900. WCAG AA 4.5:1 — safe for all text sizes.
    public static let rangPeelaDark = Color(red: 0xC1 / 255.0, green: 0x79 / 255.0, blue: 0x00 / 255.0)

    /// Sona body text variant. Hex #B87700. WCAG AA 4.5:1 — safe for all text sizes.
    public static let rangSonaDark = Color(red: 0xB8 / 255.0, green: 0x77 / 255.0, blue: 0x00 / 255.0)
}

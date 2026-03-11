import SwiftUI

/// Maps Sargam note names to their associated colors and accessibility shapes.
///
/// Colors follow the traditional spectral mapping used in Indian classical
/// music pedagogy: Sa (red) through Ni (violet). Shape indicators provide
/// colorblind accessibility so every swar is distinguishable without
/// relying on color alone.
enum SargamColorMap {

    // MARK: - Color Mapping

    /// Returns the color associated with a given swar name.
    ///
    /// Each of the seven shuddh (natural) swar maps to a spectral color.
    /// Unknown or unrecognized note names return gray as a safe fallback.
    ///
    /// - Parameter swar: The note name (e.g. "Sa", "Re", "Ga").
    /// - Returns: A `Color` for the swar, or `.gray` if unrecognized.
    static func color(for swar: String) -> Color {
        switch swar {
        case "Sa": .red
        case "Re": Color(red: 1.0, green: 0.6, blue: 0.0)
        case "Ga": .yellow
        case "Ma": .green
        case "Pa": .blue
        case "Dha": Color(red: 0.3, green: 0.0, blue: 0.5)
        case "Ni": Color(red: 0.6, green: 0.2, blue: 0.8)
        default: .gray
        }
    }

    // MARK: - Shape Mapping

    /// Returns an SF Symbol name representing a distinct shape for the given swar.
    ///
    /// Each swar gets a unique geometric shape so notes are distinguishable
    /// without relying on color. Used in accessibility overlays and
    /// colorblind-friendly rendering modes.
    ///
    /// - Parameter swar: The note name (e.g. "Sa", "Re", "Ga").
    /// - Returns: An SF Symbol name string for the shape.
    static func shape(for swar: String) -> String {
        switch swar {
        case "Sa": "circle.fill"
        case "Re": "square.fill"
        case "Ga": "triangle.fill"
        case "Ma": "diamond.fill"
        case "Pa": "pentagon.fill"
        case "Dha": "hexagon.fill"
        case "Ni": "star.fill"
        default: "questionmark.circle"
        }
    }
}

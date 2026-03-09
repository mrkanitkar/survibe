import SwiftUI

/// Rang (color) system mapping musical achievement levels to colors.
/// Full implementation in Batch 3.
public enum RangLevel: Int, CaseIterable, Sendable {
    case neel = 1    // Beginner — Indigo Blue
    case hara = 2    // Developing — Forest Green
    case peela = 3   // Intermediate — Marigold
    case lal = 4     // Advanced — Vermillion
    case sona = 5    // Master — Gold
}

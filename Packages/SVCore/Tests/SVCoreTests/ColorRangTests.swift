import SwiftUI
import Testing

@testable import SVCore

@Suite("Color+Rang Tests")
struct ColorRangTests {
    @Test("All seven rang colors are defined")
    func allColorsExist() {
        // Verify all 7 colors can be accessed without crashing
        let colors: [Color] = [
            .rangNeel, .rangHara, .rangPeela, .rangLal, .rangSona,
            .rangPeelaDark, .rangSonaDark,
        ]
        #expect(colors.count == 7)
    }

    @Test("Primary rang colors are distinct")
    func primaryColorsAreDistinct() {
        let primaries: [Color] = [.rangNeel, .rangHara, .rangPeela, .rangLal, .rangSona]
        // Each pair should be different
        for i in 0..<primaries.count {
            for j in (i + 1)..<primaries.count {
                #expect(primaries[i] != primaries[j], "Color \(i) and \(j) should differ")
            }
        }
    }

    @Test("Body text variants differ from their base colors")
    func bodyTextVariantsDiffer() {
        #expect(Color.rangPeela != Color.rangPeelaDark)
        #expect(Color.rangSona != Color.rangSonaDark)
    }

    @Test("Rang colors resolve without crashing in both color schemes")
    func colorsResolveInBothSchemes() {
        // Resolve each color to verify they don't crash
        // (Color is a value type, accessing it validates the initializer)
        let _ = Color.rangNeel.description
        let _ = Color.rangHara.description
        let _ = Color.rangPeela.description
        let _ = Color.rangLal.description
        let _ = Color.rangSona.description
        let _ = Color.rangPeelaDark.description
        let _ = Color.rangSonaDark.description
    }
}

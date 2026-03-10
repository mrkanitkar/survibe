import Foundation
import Testing

@testable import SVAudio

@Suite("Localization Validation")
struct LocalizationTests {
    @Test func allLatencyPresetDisplayNamesNonEmpty() {
        for preset in LatencyPreset.allCases {
            let name = preset.displayName
            #expect(!name.isEmpty, "displayName for \(preset.rawValue) should not be empty")
        }
    }

    @Test func allExpressionTypeDisplayNamesNonEmpty() {
        let types: [ExpressionType] = [.stable, .vibrato, .meend, .gamaka, .indeterminate]
        for type in types {
            let name = type.displayName
            #expect(!name.isEmpty, "displayName for \(type.rawValue) should not be empty")
        }
    }
}

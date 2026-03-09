import Testing
@testable import SVCore

@Suite("AccessibilityHelper Tests")
struct AccessibilityHelperTests {
    @Test("Swar label returns descriptive VoiceOver text for known notes")
    func testKnownSwarLabels() {
        #expect(AccessibilityHelper.swarLabel(for: "Sa").contains("tonic"))
        #expect(AccessibilityHelper.swarLabel(for: "Re").contains("second"))
        #expect(AccessibilityHelper.swarLabel(for: "Pa").contains("fifth"))
    }

    @Test("Swar label returns input for unknown notes")
    func testUnknownSwarLabel() {
        #expect(AccessibilityHelper.swarLabel(for: "Unknown") == "Unknown")
    }

    @Test("Tab label includes 'tab' suffix")
    func testTabLabel() {
        #expect(AccessibilityHelper.tabLabel(for: "Learn") == "Learn tab")
        #expect(AccessibilityHelper.tabLabel(for: "Practice") == "Practice tab")
    }

    @Test("Rang label includes display name and proficiency")
    func testRangLabel() {
        let label = AccessibilityHelper.rangLabel(for: .neel)
        #expect(label.contains("Neel"))
        #expect(label.contains("Beginner"))
    }

    @Test("Pitch accuracy label for in-tune notes")
    func testInTuneLabel() {
        #expect(AccessibilityHelper.pitchAccuracyLabel(centsOffset: 0) == "In tune")
        #expect(AccessibilityHelper.pitchAccuracyLabel(centsOffset: 3) == "In tune")
        #expect(AccessibilityHelper.pitchAccuracyLabel(centsOffset: -4) == "In tune")
    }

    @Test("Pitch accuracy label for sharp notes")
    func testSharpLabel() {
        let label = AccessibilityHelper.pitchAccuracyLabel(centsOffset: 15)
        #expect(label.contains("Sharp"))
        #expect(label.contains("15"))
    }

    @Test("Pitch accuracy label for flat notes")
    func testFlatLabel() {
        let label = AccessibilityHelper.pitchAccuracyLabel(centsOffset: -20)
        #expect(label.contains("Flat"))
        #expect(label.contains("20"))
    }
}

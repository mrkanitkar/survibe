import Testing
@testable import SVCore

@Suite("RangColorSystem Tests")
struct RangColorSystemTests {
    @Test("Five rang levels exist")
    func testLevelCount() {
        #expect(RangLevel.allCases.count == 5)
    }

    @Test("Neel is level 1, Sona is level 5")
    func testRawValues() {
        #expect(RangLevel.neel.rawValue == 1)
        #expect(RangLevel.sona.rawValue == 5)
    }

    @Test("Display names are correct")
    func testDisplayNames() {
        #expect(RangLevel.neel.displayName == "Neel")
        #expect(RangLevel.hara.displayName == "Hara")
        #expect(RangLevel.peela.displayName == "Peela")
        #expect(RangLevel.lal.displayName == "Lal")
        #expect(RangLevel.sona.displayName == "Sona")
    }

    @Test("Proficiency labels are correct")
    func testProficiencyLabels() {
        #expect(RangLevel.neel.proficiencyLabel == "Beginner")
        #expect(RangLevel.sona.proficiencyLabel == "Master")
    }

    @Test("XP thresholds are ordered correctly")
    func testXPThresholds() {
        let thresholds = RangLevel.allCases.map(\.xpThreshold)
        for i in 1..<thresholds.count {
            #expect(thresholds[i] > thresholds[i - 1])
        }
    }

    @Test("Level for XP returns correct level")
    func testLevelForXP() {
        #expect(RangLevel.level(for: 0) == .neel)
        #expect(RangLevel.level(for: 499) == .neel)
        #expect(RangLevel.level(for: 500) == .hara)
        #expect(RangLevel.level(for: 2000) == .peela)
        #expect(RangLevel.level(for: 5000) == .lal)
        #expect(RangLevel.level(for: 10000) == .sona)
        #expect(RangLevel.level(for: 99999) == .sona)
    }
}

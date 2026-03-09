import Testing
@testable import SVCore

@Suite("DesignTokens Tests")
struct DesignTokensTests {
    @Test("Spacing values are in ascending order")
    func testSpacingOrder() {
        #expect(Spacing.xs < Spacing.sm)
        #expect(Spacing.sm < Spacing.md)
        #expect(Spacing.md < Spacing.lg)
        #expect(Spacing.lg < Spacing.xl)
        #expect(Spacing.xl < Spacing.xxl)
    }

    @Test("Spacing values match design spec")
    func testSpacingValues() {
        #expect(Spacing.xs == 4)
        #expect(Spacing.sm == 8)
        #expect(Spacing.md == 16)
        #expect(Spacing.lg == 24)
        #expect(Spacing.xl == 32)
        #expect(Spacing.xxl == 48)
    }

    @Test("Corner radius values are in ascending order")
    func testCornerRadiusOrder() {
        #expect(CornerRadius.sm < CornerRadius.md)
        #expect(CornerRadius.md < CornerRadius.lg)
        #expect(CornerRadius.lg < CornerRadius.pill)
    }

    @Test("Pill radius is large enough for any button")
    func testPillRadius() {
        #expect(CornerRadius.pill == 999)
    }
}

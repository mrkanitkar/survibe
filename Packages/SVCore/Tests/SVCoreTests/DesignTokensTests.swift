import SwiftUI
import Testing

@testable import SVCore

@Suite("DesignTokens Tests")
struct DesignTokensTests {
    // MARK: - Spacing

    @Test("Spacing values are in ascending order")
    func spacingOrder() {
        #expect(Spacing.xs < Spacing.sm)
        #expect(Spacing.sm < Spacing.md)
        #expect(Spacing.md < Spacing.lg)
        #expect(Spacing.lg < Spacing.xl)
        #expect(Spacing.xl < Spacing.xxl)
    }

    @Test("Spacing values match design spec")
    func spacingValues() {
        #expect(Spacing.xs == 4)
        #expect(Spacing.sm == 8)
        #expect(Spacing.md == 16)
        #expect(Spacing.lg == 24)
        #expect(Spacing.xl == 32)
        #expect(Spacing.xxl == 48)
    }

    @Test("Spacing uses consistent 4-point grid")
    func spacingGridAlignment() {
        let values: [CGFloat] = [
            Spacing.xs, Spacing.sm, Spacing.md, Spacing.lg, Spacing.xl, Spacing.xxl,
        ]
        for value in values {
            #expect(
                value.truncatingRemainder(dividingBy: 4) == 0,
                "Spacing \(value) is not on the 4-point grid"
            )
        }
    }

    // MARK: - Corner Radius

    @Test("Corner radius values are in ascending order")
    func cornerRadiusOrder() {
        #expect(CornerRadius.sm < CornerRadius.md)
        #expect(CornerRadius.md < CornerRadius.lg)
        #expect(CornerRadius.lg < CornerRadius.pill)
    }

    @Test("Pill radius exceeds any reasonable view dimension")
    func pillRadiusIsLargeEnough() {
        #expect(CornerRadius.pill > 683)
    }

    @Test("Corner radii are positive")
    func cornerRadiiPositive() {
        #expect(CornerRadius.sm > 0)
        #expect(CornerRadius.md > 0)
        #expect(CornerRadius.lg > 0)
    }

    // MARK: - Typography

    @Test("Typography exposes all 11 Dynamic Type styles")
    func typographyCoversAllStyles() {
        let styles: [Font] = [
            Typography.largeTitle, Typography.title, Typography.title2, Typography.title3,
            Typography.headline, Typography.body, Typography.callout, Typography.subheadline,
            Typography.footnote, Typography.caption, Typography.caption2,
        ]
        #expect(styles.count == 11)
    }

    @Test("Typography maps to correct system fonts")
    func typographyMapsToSystemFonts() {
        #expect(Typography.largeTitle == Font.largeTitle)
        #expect(Typography.body == Font.body)
        #expect(Typography.caption == Font.caption)
        #expect(Typography.headline == Font.headline)
    }
}

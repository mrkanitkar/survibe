import SwiftUI

/// Design tokens for consistent spacing throughout the app.
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

/// Design tokens for corner radii.
public enum CornerRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let pill: CGFloat = 999
}

/// Semantic typography styles using Dynamic Type.
public enum Typography {
    /// Large title for section headers.
    public static let largeTitle = Font.largeTitle

    /// Primary title.
    public static let title = Font.title

    /// Secondary title.
    public static let title2 = Font.title2

    /// Tertiary title.
    public static let title3 = Font.title3

    /// Headline text.
    public static let headline = Font.headline

    /// Body text — default reading size.
    public static let body = Font.body

    /// Callout text.
    public static let callout = Font.callout

    /// Subheadline text.
    public static let subheadline = Font.subheadline

    /// Footnote text.
    public static let footnote = Font.footnote

    /// Caption text — smallest readable size.
    public static let caption = Font.caption

    /// Caption 2 — secondary caption.
    public static let caption2 = Font.caption2
}

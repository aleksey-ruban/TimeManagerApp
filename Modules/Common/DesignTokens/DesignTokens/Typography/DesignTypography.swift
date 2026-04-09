import UIKit

@MainActor
public enum DesignTypography {
    public struct Style {
        public let font: UIFont
        public let lineHeight: CGFloat
        public let kerning: CGFloat

        public init(font: UIFont, lineHeight: CGFloat, kerning: CGFloat) {
            self.font = font
            self.lineHeight = lineHeight
            self.kerning = kerning
        }
    }

    public static let displaySemibold32 = Style(
        font: .systemFont(ofSize: 32, weight: .semibold),
        lineHeight: 36,
        kerning: 0
    )

    public static let displayMedium32 = Style(
        font: .systemFont(ofSize: 32, weight: .medium),
        lineHeight: 37,
        kerning: 0
    )

    public static let bodyRegular15 = Style(
        font: .systemFont(ofSize: 15, weight: .regular),
        lineHeight: 17,
        kerning: 0
    )
    
    public static let bodyRegular16 = Style(
        font: .systemFont(ofSize: 16, weight: .regular),
        lineHeight: 17,
        kerning: 0
    )
    
    public static let bodyRegular17 = Style(
        font: .systemFont(ofSize: 17, weight: .regular),
        lineHeight: 22,
        kerning: -0.43
    )

    public static let bodyMedium17 = Style(
        font: .systemFont(ofSize: 17, weight: .medium),
        lineHeight: 22,
        kerning: -0.43
    )

    public static let labelLight13 = Style(
        font: .systemFont(ofSize: 13, weight: .light),
        lineHeight: 22,
        kerning: -0.43
    )

    public static let labelRegular13 = Style(
        font: .systemFont(ofSize: 13, weight: .regular),
        lineHeight: 19,
        kerning: 0
    )

    public static let captionLight12 = Style(
        font: .systemFont(ofSize: 12, weight: .light),
        lineHeight: 16,
        kerning: 0
    )
}

import UIKit
import DesignTokens

@MainActor
public struct CommonTextFieldConfiguration {
    public enum InputKind {
        case plain
        case email
        case phone
        case numericCode
        case password
    }

    public struct Appearance {
        public var textColor: UIColor
        public var hintColor: UIColor
        public var borderColor: UIColor
        public var errorColor: UIColor
        public var tintColor: UIColor
        public var textFont: UIFont
        public var hintFont: UIFont
        public var floatingHintFont: UIFont
        public var errorFont: UIFont
        public var horizontalPadding: CGFloat
        public var topPadding: CGFloat
        public var bottomPadding: CGFloat
        public var controlsSpacing: CGFloat

        @MainActor
        public init(
            textColor: UIColor = DesignColor.textPrimary,
            hintColor: UIColor = DesignColor.textSecondary,
            borderColor: UIColor = DesignColor.secondary,
            errorColor: UIColor = DesignColor.destructive,
            tintColor: UIColor = DesignColor.textPrimary,
            textFont: UIFont = DesignTypography.bodyRegular17.font,
            hintFont: UIFont = DesignTypography.bodyRegular17.font,
            floatingHintFont: UIFont = DesignTypography.labelLight13.font,
            errorFont: UIFont = DesignTypography.bodyRegular15.font,
            horizontalPadding: CGFloat = 0,
            topPadding: CGFloat = DesignSize.textFieldTopPadding,
            bottomPadding: CGFloat = DesignSize.textFieldBottomPadding,
            controlsSpacing: CGFloat = DesignSpacing.small
        ) {
            self.textColor = textColor
            self.hintColor = hintColor
            self.borderColor = borderColor
            self.errorColor = errorColor
            self.tintColor = tintColor
            self.textFont = textFont
            self.hintFont = hintFont
            self.floatingHintFont = floatingHintFont
            self.errorFont = errorFont
            self.horizontalPadding = horizontalPadding
            self.topPadding = topPadding
            self.bottomPadding = bottomPadding
            self.controlsSpacing = controlsSpacing
        }
    }

    public var hint: String
    public var kind: InputKind
    public var text: String?
    public var errorText: String?
    public var isEnabled: Bool
    public var showsClearButton: Bool
    public var showsDoneAccessory: Bool
    public var appearance: Appearance

    public init(
        hint: String,
        kind: InputKind = .plain,
        text: String? = nil,
        errorText: String? = nil,
        isEnabled: Bool = true,
        showsClearButton: Bool = true,
        showsDoneAccessory: Bool = true,
        appearance: Appearance = .init()
    ) {
        self.hint = hint
        self.kind = kind
        self.text = text
        self.errorText = errorText
        self.isEnabled = isEnabled
        self.showsClearButton = showsClearButton
        self.showsDoneAccessory = showsDoneAccessory
        self.appearance = appearance
    }
}

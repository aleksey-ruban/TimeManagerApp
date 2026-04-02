import UIKit
import DesignTokens

@MainActor
public struct PrimaryButtonConfiguration {
    public struct Appearance {
        public var titleColor: UIColor
        public var disabledTitleColor: UIColor
        public var backgroundColor: UIColor
        public var disabledBackgroundColor: UIColor
        public var titleFont: UIFont
        public var cornerRadius: CGFloat
        public var contentInsets: NSDirectionalEdgeInsets

        @MainActor
        public init(
            titleColor: UIColor = DesignColor.textPrimary,
            disabledTitleColor: UIColor = DesignColor.textSecondary,
            backgroundColor: UIColor = DesignColor.buttonPrimary,
            disabledBackgroundColor: UIColor = DesignColor.buttonUnavailable,
            titleFont: UIFont = .systemFont(ofSize: 16, weight: .regular),
            cornerRadius: CGFloat = DesignSize.primaryButtonCornerRadius,
            contentInsets: NSDirectionalEdgeInsets = .init(
                top: DesignSpacing.medium,
                leading: DesignSpacing.large,
                bottom: DesignSpacing.medium,
                trailing: DesignSpacing.large
            )
        ) {
            self.titleColor = titleColor
            self.disabledTitleColor = disabledTitleColor
            self.backgroundColor = backgroundColor
            self.disabledBackgroundColor = disabledBackgroundColor
            self.titleFont = titleFont
            self.cornerRadius = cornerRadius
            self.contentInsets = contentInsets
        }
    }

    public var title: String
    public var isEnabled: Bool
    public var appearance: Appearance

    public init(
        title: String,
        isEnabled: Bool = true,
        appearance: Appearance = .init()
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.appearance = appearance
    }
}

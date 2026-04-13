import UIKit
import DesignTokens

@MainActor
public struct LinkButtonConfiguration {
    public struct Appearance {
        public var titleColor: UIColor
        public var disabledTitleColor: UIColor
        public var titleFont: UIFont
        public var contentInsets: NSDirectionalEdgeInsets

        @MainActor
        public init(
            titleColor: UIColor = DesignColor.accent,
            disabledTitleColor: UIColor = DesignColor.textSecondary,
            titleFont: UIFont = .systemFont(ofSize: 16, weight: .regular),
            contentInsets: NSDirectionalEdgeInsets = .zero
        ) {
            self.titleColor = titleColor
            self.disabledTitleColor = disabledTitleColor
            self.titleFont = titleFont
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

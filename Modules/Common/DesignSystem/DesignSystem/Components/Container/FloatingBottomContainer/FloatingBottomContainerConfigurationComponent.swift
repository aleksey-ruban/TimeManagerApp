import UIKit
import DesignTokens

@MainActor
public struct FloatingBottomContainerConfiguration {
    public struct Gradient {
        public var isEnabled: Bool
        public var color: UIColor
        public var height: CGFloat

        public init(
            isEnabled: Bool = true,
            color: UIColor = DesignColor.backgroundPrimary,
            height: CGFloat = DesignSize.floatingBottomContainerGradientHeight
        ) {
            self.isEnabled = isEnabled
            self.color = color
            self.height = height
        }
    }

    public var primaryButton: PrimaryButtonConfiguration?
    public var secondaryButton: LinkButtonConfiguration?
    public var horizontalInset: CGFloat
    public var buttonSpacing: CGFloat
    public var bottomInset: CGFloat
    public var gradient: Gradient

    public init(
        primaryButton: PrimaryButtonConfiguration? = nil,
        secondaryButton: LinkButtonConfiguration? = nil,
        horizontalInset: CGFloat = DesignSpacing.large,
        buttonSpacing: CGFloat = DesignSpacing.medium,
        bottomInset: CGFloat = DesignSize.floatingBottomContainerRoundedScreenBottomInset,
        gradient: Gradient = .init()
    ) {
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.horizontalInset = horizontalInset
        self.buttonSpacing = buttonSpacing
        self.bottomInset = bottomInset
        self.gradient = gradient
    }
}

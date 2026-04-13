import UIKit
import DesignTokens

@MainActor
public final class PrimaryButton: UIView {
    public var onTap: (() -> Void)?

    public var title: String {
        get { configuration.title }
        set {
            configuration.title = newValue
            updateAppearance()
        }
    }

    public var isEnabled: Bool {
        get { configuration.isEnabled }
        set {
            configuration.isEnabled = newValue
            updateAppearance()
        }
    }

    public private(set) var configuration: PrimaryButtonConfiguration

    private let button = UIButton(type: .system)

    public init(configuration: PrimaryButtonConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupView()
        apply(configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func apply(configuration: PrimaryButtonConfiguration) {
        self.configuration = configuration
        updateAppearance()
    }

    public func setTitle(_ title: String) {
        configuration.title = title
        updateAppearance()
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: DesignSize.primaryButtonHeight)
    }
}

private extension PrimaryButton {
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addSubview(button)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: DesignSize.primaryButtonHeight),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func updateAppearance() {
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.title = configuration.title
        buttonConfiguration.baseBackgroundColor = configuration.isEnabled
            ? configuration.appearance.backgroundColor
            : configuration.appearance.disabledBackgroundColor
        buttonConfiguration.baseForegroundColor = configuration.isEnabled
            ? configuration.appearance.titleColor
            : configuration.appearance.disabledTitleColor
        buttonConfiguration.contentInsets = configuration.appearance.contentInsets
        buttonConfiguration.cornerStyle = .fixed
        buttonConfiguration.background.cornerRadius = configuration.appearance.cornerRadius

        let titleAttributes = AttributeContainer([
            .font: configuration.appearance.titleFont,
            .foregroundColor: configuration.isEnabled
                ? configuration.appearance.titleColor
                : configuration.appearance.disabledTitleColor,
        ])
        buttonConfiguration.attributedTitle = AttributedString(configuration.title, attributes: titleAttributes)

        button.configuration = buttonConfiguration
        button.isEnabled = true
        button.isUserInteractionEnabled = configuration.isEnabled
        button.alpha = 1
    }

    @objc
    func handleTap() {
        guard configuration.isEnabled else { return }
        onTap?()
    }
}

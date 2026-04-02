import UIKit
import DesignTokens

@MainActor
public final class LinkButton: UIView {
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

    public private(set) var configuration: LinkButtonConfiguration

    private let button = UIButton(type: .system)

    public init(configuration: LinkButtonConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupView()
        apply(configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func apply(configuration: LinkButtonConfiguration) {
        self.configuration = configuration
        updateAppearance()
    }

    public func setTitle(_ title: String) {
        configuration.title = title
        updateAppearance()
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: DesignSize.linkButtonHeight)
    }
}

private extension LinkButton {
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addSubview(button)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: DesignSize.linkButtonHeight),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func updateAppearance() {
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.title = configuration.title
        buttonConfiguration.baseBackgroundColor = .clear
        buttonConfiguration.baseForegroundColor = configuration.isEnabled
            ? configuration.appearance.titleColor
            : configuration.appearance.disabledTitleColor
        buttonConfiguration.contentInsets = configuration.appearance.contentInsets

        let titleAttributes = AttributeContainer([
            .font: configuration.appearance.titleFont,
            .foregroundColor: configuration.isEnabled
                ? configuration.appearance.titleColor
                : configuration.appearance.disabledTitleColor,
        ])
        buttonConfiguration.attributedTitle = AttributedString(configuration.title, attributes: titleAttributes)

        button.configuration = buttonConfiguration
        button.isEnabled = configuration.isEnabled
    }

    @objc
    func handleTap() {
        guard configuration.isEnabled else { return }
        onTap?()
    }
}

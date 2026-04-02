import UIKit
import DesignTokens

@MainActor
public final class FloatingBottomContainer: UIView {
    public private(set) var configuration: FloatingBottomContainerConfiguration

    public let primaryButton: PrimaryButton?
    public let secondaryButton: LinkButton?

    private let gradientLayer = CAGradientLayer()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?

    public init(configuration: FloatingBottomContainerConfiguration) {
        self.configuration = configuration
        self.primaryButton = configuration.primaryButton.map(PrimaryButton.init(configuration:))
        self.secondaryButton = configuration.secondaryButton.map(LinkButton.init(configuration:))
        super.init(frame: .zero)
        setupView()
        apply(configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func apply(configuration: FloatingBottomContainerConfiguration) {
        self.configuration = configuration
        stackView.spacing = configuration.buttonSpacing

        if let primaryButton, let primaryConfiguration = configuration.primaryButton {
            primaryButton.apply(configuration: primaryConfiguration)
        }

        if let secondaryButton, let secondaryConfiguration = configuration.secondaryButton {
            secondaryButton.apply(configuration: secondaryConfiguration)
        }

        leadingConstraint?.constant = configuration.horizontalInset
        trailingConstraint?.constant = -configuration.horizontalInset
        updateGradient()
        updateBottomInset()
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateBottomInset()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        updateGradient()
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews where !subview.isHidden && subview.alpha > 0 {
            let convertedPoint = convert(point, to: subview)
            if subview.point(inside: convertedPoint, with: event) {
                return true
            }
        }

        return false
    }
}

private extension FloatingBottomContainer {
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isOpaque = false

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        addSubview(contentView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        contentView.addSubview(stackView)

        if let primaryButton {
            stackView.addArrangedSubview(primaryButton)
        }

        if let secondaryButton {
            stackView.addArrangedSubview(secondaryButton)
        }

        leadingConstraint = contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingConstraint = contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
        bottomConstraint = contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: contentView.topAnchor),
            leadingConstraint,
            trailingConstraint,
            bottomConstraint,

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ].compactMap { $0 })
    }

    func updateBottomInset() {
        guard let bottomConstraint else { return }

        let additionalBottomInset: CGFloat
        if safeAreaInsets.bottom > 0 {
            additionalBottomInset = max(configuration.bottomInset - safeAreaInsets.bottom, 0)
        } else {
            additionalBottomInset = DesignSpacing.xLarge
        }

        bottomConstraint.constant = -additionalBottomInset
    }

    func updateGradient() {
        guard configuration.gradient.isEnabled else {
            gradientLayer.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor]
            return
        }

        let fadeStartLocation = gradientFadeStartLocation()
        gradientLayer.colors = [
            configuration.gradient.color.withAlphaComponent(0).cgColor,
            configuration.gradient.color.withAlphaComponent(0).cgColor,
            configuration.gradient.color.withAlphaComponent(1).cgColor,
        ]
        gradientLayer.locations = [0, fadeStartLocation as NSNumber, 1]
    }

    func gradientFadeStartLocation() -> NSNumber {
        guard bounds.height > 0 else { return 0.35 }

        let fadeEndY: CGFloat
        if let primaryButton, let primarySuperview = primaryButton.superview {
            fadeEndY = primarySuperview.convert(primaryButton.frame, to: self).maxY
        } else if let secondaryButton, let secondarySuperview = secondaryButton.superview {
            fadeEndY = secondarySuperview.convert(secondaryButton.frame, to: self).minY
        } else {
            fadeEndY = bounds.height * 0.6
        }

        let fadeHeight = max(configuration.gradient.height, 1)
        let fadeStartY = max(fadeEndY - fadeHeight, 0)
        let normalized = min(max(fadeStartY / bounds.height, 0.05), 0.85)
        return NSNumber(value: Double(normalized))
    }
}

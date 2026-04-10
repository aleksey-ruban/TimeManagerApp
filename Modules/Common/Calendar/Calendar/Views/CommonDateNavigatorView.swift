import UIKit
import DesignTokens

@MainActor
public final class CommonDateNavigatorView: UIView, CommonDateNavigatorViewProtocol {
    public var onPreviousDate: (() -> Void)?
    public var onNextDate: (() -> Void)?
    public var onTapDate: (() -> Void)?

    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)
    private let dateButton = UIButton(type: .system)
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func apply(date: Date) {
        dateButton.setTitle(dateFormatter.string(from: date), for: .normal)
    }
}

private extension CommonDateNavigatorView {
    func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 20

        configureButton(leftButton, systemName: "chevron.left", action: #selector(handlePrevious))
        configureButton(rightButton, systemName: "chevron.right", action: #selector(handleNext))

        dateButton.translatesAutoresizingMaskIntoConstraints = false
        dateButton.setTitleColor(DesignColor.accent, for: .normal)
        dateButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        dateButton.titleLabel?.lineBreakMode = .byTruncatingTail
        dateButton.addTarget(self, action: #selector(handleTapDate), for: .touchUpInside)
        addSubview(dateButton)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),

            leftButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            leftButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftButton.widthAnchor.constraint(equalToConstant: 28),
            leftButton.heightAnchor.constraint(equalToConstant: 28),

            rightButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            rightButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightButton.widthAnchor.constraint(equalToConstant: 28),
            rightButton.heightAnchor.constraint(equalToConstant: 28),

            dateButton.leadingAnchor.constraint(greaterThanOrEqualTo: leftButton.trailingAnchor, constant: DesignSpacing.small),
            dateButton.trailingAnchor.constraint(lessThanOrEqualTo: rightButton.leadingAnchor, constant: -DesignSpacing.small),
            dateButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            dateButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    func configureButton(_ button: UIButton, systemName: String, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = DesignColor.accent
        button.setImage(
            UIImage(
                systemName: systemName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            ),
            for: .normal
        )
        button.addTarget(self, action: action, for: .touchUpInside)
        addSubview(button)
    }

    @objc
    func handlePrevious() {
        onPreviousDate?()
    }

    @objc
    func handleNext() {
        onNextDate?()
    }

    @objc
    func handleTapDate() {
        onTapDate?()
    }

    @objc
    func handleSwipeLeft() {
        onNextDate?()
    }

    @objc
    func handleSwipeRight() {
        onPreviousDate?()
    }
}

import UIKit
import DesignTokens

@MainActor
final class CommonCalendarDayButton: UIControl {
    var onTap: (() -> Void)?

    private let circleView = UIView()
    private let dayLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(day: Int, isSelected: Bool, isHighlighted: Bool, isEnabled: Bool) {
        dayLabel.text = "\(day)"
        self.isEnabled = isEnabled

        if isSelected {
            circleView.backgroundColor = DesignColor.accent
            dayLabel.textColor = .white
        } else if isEnabled == false {
            circleView.backgroundColor = .clear
            dayLabel.textColor = DesignColor.textSecondary
        } else if isHighlighted {
            circleView.backgroundColor = DesignColor.backgroundSecondary
            dayLabel.textColor = DesignColor.textPrimary
        } else {
            circleView.backgroundColor = .clear
            dayLabel.textColor = DesignColor.textPrimary
        }
    }
}

private extension CommonCalendarDayButton {
    func setupView() {
        addAction(UIAction { [weak self] _ in
            self?.onTap?()
        }, for: .touchUpInside)

        circleView.layer.cornerRadius = 18
        circleView.isUserInteractionEnabled = false
        addSubview(circleView)

        dayLabel.font = .systemFont(ofSize: 17, weight: .regular)
        dayLabel.textAlignment = .center
        dayLabel.isUserInteractionEnabled = false
        circleView.addSubview(dayLabel)

        circleView.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40),

            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 36),
            circleView.heightAnchor.constraint(equalToConstant: 36),

            dayLabel.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
        ])
    }
}

import UIKit
import DesignTokens

@MainActor
final class PillButtonView: UIControl {
    var onDelete: (() -> Void)?

    private let horizontalInset = DesignSpacing.medium
    private let verticalInset = DesignSpacing.small
    private let titleLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private let stackView = UIStackView()

    init(title: String, isSelected: Bool, showsDelete: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 16
        layer.borderWidth = 1
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = DesignSpacing.small
        stackView.alignment = .center
        addSubview(stackView)

        titleLabel.font = DesignTypography.labelRegular13.font
        titleLabel.text = title
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.isUserInteractionEnabled = false
        stackView.addArrangedSubview(titleLabel)

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        deleteButton.tintColor = DesignColor.textSecondary
        deleteButton.isHidden = showsDelete == false
        deleteButton.isUserInteractionEnabled = true
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        stackView.addArrangedSubview(deleteButton)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: verticalInset),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalInset),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalInset),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -verticalInset),
            deleteButton.widthAnchor.constraint(equalToConstant: 14),
            deleteButton.heightAnchor.constraint(equalToConstant: 14),
        ])

        applySelection(isSelected)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applySelection(_ isSelected: Bool) {
        backgroundColor = isSelected ? DesignColor.buttonPrimary : DesignColor.backgroundSecondary
        layer.borderColor = (isSelected ? DesignColor.buttonPrimary : DesignColor.secondary).cgColor
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        let titleSize = titleLabel.intrinsicContentSize
        let deleteWidth: CGFloat = deleteButton.isHidden ? 0 : (DesignSpacing.small + 14)
        let width = horizontalInset * 2 + titleSize.width + deleteWidth
        let height = verticalInset * 2 + max(titleSize.height, 14)
        return CGSize(width: ceil(width), height: ceil(height))
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if bounds.contains(point) {
            return true
        }

        guard deleteButton.isHidden == false else {
            return false
        }

        let deletePoint = convert(point, to: deleteButton)
        return deleteButton.bounds.insetBy(dx: -8, dy: -8).contains(deletePoint)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, isHidden == false, alpha > 0.01, self.point(inside: point, with: event) else {
            return nil
        }

        if deleteButton.isHidden == false {
            let deletePoint = convert(point, to: deleteButton)
            if deleteButton.bounds.insetBy(dx: -8, dy: -8).contains(deletePoint) {
                return deleteButton
            }
        }

        return self
    }

    @objc
    private func handleDelete() {
        onDelete?()
    }
}

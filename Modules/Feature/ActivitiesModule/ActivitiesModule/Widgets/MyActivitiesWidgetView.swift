import UIKit
import DesignSystem
import DesignTokens
import SnapKit

@MainActor
public final class MyActivitiesWidgetView: UIView {
    private let onOpen: () -> Void

    private let tapButton = UIButton(type: .system)
    private let iconView = UIImageView(image: UIImage(named: "MyTasks"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let labelsStackView = UIStackView()

    init(onOpen: @escaping () -> Void) {
        self.onOpen = onOpen
        super.init(frame: .zero)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension MyActivitiesWidgetView {
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 24
        DesignShadow.applyWidgetShadow(to: self)

        snp.makeConstraints { make in
            make.height.equalTo(81)
        }

        tapButton.backgroundColor = .clear
        tapButton.addAction(UIAction { [weak self] _ in
            self?.onOpen()
        }, for: .touchUpInside)
        addSubview(tapButton)

        iconView.tintColor = nil
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)

        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading
        labelsStackView.spacing = 5
        addSubview(labelsStackView)

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.text = "Мои задачи"
        labelsStackView.addArrangedSubview(titleLabel)

        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = DesignColor.textPrimary
        subtitleLabel.text = "Ваши дела в одном месте"
        labelsStackView.addArrangedSubview(subtitleLabel)

        tapButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.lessThanOrEqualTo(CGSize(width: 40, height: 40))
        }

        labelsStackView.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        bringSubviewToFront(tapButton)
    }
}

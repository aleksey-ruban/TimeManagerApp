import UIKit
import DesignSystem
import DesignTokens
import SnapKit

@MainActor
public final class MyActivitiesWidgetView: UIView {
    private let onOpen: () -> Void

    private let tapButton = UIButton(type: .system)
    private let iconContainerView = UIView()
    private let iconView = UIImageView(image: UIImage(systemName: "checklist"))
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

        iconContainerView.backgroundColor = UIColor(red: 0.20, green: 0.55, blue: 0.98, alpha: 1)
        iconContainerView.layer.cornerRadius = 20
        addSubview(iconContainerView)

        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconContainerView.addSubview(iconView)

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

        iconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 40, height: 40))
        }

        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 22, height: 22))
        }

        labelsStackView.snp.makeConstraints { make in
            make.leading.equalTo(iconContainerView.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        bringSubviewToFront(tapButton)
    }
}

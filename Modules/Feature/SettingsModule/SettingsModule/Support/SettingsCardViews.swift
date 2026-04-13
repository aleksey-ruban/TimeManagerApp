import DesignSystem
import DesignTokens
import SnapKit
import UIKit

@MainActor
final class SettingsAvatarView: UIView {
    private let imageView = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SettingsAvatarView {
    func setupView() {
        backgroundColor = DesignColor.backgroundSecondary
        layer.cornerRadius = 28

        isUserInteractionEnabled = false
        imageView.tintColor = DesignColor.iconTint
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)

        snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 56, height: 56))
        }

        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 28, height: 28))
        }
    }
}

@MainActor
final class SettingsProfileCardButton: UIControl {
    private let avatarView = SettingsAvatarView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(name: String, email: String) {
        titleLabel.text = name
        subtitleLabel.text = email
    }
}

private extension SettingsProfileCardButton {
    func setupView() {
        SettingsCardStyling.apply(to: self)

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.isUserInteractionEnabled = false

        subtitleLabel.font = DesignTypography.bodyRegular15.font
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.isUserInteractionEnabled = false

        chevronImageView.tintColor = DesignColor.iconTint
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.isUserInteractionEnabled = false

        let labelsStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelsStackView.axis = .vertical
        labelsStackView.spacing = DesignSpacing.xSmall
        labelsStackView.isUserInteractionEnabled = false

        addSubview(avatarView)
        addSubview(labelsStackView)
        addSubview(chevronImageView)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(DesignSpacing.large)
            make.centerY.equalToSuperview()
        }

        labelsStackView.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(DesignSpacing.medium)
            make.top.bottom.equalToSuperview().inset(DesignSpacing.large)
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-DesignSpacing.small)
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(DesignSpacing.large)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 12, height: 18))
        }
    }
}

@MainActor
final class SettingsFeatureCardButton: UIControl {
    private let iconContainerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(symbolName: String, title: String, subtitle: String) {
        iconImageView.image = UIImage(systemName: symbolName)
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}

private extension SettingsFeatureCardButton {
    func setupView() {
        SettingsCardStyling.apply(to: self)

        iconContainerView.backgroundColor = DesignColor.backgroundSecondary
        iconContainerView.layer.cornerRadius = 22
        iconContainerView.isUserInteractionEnabled = false

        iconImageView.tintColor = DesignColor.accent
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.isUserInteractionEnabled = false

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.isUserInteractionEnabled = false

        subtitleLabel.font = DesignTypography.bodyRegular15.font
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.isUserInteractionEnabled = false

        chevronImageView.tintColor = DesignColor.iconTint
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.isUserInteractionEnabled = false

        let labelsStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelsStackView.axis = .vertical
        labelsStackView.spacing = DesignSpacing.xSmall
        labelsStackView.isUserInteractionEnabled = false

        addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        addSubview(labelsStackView)
        addSubview(chevronImageView)

        iconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(DesignSpacing.large)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 22, height: 22))
        }

        labelsStackView.snp.makeConstraints { make in
            make.leading.equalTo(iconContainerView.snp.trailing).offset(DesignSpacing.medium)
            make.top.bottom.equalToSuperview().inset(DesignSpacing.large)
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-DesignSpacing.small)
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(DesignSpacing.large)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 12, height: 18))
        }
    }
}

@MainActor
final class SettingsSessionCardView: UIView {
    struct ViewModel {
        let title: String
        let badgeText: String?
        let createdAtText: String
        let lastUsedAtText: String
        let showsLogoutAction: Bool
    }

    var onLogoutTap: (() -> Void)?

    private let contentStackView = UIStackView()
    private let titleLabel = UILabel()
    private let badgeContainerView = UIView()
    private let badgeLabel = UILabel()
    private let createdAtLabel = UILabel()
    private let lastUsedAtLabel = UILabel()
    private let actionButton = LinkButton(
        configuration: .init(
            title: "Завершить сессию",
            appearance: .init(
                titleColor: DesignColor.destructive,
                titleFont: DesignTypography.bodyRegular16.font
            )
        )
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ViewModel) {
        titleLabel.text = viewModel.title
        badgeLabel.text = viewModel.badgeText
        badgeContainerView.isHidden = viewModel.badgeText == nil
        createdAtLabel.text = viewModel.createdAtText
        lastUsedAtLabel.text = viewModel.lastUsedAtText
        actionButton.isHidden = !viewModel.showsLogoutAction
    }
}

private extension SettingsSessionCardView {
    func setupView() {
        SettingsCardStyling.apply(to: self, cornerRadius: 24)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.medium

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.numberOfLines = 0

        badgeContainerView.backgroundColor = DesignColor.backgroundSecondary
        badgeContainerView.layer.cornerRadius = 12
        badgeContainerView.isHidden = true

        badgeLabel.font = DesignTypography.labelRegular13.font
        badgeLabel.textColor = DesignColor.textSecondary

        createdAtLabel.font = DesignTypography.bodyRegular15.font
        createdAtLabel.textColor = DesignColor.textSecondary
        createdAtLabel.numberOfLines = 0

        lastUsedAtLabel.font = DesignTypography.bodyRegular15.font
        lastUsedAtLabel.textColor = DesignColor.textSecondary
        lastUsedAtLabel.numberOfLines = 0

        actionButton.onTap = { [weak self] in
            self?.onLogoutTap?()
        }

        addSubview(contentStackView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(badgeContainerView)
        badgeContainerView.addSubview(badgeLabel)
        contentStackView.addArrangedSubview(createdAtLabel)
        contentStackView.addArrangedSubview(lastUsedAtLabel)
        contentStackView.addArrangedSubview(actionButton)

        badgeContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
        }

        badgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10))
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(DesignSpacing.large)
        }
    }
}

enum SettingsCardStyling {
    @MainActor
    static func apply(to view: UIView, cornerRadius: CGFloat = 28) {
        view.backgroundColor = .white
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        DesignShadow.applyWidgetShadow(to: view)
    }
}

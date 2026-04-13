import DesignSystem
import DesignTokens
import SnapKit
import UIKit

@MainActor
final class SettingsProfileEditViewController: BaseViewController, SettingsProfileEditView {
    private let presenter: SettingsProfileEditPresenting

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let identityCardView = UIView()
    private let avatarView = SettingsAvatarView()
    private let currentNameLabel = UILabel()
    private let currentEmailLabel = UILabel()
    private let nameField = CommonTextField(
        configuration: .init(
            hint: "Имя",
            showsDoneAccessory: false
        )
    )
    private let emailField = CommonTextField(
        configuration: .init(
            hint: "Почта",
            kind: .email,
            isEnabled: false,
            showsClearButton: false
        )
    )
    private let noteLabel = UILabel()
    private let bottomContainer = FloatingBottomContainer(
        configuration: .init(
            primaryButton: .init(title: "Сохранить", isEnabled: false),
            secondaryButton: .init(
                title: "Удалить аккаунт",
                appearance: .init(
                    titleColor: DesignColor.destructive,
                    titleFont: DesignTypography.bodyRegular16.font
                )
            )
        )
    )

    init(presenter: SettingsProfileEditPresenting) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollInsets()
    }

    func render(viewModel: SettingsProfileEditViewModel) {
        currentNameLabel.text = viewModel.currentName
        currentEmailLabel.text = viewModel.currentEmail
        nameField.apply(
            configuration: .init(
                hint: "Имя",
                text: viewModel.editableName,
                isEnabled: !viewModel.isLoading,
                showsDoneAccessory: false
            )
        )
        emailField.apply(
            configuration: .init(
                hint: "Почта",
                kind: .email,
                text: viewModel.email,
                isEnabled: false,
                showsClearButton: false
            )
        )
        noteLabel.alpha = viewModel.isLoading ? 0.6 : 1
        bottomContainer.primaryButton?.isEnabled = viewModel.isSaveEnabled
        bottomContainer.secondaryButton?.isEnabled = !viewModel.isLoading
    }

    func showDeleteAccountConfirmation() {
        let alert = UIAlertController(
            title: "Удалить аккаунт",
            message: "Аккаунт будет удалён без возможности восстановления. Локальные данные приложения на устройстве тоже будут очищены.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.presenter.didConfirmDeleteAccount()
        })
        present(alert, animated: true)
    }

    func showError(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func close() {
        navigationController?.popViewController(animated: true)
    }
}

private extension SettingsProfileEditViewController {
    func setupView() {
        navigationItem.title = "Профиль"
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        configureIdentityCard()

        noteLabel.font = DesignTypography.bodyRegular15.font
        noteLabel.textColor = DesignColor.textSecondary
        noteLabel.numberOfLines = 0
        noteLabel.text = "Аватар и почта доступны только для просмотра. Изменить можно только имя аккаунта."

        contentStackView.addArrangedSubview(identityCardView)
        contentStackView.addArrangedSubview(nameField)
        contentStackView.addArrangedSubview(emailField)
        contentStackView.addArrangedSubview(noteLabel)

        nameField.onTextChanged = { [weak self] text in
            self?.presenter.didUpdateName(text)
        }

        bottomContainer.primaryButton?.onTap = { [weak self] in
            self?.presenter.didTapSave()
        }
        bottomContainer.secondaryButton?.onTap = { [weak self] in
            self?.presenter.didTapDeleteAccount()
        }
        view.addSubview(bottomContainer)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(DesignSpacing.large)
            make.leading.equalTo(scrollView.frameLayoutGuide).offset(DesignSpacing.large)
            make.trailing.equalTo(scrollView.frameLayoutGuide).inset(DesignSpacing.large)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(DesignSpacing.xxLarge)
        }

        bottomContainer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configureIdentityCard() {
        SettingsCardStyling.apply(to: identityCardView)

        currentNameLabel.font = DesignTypography.bodyMedium17.font
        currentNameLabel.textColor = DesignColor.textPrimary

        currentEmailLabel.font = DesignTypography.bodyRegular15.font
        currentEmailLabel.textColor = DesignColor.textSecondary
        currentEmailLabel.numberOfLines = 0

        let labelsStackView = UIStackView(arrangedSubviews: [currentNameLabel, currentEmailLabel])
        labelsStackView.axis = .vertical
        labelsStackView.spacing = DesignSpacing.xSmall

        identityCardView.addSubview(avatarView)
        identityCardView.addSubview(labelsStackView)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(DesignSpacing.large)
            make.centerY.equalToSuperview()
        }

        labelsStackView.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(DesignSpacing.medium)
            make.top.bottom.trailing.equalToSuperview().inset(DesignSpacing.large)
        }
    }

    func updateScrollInsets() {
        let bottomInset = bottomContainer.bounds.height + DesignSpacing.xLarge
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
}

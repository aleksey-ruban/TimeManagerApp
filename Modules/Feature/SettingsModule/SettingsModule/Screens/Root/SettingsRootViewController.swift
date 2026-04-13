import DesignSystem
import DesignTokens
import SnapKit
import UIKit

@MainActor
final class SettingsRootViewController: BaseViewController, SettingsRootView {
    private let presenter: SettingsRootPresenting

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let profileCardButton = SettingsProfileCardButton()
    private let securityCardButton = SettingsFeatureCardButton()
    private let logoutButton = LinkButton(
        configuration: .init(
            title: "Выйти из аккаунта",
            appearance: .init(
                titleColor: DesignColor.destructive,
                titleFont: DesignTypography.bodyRegular16.font
            )
        )
    )

    private var isLoadingState = false {
        didSet {
            profileCardButton.isEnabled = !isLoadingState
            securityCardButton.isEnabled = !isLoadingState
            logoutButton.isEnabled = !isLoadingState
        }
    }

    init(presenter: SettingsRootPresenting) {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollInsets()
    }

    func render(viewModel: SettingsRootViewModel) {
        profileCardButton.apply(name: viewModel.profileName, email: viewModel.profileEmail)
    }

    func setLoading(_ isLoading: Bool) {
        isLoadingState = isLoading
    }

    func showLogoutConfirmation() {
        let alert = UIAlertController(
            title: "Выйти из аккаунта",
            message: "Текущая сессия будет завершена на устройстве, а локальные данные приложения будут удалены.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            self?.presenter.didConfirmLogout()
        })
        present(alert, animated: true)
    }

    func showError(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private extension SettingsRootViewController {
    func setupView() {
        navigationItem.title = "Настройки"
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        securityCardButton.apply(
            symbolName: "shield.fill",
            title: "Безопасность аккаунта",
            subtitle: "Активные сессии, завершение входа на отдельных устройствах и выход на остальных."
        )

        profileCardButton.addTarget(self, action: #selector(handleOpenProfile), for: .touchUpInside)
        securityCardButton.addTarget(self, action: #selector(handleOpenSecurity), for: .touchUpInside)

        contentStackView.addArrangedSubview(profileCardButton)
        contentStackView.addArrangedSubview(securityCardButton)
        contentStackView.addArrangedSubview(makeLogoutSpacerView())
        contentStackView.addArrangedSubview(logoutButton)

        logoutButton.onTap = { [weak self] in
            self?.presenter.didTapLogout()
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(DesignSpacing.large)
            make.leading.equalTo(scrollView.frameLayoutGuide).offset(DesignSpacing.large)
            make.trailing.equalTo(scrollView.frameLayoutGuide).inset(DesignSpacing.large)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(DesignSpacing.xLarge)
        }
    }

    func updateScrollInsets() {
        scrollView.contentInset.bottom = DesignSpacing.xLarge
        scrollView.verticalScrollIndicatorInsets.bottom = DesignSpacing.xLarge
    }

    func makeLogoutSpacerView() -> UIView {
        let spacerView = UIView()
        spacerView.isUserInteractionEnabled = false
        spacerView.snp.makeConstraints { make in
            make.height.equalTo(DesignSpacing.small)
        }
        return spacerView
    }

    @objc
    func handleOpenProfile() {
        presenter.didTapProfile()
    }

    @objc
    func handleOpenSecurity() {
        presenter.didTapSecurity()
    }
}

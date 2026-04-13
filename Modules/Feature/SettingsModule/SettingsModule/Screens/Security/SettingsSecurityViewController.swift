import DesignSystem
import DesignTokens
import SnapKit
import UIKit

@MainActor
final class SettingsSecurityViewController: BaseViewController, SettingsSecurityView {
    private let presenter: SettingsSecurityPresenting

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let descriptionLabel = UILabel()
    private let sessionsStackView = UIStackView()
    private let emptyLabel = UILabel()
    private let bottomContainer = FloatingBottomContainer(
        configuration: .init(
            primaryButton: .init(title: "Выйти на других устройствах", isEnabled: false)
        )
    )

    private var sessionItems: [SettingsSecuritySessionItemViewModel] = []

    init(presenter: SettingsSecurityPresenting) {
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

    func render(viewModel: SettingsSecurityViewModel) {
        descriptionLabel.text = viewModel.descriptionText
        emptyLabel.text = viewModel.emptyStateText
        bottomContainer.primaryButton?.isEnabled = viewModel.isLogoutOthersEnabled
        sessionItems = viewModel.sessionItems
        rebuildSessionCards()
    }

    func showLogoutDeviceConfirmation(deviceName: String) {
        let alert = UIAlertController(
            title: "Завершить сессию",
            message: "Устройство «\(deviceName)» будет разлогинено.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Разлогинить", style: .destructive) { [weak self] _ in
            self?.presenter.didConfirmLogoutDevice()
        })
        present(alert, animated: true)
    }

    func showLogoutOthersConfirmation() {
        let alert = UIAlertController(
            title: "Выйти на других устройствах",
            message: "Будут завершены все активные сессии кроме текущей.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Подтвердить", style: .destructive) { [weak self] _ in
            self?.presenter.didConfirmLogoutOthers()
        })
        present(alert, animated: true)
    }

    func showError(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private extension SettingsSecurityViewController {
    func setupView() {
        navigationItem.title = "Безопасность"
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        descriptionLabel.font = DesignTypography.bodyRegular15.font
        descriptionLabel.textColor = DesignColor.textSecondary
        descriptionLabel.numberOfLines = 0

        sessionsStackView.axis = .vertical
        sessionsStackView.spacing = DesignSpacing.medium

        emptyLabel.font = DesignTypography.bodyRegular15.font
        emptyLabel.textColor = DesignColor.textSecondary
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        contentStackView.addArrangedSubview(descriptionLabel)
        contentStackView.addArrangedSubview(sessionsStackView)
        contentStackView.addArrangedSubview(emptyLabel)

        bottomContainer.primaryButton?.onTap = { [weak self] in
            self?.presenter.didTapLogoutOthers()
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

    func rebuildSessionCards() {
        sessionsStackView.arrangedSubviews.forEach {
            sessionsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        emptyLabel.isHidden = sessionItems.isEmpty == false

        for (index, item) in sessionItems.enumerated() {
            let cardView = SettingsSessionCardView()
            cardView.apply(
                viewModel: .init(
                    title: item.title,
                    badgeText: item.badgeText,
                    createdAtText: item.createdAtText,
                    lastUsedAtText: item.lastUsedAtText,
                    showsLogoutAction: item.showsLogoutAction
                )
            )
            cardView.onLogoutTap = { [weak self] in
                self?.presenter.didTapLogoutDevice(at: index)
            }
            sessionsStackView.addArrangedSubview(cardView)
        }
    }

    func updateScrollInsets() {
        let bottomInset = bottomContainer.bounds.height + DesignSpacing.xLarge
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
}

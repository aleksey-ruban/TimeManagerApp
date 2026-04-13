import UIKit
import CoreAuth
import DesignSystem
import DesignTokens

@MainActor
final class MainSettingsViewController: UIViewController {
    private let authFeatureService: AuthFeatureServiceProtocol
    private let onLogout: () -> Void

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let heroCardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let logoutButton = PrimaryButton(
        configuration: .init(title: "Выйти из аккаунта")
    )

    init(
        authFeatureService: AuthFeatureServiceProtocol,
        onLogout: @escaping () -> Void
    ) {
        self.authFeatureService = authFeatureService
        self.onLogout = onLogout
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
}

private extension MainSettingsViewController {
    func setupView() {
        navigationItem.title = "Настройки"
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        heroCardView.translatesAutoresizingMaskIntoConstraints = false
        heroCardView.backgroundColor = DesignColor.backgroundSecondary
        heroCardView.layer.cornerRadius = 28
        heroCardView.layer.cornerCurve = .continuous

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DesignTypography.displaySemibold32.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.text = "Параметры приложения"

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = DesignTypography.bodyRegular16.font
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "Этот таб зарезервирован под настройки, управление сессией и будущие пользовательские параметры."

        logoutButton.onTap = { [weak self] in
            self?.handleLogout()
        }

        contentStackView.addArrangedSubview(heroCardView)
        contentStackView.addArrangedSubview(logoutButton)

        heroCardView.addSubview(titleLabel)
        heroCardView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: DesignSpacing.xxLarge),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: DesignSpacing.large),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -DesignSpacing.large),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -DesignSpacing.xxLarge),

            heroCardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),

            titleLabel.topAnchor.constraint(equalTo: heroCardView.topAnchor, constant: DesignSpacing.xLarge),
            titleLabel.leadingAnchor.constraint(equalTo: heroCardView.leadingAnchor, constant: DesignSpacing.xLarge),
            titleLabel.trailingAnchor.constraint(equalTo: heroCardView.trailingAnchor, constant: -DesignSpacing.xLarge),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DesignSpacing.small),
            subtitleLabel.leadingAnchor.constraint(equalTo: heroCardView.leadingAnchor, constant: DesignSpacing.xLarge),
            subtitleLabel.trailingAnchor.constraint(equalTo: heroCardView.trailingAnchor, constant: -DesignSpacing.xLarge),
            subtitleLabel.bottomAnchor.constraint(equalTo: heroCardView.bottomAnchor, constant: -DesignSpacing.xLarge),
        ])
    }

    func handleLogout() {
        Task { [weak self] in
            guard let self else { return }

            do {
                try await authFeatureService.logout()
                await MainActor.run {
                    self.onLogout()
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: nil,
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

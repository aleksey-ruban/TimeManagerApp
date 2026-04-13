import UIKit
import DesignSystem
import DesignTokens
import CoreAuth

@MainActor
final class MainPlaceholderViewController: UIViewController {
    private let authFeatureService: AuthFeatureServiceProtocol
    private let onLogout: () -> Void

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = DesignTypography.displaySemibold32.font
        label.textColor = DesignColor.textPrimary
        label.numberOfLines = 0
        label.text = "Main Flow Placeholder"
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = DesignTypography.bodyRegular15.font
        label.textColor = DesignColor.textSecondary
        label.numberOfLines = 0
        label.text = "AppCoordinator routed the user into the main application flow. Replace this screen with real app navigation."
        return label
    }()

    private let logoutButton = PrimaryButton(
        configuration: .init(
            title: "Log out"
        )
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
        title = "Time Manager"
        view.backgroundColor = DesignColor.backgroundPrimary
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(logoutButton)

        logoutButton.onTap = { [weak self] in
            self?.handleLogout()
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DesignSpacing.xxLarge),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSpacing.large),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSpacing.large),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DesignSpacing.small),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSpacing.large),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSpacing.large),

            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSpacing.large),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSpacing.large),
            logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DesignSpacing.xxLarge),
        ])
    }

    private func handleLogout() {
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
                        title: "Error",
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

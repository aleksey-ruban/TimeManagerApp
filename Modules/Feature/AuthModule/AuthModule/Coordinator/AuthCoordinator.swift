import UIKit
import CoreAuth

@MainActor
final class AuthCoordinator: AuthCoordinatorProtocol {
    private let navigationController: UINavigationController
    private let flowService: AuthFlowServiceProtocol
    private let authFeatureService: AuthFeatureServiceProtocol
    private let localeProvider: AuthLocaleProviding
    private let codeResendDateProvider: AuthCodeResendDateProviding
    private let onAuthorized: (() -> Void)?

    init(
        navigationController: UINavigationController,
        flowService: AuthFlowServiceProtocol,
        authFeatureService: AuthFeatureServiceProtocol,
        localeProvider: AuthLocaleProviding,
        codeResendDateProvider: AuthCodeResendDateProviding,
        onAuthorized: (() -> Void)?
    ) {
        self.navigationController = navigationController
        self.flowService = flowService
        self.authFeatureService = authFeatureService
        self.localeProvider = localeProvider
        self.codeResendDateProvider = codeResendDateProvider
        self.onAuthorized = onAuthorized
    }

    func start() {
        navigationController.setViewControllers([makeEmailEntryScreen()], animated: false)
    }
}

private extension AuthCoordinator {
    func makeEmailEntryScreen() -> UIViewController {
        let presenter = AuthEmailEntryPresenter(
            flowService: flowService,
            localeProvider: localeProvider,
            onRouteToLogin: { [weak self] email in
                self?.showLoginScreen(email: email)
            },
            onRouteToRegistrationCode: { [weak self] email, _ in
                self?.presentCodeVerification(
                    flow: .registration,
                    email: email,
                    resendAvailableAt: self?.codeResendDateProvider.makeResendAvailableAt()
                )
            }
        )

        let viewController = AuthEmailEntryViewController(presenter: presenter)
        presenter.view = viewController
        return viewController
    }

    func showLoginScreen(email: String) {
        let presenter = AuthLoginPasswordPresenter(
            email: email,
            flowService: flowService,
            authFeatureService: authFeatureService,
            localeProvider: localeProvider,
            onStartPasswordReset: { [weak self] email, _ in
                self?.presentCodeVerification(
                    flow: .passwordReset,
                    email: email,
                    resendAvailableAt: self?.codeResendDateProvider.makeResendAvailableAt()
                )
            },
            onAuthorized: { [weak self] in
                self?.onAuthorized?()
            }
        )

        let viewController = AuthLoginPasswordViewController(email: email, presenter: presenter)
        presenter.view = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func showRegistrationScreen(email: String) {
        let presenter = AuthRegistrationPresenter(
            email: email,
            flowService: flowService,
            authFeatureService: authFeatureService,
            onAuthorized: { [weak self] in
                self?.onAuthorized?()
            }
        )

        let viewController = AuthRegistrationViewController(
            email: email,
            presenter: presenter
        )
        presenter.view = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func showPasswordResetScreen(email: String) {
        let presenter = AuthPasswordResetPresenter(
            email: email,
            flowService: flowService,
            authFeatureService: authFeatureService,
            onAuthorized: { [weak self] in
                self?.onAuthorized?()
            }
        )

        let viewController = AuthPasswordResetViewController(
            email: email,
            presenter: presenter
        )
        presenter.view = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func presentCodeVerification(
        flow: AuthVerificationFlow,
        email: String,
        resendAvailableAt: Date?
    ) {
        let presenter = AuthCodeVerificationPresenter(
            flow: flow,
            email: email,
            resendAvailableAt: resendAvailableAt,
            flowService: flowService,
            localeProvider: localeProvider,
            onClose: { [weak self] in
                self?.navigationController.presentedViewController?.dismiss(animated: true)
            },
            onVerified: { [weak self] email in
                self?.navigationController.presentedViewController?.dismiss(animated: true) {
                    guard let self else { return }

                    switch flow {
                    case .registration:
                        self.showRegistrationScreen(email: email)
                    case .passwordReset:
                        self.showPasswordResetScreen(email: email)
                    }
                }
            }
        )

        let viewController = AuthCodeVerificationViewController(
            flow: flow,
            email: email,
            presenter: presenter
        )
        presenter.view = viewController

        let modalNavigationController = UINavigationController(rootViewController: viewController)
        modalNavigationController.modalPresentationStyle = .pageSheet

        if let sheet = modalNavigationController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        navigationController.present(modalNavigationController, animated: true)
    }
}

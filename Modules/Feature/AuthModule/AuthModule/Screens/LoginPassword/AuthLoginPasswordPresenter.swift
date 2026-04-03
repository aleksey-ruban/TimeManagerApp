import Foundation
import CoreAuth

@MainActor
protocol AuthLoginPasswordView: AnyObject {
    func setPrimaryActionEnabled(_ isEnabled: Bool)
    func setLoading(_ isLoading: Bool)
    func showError(message: String)
}

@MainActor
final class AuthLoginPasswordPresenter {
    weak var view: AuthLoginPasswordView?

    private let email: String
    private let flowService: AuthFlowServiceProtocol
    private let authFeatureService: AuthFeatureServiceProtocol
    private let localeProvider: AuthLocaleProviding
    private let onStartPasswordReset: (String, String?) -> Void
    private let onAuthorized: () -> Void

    private var password = ""

    init(
        email: String,
        flowService: AuthFlowServiceProtocol,
        authFeatureService: AuthFeatureServiceProtocol,
        localeProvider: AuthLocaleProviding,
        onStartPasswordReset: @escaping (String, String?) -> Void,
        onAuthorized: @escaping () -> Void
    ) {
        self.email = email
        self.flowService = flowService
        self.authFeatureService = authFeatureService
        self.localeProvider = localeProvider
        self.onStartPasswordReset = onStartPasswordReset
        self.onAuthorized = onAuthorized
    }

    func viewDidLoad() {
        updatePrimaryActionState()
    }

    func didUpdatePassword(_ password: String) {
        self.password = password
        updatePrimaryActionState()
    }

    func didTapLogin() {
        guard canSubmit else { return }

        view?.setLoading(true)

        Task { [weak self] in
            guard let self else { return }

            do {
                try await self.authFeatureService.login(
                    email: self.email,
                    password: self.password
                )

                self.handleSuccess()
            } catch {
                self.handleFailure(error)
            }
        }
    }

    func didTapForgotPassword() {
        view?.setLoading(true)

        Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await self.flowService.startPasswordReset(
                    email: self.email,
                    locale: self.localeProvider.localeCode()
                )

                self.handlePasswordResetStarted(expiresAt: response.expiresAt)
            } catch {
                self.handleFailure(error)
            }
        }
    }
}

extension AuthLoginPasswordPresenter: AuthLoginPasswordPresenting {}

private extension AuthLoginPasswordPresenter {
    var canSubmit: Bool {
        password.count >= 6
    }

    func updatePrimaryActionState() {
        view?.setPrimaryActionEnabled(canSubmit)
    }

    func handleSuccess() {
        view?.setLoading(false)
        onAuthorized()
    }

    func handlePasswordResetStarted(expiresAt: String?) {
        view?.setLoading(false)
        onStartPasswordReset(email, expiresAt)
    }

    func handleFailure(_ error: Error) {
        view?.setLoading(false)
        view?.showError(message: AuthFeatureErrorFormatter.message(for: error))
    }
}

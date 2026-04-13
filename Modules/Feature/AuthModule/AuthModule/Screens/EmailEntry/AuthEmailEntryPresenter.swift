import Foundation

@MainActor
protocol AuthEmailEntryView: AnyObject {
    func setPrimaryActionEnabled(_ isEnabled: Bool)
    func setLoading(_ isLoading: Bool)
    func showError(message: String)
}

@MainActor
final class AuthEmailEntryPresenter {
    weak var view: AuthEmailEntryView?

    private let flowService: AuthFlowServiceProtocol
    private let localeProvider: AuthLocaleProviding
    private let onRouteToLogin: (String) -> Void
    private let onRouteToRegistrationCode: (String, String?) -> Void

    private var email = ""

    init(
        flowService: AuthFlowServiceProtocol,
        localeProvider: AuthLocaleProviding,
        onRouteToLogin: @escaping (String) -> Void,
        onRouteToRegistrationCode: @escaping (String, String?) -> Void
    ) {
        self.flowService = flowService
        self.localeProvider = localeProvider
        self.onRouteToLogin = onRouteToLogin
        self.onRouteToRegistrationCode = onRouteToRegistrationCode
    }

    func didUpdateEmail(_ email: String) {
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        view?.setPrimaryActionEnabled(isValidEmail)
    }

    func didTapContinue() {
        guard isValidEmail else { return }

        view?.setLoading(true)

        Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await self.flowService.start(
                    email: self.email,
                    locale: self.localeProvider.localeCode()
                )
                self.handleStartResponse(response)
            } catch {
                self.handleFailure(error)
            }
        }
    }
}

extension AuthEmailEntryPresenter: AuthEmailEntryPresenting {}

private extension AuthEmailEntryPresenter {
    var isValidEmail: Bool {
        email.contains("@") && email.contains(".")
    }

    func handleStartResponse(_ response: AuthStartResponse) {
        view?.setLoading(false)

        switch response.action {
        case .login:
            onRouteToLogin(email)
        case .registration:
            onRouteToRegistrationCode(email, response.expiresAt)
        }
    }

    func handleFailure(_ error: Error) {
        view?.setLoading(false)
        view?.showError(message: AuthFeatureErrorFormatter.message(for: error))
    }
}

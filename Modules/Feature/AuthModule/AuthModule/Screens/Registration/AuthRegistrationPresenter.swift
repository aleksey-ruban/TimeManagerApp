import Foundation
import CoreAuth

@MainActor
protocol AuthRegistrationView: AnyObject {
    func setPrimaryActionEnabled(_ isEnabled: Bool)
    func setLoading(_ isLoading: Bool)
    func showError(message: String)
}

@MainActor
final class AuthRegistrationPresenter {
    weak var view: AuthRegistrationView?

    private let email: String
    private let flowService: AuthFlowServiceProtocol
    private let authFeatureService: AuthFeatureServiceProtocol
    private let onAuthorized: () -> Void

    private var firstName = ""
    private var password = ""

    init(
        email: String,
        flowService: AuthFlowServiceProtocol,
        authFeatureService: AuthFeatureServiceProtocol,
        onAuthorized: @escaping () -> Void
    ) {
        self.email = email
        self.flowService = flowService
        self.authFeatureService = authFeatureService
        self.onAuthorized = onAuthorized
    }

    func viewDidLoad() {
        updatePrimaryActionState()
    }

    func didUpdateFirstName(_ firstName: String) {
        self.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatePrimaryActionState()
    }

    func didUpdatePassword(_ password: String) {
        self.password = password
        updatePrimaryActionState()
    }

    func didTapContinue() {
        guard canSubmit else { return }

        view?.setLoading(true)

        Task { [weak self] in
            guard let self else { return }

            do {
                try await self.flowService.completeRegistration(
                    email: self.email,
                    firstName: self.firstName,
                    password: self.password
                )
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
}

extension AuthRegistrationPresenter: AuthRegistrationPresenting {}

private extension AuthRegistrationPresenter {
    var canSubmit: Bool {
        firstName.isEmpty == false && password.count >= 6
    }

    func updatePrimaryActionState() {
        view?.setPrimaryActionEnabled(canSubmit)
    }

    func handleSuccess() {
        view?.setLoading(false)
        onAuthorized()
    }

    func handleFailure(_ error: Error) {
        view?.setLoading(false)
        view?.showError(message: AuthFeatureErrorFormatter.message(for: error))
    }
}

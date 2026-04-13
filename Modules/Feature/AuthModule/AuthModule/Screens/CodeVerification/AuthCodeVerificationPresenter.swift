import Foundation

@MainActor
protocol AuthCodeVerificationView: AnyObject {
    func updatePrimaryButton(title: String, isEnabled: Bool)
    func setLoading(_ isLoading: Bool)
    func showError(message: String)
}

@MainActor
final class AuthCodeVerificationPresenter {
    weak var view: AuthCodeVerificationView?

    private let flow: AuthVerificationFlow
    private let email: String
    private let flowService: AuthFlowServiceProtocol
    private let localeProvider: AuthLocaleProviding
    private let onClose: () -> Void
    private let onVerified: (String) -> Void

    private var code = ""
    private var resendAvailableAt: Date?
    private var countdownTask: Task<Void, Never>?
    private var isLoading = false

    init(
        flow: AuthVerificationFlow,
        email: String,
        resendAvailableAt: Date?,
        flowService: AuthFlowServiceProtocol,
        localeProvider: AuthLocaleProviding,
        onClose: @escaping () -> Void,
        onVerified: @escaping (String) -> Void
    ) {
        self.flow = flow
        self.email = email
        self.resendAvailableAt = resendAvailableAt
        self.flowService = flowService
        self.localeProvider = localeProvider
        self.onClose = onClose
        self.onVerified = onVerified
    }

    deinit {
        countdownTask?.cancel()
    }

    func viewDidLoad() {
        startTimerIfNeeded()
        updatePrimaryButtonState()
    }

    func didUpdateCode(_ code: String) {
        self.code = String(code.prefix(6))
        startTimerIfNeeded()
        updatePrimaryButtonState()
    }

    func didTapPrimaryAction() {
        if code.isEmpty {
            guard canResend else { return }
            resendCode()
            return
        }

        guard code.count == 6 else { return }

        verifyCode()
    }

    func didTapClose() {
        onClose()
    }
}

extension AuthCodeVerificationPresenter: AuthCodeVerificationPresenting {}

private extension AuthCodeVerificationPresenter {
    var canResend: Bool {
        guard let resendAvailableAt else { return true }
        return resendAvailableAt <= Date()
    }

    func verifyCode() {
        isLoading = true
        updatePrimaryButtonState()
        view?.setLoading(true)

        Task { [weak self] in
            guard let self else { return }

            do {
                switch self.flow {
                case .registration:
                    try await self.flowService.verifyRegistrationCode(
                        email: self.email,
                        code: self.code
                    )
                case .passwordReset:
                    try await self.flowService.verifyPasswordResetCode(
                        email: self.email,
                        code: self.code
                    )
                }

                self.handleVerified()
            } catch {
                self.handleFailure(error)
            }
        }
    }

    func resendCode() {
        isLoading = true
        updatePrimaryButtonState()
        view?.setLoading(true)

        Task { [weak self] in
            guard let self else { return }

            do {
                switch self.flow {
                case .registration:
                    try await self.flowService.resendRegistrationCode(
                        email: self.email,
                        locale: self.localeProvider.localeCode()
                    )
                case .passwordReset:
                    try await self.flowService.resendPasswordResetCode(
                        email: self.email,
                        locale: self.localeProvider.localeCode()
                    )
                }

                self.handleResent()
            } catch {
                self.handleFailure(error)
            }
        }
    }

    func handleVerified() {
        isLoading = false
        view?.setLoading(false)
        updatePrimaryButtonState()
        onVerified(email)
    }

    func handleResent() {
        isLoading = false
        resendAvailableAt = Date().addingTimeInterval(60)
        startTimerIfNeeded()
        view?.setLoading(false)
        updatePrimaryButtonState()
    }

    func handleFailure(_ error: Error) {
        isLoading = false
        view?.setLoading(false)
        updatePrimaryButtonState()
        view?.showError(message: AuthFeatureErrorFormatter.message(for: error))
    }

    func startTimerIfNeeded() {
        countdownTask?.cancel()
        countdownTask = nil

        guard code.isEmpty, canResend == false else { return }

        countdownTask = Task { [weak self] in
            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(1))

                guard let self else { return }
                self.handleTimerTick()

                if self.code.isEmpty == false || self.canResend {
                    return
                }
            }
        }
    }

    func handleTimerTick() {
        guard code.isEmpty else {
            countdownTask?.cancel()
            countdownTask = nil
            return
        }

        if canResend {
            countdownTask?.cancel()
            countdownTask = nil
        }

        updatePrimaryButtonState()
    }

    func updatePrimaryButtonState() {
        let state = currentButtonState()
        view?.updatePrimaryButton(title: state.title, isEnabled: state.isEnabled)
    }

    func currentButtonState() -> (title: String, isEnabled: Bool) {
        if code.isEmpty == false {
            return ("Продолжить", code.count == 6 && isLoading == false)
        }

        guard isLoading == false else {
            return ("Отправить код повторно", false)
        }

        guard let resendAvailableAt else {
            return ("Отправить код повторно", true)
        }

        let remaining = Int(ceil(resendAvailableAt.timeIntervalSinceNow))
        if remaining <= 0 {
            return ("Отправить код повторно", true)
        }

        return ("Запросить через \(format(seconds: remaining))", false)
    }

    func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

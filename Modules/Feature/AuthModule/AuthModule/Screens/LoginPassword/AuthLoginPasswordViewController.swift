import UIKit
import DesignSystem

@MainActor
final class AuthLoginPasswordViewController: BaseViewController, AuthLoginPasswordView {
    private let presenter: AuthLoginPasswordPresenting
    private let email: String
    private let screenView = AuthScreenScaffoldView(
        title: "Введите пароль",
        subtitle: nil,
        primaryButtonTitle: "Войти"
    )
    private let passwordField = CommonTextField(
        configuration: .init(
            hint: "Пароль",
            kind: .password
        )
    )
    private let forgotPasswordButton = LinkButton(
        configuration: LinkButtonConfiguration(title: "Забыли пароль")
    )

    private var isPrimaryActionEnabled = false
    private var isLoadingState = false

    init(
        email: String,
        presenter: AuthLoginPasswordPresenting
    ) {
        self.email = email
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = screenView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.viewDidLoad()
    }

    func setPrimaryActionEnabled(_ isEnabled: Bool) {
        isPrimaryActionEnabled = isEnabled
        updateControlsState()
    }

    func setLoading(_ isLoading: Bool) {
        isLoadingState = isLoading
        screenView.bodyStackView.isUserInteractionEnabled = !isLoading
        screenView.actionsStackView.isUserInteractionEnabled = !isLoading
        screenView.setLoading(isLoading)
        updateControlsState()
    }

    func showError(message: String) {
        presentAuthError(message: message)
    }
}

private extension AuthLoginPasswordViewController {
    func setupView() {
        screenView.bodyStackView.addArrangedSubview(AuthEmailSummaryView(email: email))
        screenView.bodyStackView.addArrangedSubview(passwordField)

        screenView.actionsStackView.addArrangedSubview(forgotPasswordButton)

        passwordField.onTextChanged = { [weak self] text in
            self?.presenter.didUpdatePassword(text)
        }
        screenView.primaryButton.onTap = { [weak self] in
            self?.presenter.didTapLogin()
        }
        forgotPasswordButton.onTap = { [weak self] in
            self?.presenter.didTapForgotPassword()
        }
    }

    func updateControlsState() {
        screenView.primaryButton.isEnabled = isPrimaryActionEnabled && !isLoadingState
        forgotPasswordButton.isEnabled = !isLoadingState
    }
}

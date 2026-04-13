import UIKit
import DesignSystem

@MainActor
final class AuthPasswordResetViewController: BaseViewController, AuthPasswordResetView {
    private let presenter: AuthPasswordResetPresenting
    private let email: String
    private let screenView = AuthScreenScaffoldView(
        title: "Новый пароль",
        subtitle: "Придумайте новый пароль для восстановления доступа.",
        primaryButtonTitle: "Сохранить пароль"
    )
    private let passwordField = CommonTextField(
        configuration: .init(
            hint: "Новый пароль",
            kind: .password
        )
    )

    private var isPrimaryActionEnabled = false
    private var isLoadingState = false

    init(
        email: String,
        presenter: AuthPasswordResetPresenting
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
        updatePrimaryButtonState()
    }

    func setLoading(_ isLoading: Bool) {
        isLoadingState = isLoading
        screenView.bodyStackView.isUserInteractionEnabled = !isLoading
        screenView.actionsStackView.isUserInteractionEnabled = !isLoading
        screenView.setLoading(isLoading)
        updatePrimaryButtonState()
    }

    func showError(message: String) {
        presentAuthError(message: message)
    }
}

private extension AuthPasswordResetViewController {
    func setupView() {
        screenView.bodyStackView.addArrangedSubview(AuthEmailSummaryView(email: email))
        screenView.bodyStackView.addArrangedSubview(passwordField)

        passwordField.onTextChanged = { [weak self] text in
            self?.presenter.didUpdatePassword(text)
        }
        screenView.primaryButton.onTap = { [weak self] in
            self?.presenter.didTapContinue()
        }
    }

    func updatePrimaryButtonState() {
        screenView.primaryButton.isEnabled = isPrimaryActionEnabled && !isLoadingState
    }
}

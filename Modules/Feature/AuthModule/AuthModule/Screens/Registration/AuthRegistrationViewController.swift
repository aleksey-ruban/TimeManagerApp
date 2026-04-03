import UIKit
import DesignSystem

@MainActor
final class AuthRegistrationViewController: UIViewController, AuthRegistrationView {
    private let presenter: AuthRegistrationPresenting
    private let email: String
    private let screenView = AuthScreenScaffoldView(
        title: "Регистрация",
        subtitle: "Введите имя и пароль, чтобы завершить создание аккаунта.",
        primaryButtonTitle: "Зарегистрироваться"
    )
    private let firstNameField = CommonTextField(
        configuration: .init(
            hint: "Имя",
            kind: .plain
        )
    )
    private let passwordField = CommonTextField(
        configuration: .init(
            hint: "Пароль",
            kind: .password
        )
    )

    private var isPrimaryActionEnabled = false
    private var isLoadingState = false

    init(
        email: String,
        presenter: AuthRegistrationPresenting
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

private extension AuthRegistrationViewController {
    func setupView() {
        screenView.bodyStackView.addArrangedSubview(AuthEmailSummaryView(email: email))
        screenView.bodyStackView.addArrangedSubview(firstNameField)
        screenView.bodyStackView.addArrangedSubview(passwordField)

        firstNameField.onTextChanged = { [weak self] text in
            self?.presenter.didUpdateFirstName(text)
        }
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

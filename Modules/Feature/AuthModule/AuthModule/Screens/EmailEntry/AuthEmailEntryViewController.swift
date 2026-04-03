import UIKit
import DesignSystem

@MainActor
final class AuthEmailEntryViewController: UIViewController, AuthEmailEntryView {
    private let presenter: AuthEmailEntryPresenting
    private let screenView = AuthScreenScaffoldView(
        title: "Введите адрес электронной почты",
        subtitle: "Чтобы войти или зарегистрироваться",
        primaryButtonTitle: "Продолжить"
    )
    private let emailField = CommonTextField(
        configuration: .init(
            hint: "Электронная почта",
            kind: .email
        )
    )
    private var isPrimaryActionEnabled = false
    private var isLoadingState = false

    init(presenter: AuthEmailEntryPresenting) {
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

private extension AuthEmailEntryViewController {
    func setupView() {
        navigationItem.hidesBackButton = true
        
        screenView.bodyStackView.addArrangedSubview(emailField)
        
        emailField.onTextChanged = { [weak self] text in
            self?.presenter.didUpdateEmail(text)
        }
        
        screenView.primaryButton.onTap = { [weak self] in
            self?.presenter.didTapContinue()
        }
    }

    func updatePrimaryButtonState() {
        screenView.primaryButton.isEnabled = isPrimaryActionEnabled && !isLoadingState
    }
}

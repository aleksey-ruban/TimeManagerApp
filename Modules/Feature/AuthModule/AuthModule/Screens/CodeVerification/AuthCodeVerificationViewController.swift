import UIKit
import DesignSystem

@MainActor
final class AuthCodeVerificationViewController: BaseViewController, AuthCodeVerificationView {
    private let presenter: AuthCodeVerificationPresenting
    private let screenView: AuthScreenScaffoldView
    private let codeField = CommonTextField(
        configuration: .init(
            hint: "Код проверки",
            kind: .numericCode
        )
    )
    private var primaryButtonEnabled = false
    private var isLoadingState = false

    init(
        flow: AuthVerificationFlow,
        email: String,
        presenter: AuthCodeVerificationPresenting
    ) {
        self.presenter = presenter
        self.screenView = AuthScreenScaffoldView(
            title: flow == .registration ? "Подтвердите почту" : "Подтвердите восстановление",
            subtitle: "Код отправлен на почту \(email)",
            primaryButtonTitle: "Продолжить"
        )
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

    func updatePrimaryButton(title: String, isEnabled: Bool) {
        primaryButtonEnabled = isEnabled
        screenView.setPrimaryButtonTitle(title)
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

private extension AuthCodeVerificationViewController {
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(handleClose)
        )

        screenView.bodyStackView.addArrangedSubview(codeField)
        codeField.onTextChanged = { [weak self] text in
            self?.presenter.didUpdateCode(text)
        }
        screenView.primaryButton.onTap = { [weak self] in
            self?.presenter.didTapPrimaryAction()
        }
    }

    @objc
    private func handleClose() {
        presenter.didTapClose()
    }

    func updatePrimaryButtonState() {
        screenView.primaryButton.isEnabled = primaryButtonEnabled && !isLoadingState
    }
}

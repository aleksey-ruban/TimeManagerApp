import UIKit

@MainActor
open class BaseViewController: UIViewController {
    open var allowsTapToDismissKeyboard: Bool {
        true
    }

    private lazy var tapToDismissKeyboardGestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapToDismissKeyboard)
        )
        gestureRecognizer.cancelsTouchesInView = false
        return gestureRecognizer
    }()

    open override func viewDidLoad() {
        super.viewDidLoad()
        configureTapToDismissKeyboardIfNeeded()
    }
}

private extension BaseViewController {
    func configureTapToDismissKeyboardIfNeeded() {
        guard allowsTapToDismissKeyboard else { return }
        view.addGestureRecognizer(tapToDismissKeyboardGestureRecognizer)
    }

    @objc
    func handleTapToDismissKeyboard() {
        view.endEditing(true)
    }
}

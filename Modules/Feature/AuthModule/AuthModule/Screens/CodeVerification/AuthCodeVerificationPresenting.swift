import Foundation

@MainActor
protocol AuthCodeVerificationPresenting: AnyObject {
    var view: AuthCodeVerificationView? { get set }
    func viewDidLoad()
    func didUpdateCode(_ code: String)
    func didTapPrimaryAction()
    func didTapClose()
}

import Foundation

@MainActor
protocol AuthLoginPasswordPresenting: AnyObject {
    var view: AuthLoginPasswordView? { get set }
    func viewDidLoad()
    func didUpdatePassword(_ password: String)
    func didTapLogin()
    func didTapForgotPassword()
}

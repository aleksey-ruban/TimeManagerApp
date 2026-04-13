import Foundation

@MainActor
protocol AuthPasswordResetPresenting: AnyObject {
    var view: AuthPasswordResetView? { get set }
    func viewDidLoad()
    func didUpdatePassword(_ password: String)
    func didTapContinue()
}

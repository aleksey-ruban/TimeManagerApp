import Foundation

@MainActor
protocol AuthRegistrationPresenting: AnyObject {
    var view: AuthRegistrationView? { get set }
    func viewDidLoad()
    func didUpdateFirstName(_ firstName: String)
    func didUpdatePassword(_ password: String)
    func didTapContinue()
}

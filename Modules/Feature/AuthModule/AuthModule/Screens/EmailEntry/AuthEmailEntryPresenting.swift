import Foundation

@MainActor
protocol AuthEmailEntryPresenting: AnyObject {
    var view: AuthEmailEntryView? { get set }
    func didUpdateEmail(_ email: String)
    func didTapContinue()
}

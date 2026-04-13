import Foundation

@MainActor
protocol SettingsProfileEditPresenting: AnyObject {
    func viewDidLoad()
    func didUpdateName(_ name: String)
    func didTapSave()
    func didTapDeleteAccount()
    func didConfirmDeleteAccount()
}

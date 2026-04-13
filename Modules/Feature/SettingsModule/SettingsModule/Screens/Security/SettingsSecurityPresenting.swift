import Foundation

@MainActor
protocol SettingsSecurityPresenting: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func didTapLogoutDevice(at index: Int)
    func didTapLogoutOthers()
    func didConfirmLogoutDevice()
    func didConfirmLogoutOthers()
}

import Foundation

@MainActor
protocol SettingsRootPresenting: AnyObject {
    func viewDidLoad()
    func viewWillAppear()
    func didTapProfile()
    func didTapSecurity()
    func didTapLogout()
    func didConfirmLogout()
}

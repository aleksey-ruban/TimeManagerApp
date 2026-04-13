import UIKit

@MainActor
protocol SettingsSecurityAssemblyProtocol: AnyObject {
    func makeViewController() -> UIViewController
}

@MainActor
final class SettingsSecurityAssembly: SettingsSecurityAssemblyProtocol {
    private let service: SettingsFeatureServiceProtocol

    init(service: SettingsFeatureServiceProtocol) {
        self.service = service
    }

    func makeViewController() -> UIViewController {
        let presenter = SettingsSecurityPresenter(service: service)
        let viewController = SettingsSecurityViewController(presenter: presenter)
        presenter.view = viewController
        return viewController
    }
}

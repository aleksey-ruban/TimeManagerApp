import UIKit

@MainActor
protocol SettingsProfileEditAssemblyProtocol: AnyObject {
    func makeViewController(onSessionFinished: @escaping @MainActor () -> Void) -> UIViewController
}

@MainActor
final class SettingsProfileEditAssembly: SettingsProfileEditAssemblyProtocol {
    private let service: SettingsFeatureServiceProtocol

    init(service: SettingsFeatureServiceProtocol) {
        self.service = service
    }

    func makeViewController(onSessionFinished: @escaping @MainActor () -> Void) -> UIViewController {
        let presenter = SettingsProfileEditPresenter(
            service: service,
            onSessionFinished: onSessionFinished
        )
        let viewController = SettingsProfileEditViewController(presenter: presenter)
        presenter.view = viewController
        return viewController
    }
}

import UIKit

@MainActor
protocol SettingsRootAssemblyProtocol: AnyObject {
    func makeViewController(
        onOpenProfile: @escaping () -> Void,
        onOpenSecurity: @escaping () -> Void,
        onSessionFinished: @escaping @MainActor () -> Void
    ) -> UIViewController
}

@MainActor
final class SettingsRootAssembly: SettingsRootAssemblyProtocol {
    private let service: SettingsFeatureServiceProtocol

    init(service: SettingsFeatureServiceProtocol) {
        self.service = service
    }

    func makeViewController(
        onOpenProfile: @escaping () -> Void,
        onOpenSecurity: @escaping () -> Void,
        onSessionFinished: @escaping @MainActor () -> Void
    ) -> UIViewController {
        let presenter = SettingsRootPresenter(
            service: service,
            onOpenProfile: onOpenProfile,
            onOpenSecurity: onOpenSecurity,
            onSessionFinished: onSessionFinished
        )
        let viewController = SettingsRootViewController(presenter: presenter)
        presenter.view = viewController
        return viewController
    }
}

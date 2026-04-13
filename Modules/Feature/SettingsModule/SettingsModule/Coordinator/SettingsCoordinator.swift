import UIKit

@MainActor
final class SettingsCoordinator: SettingsCoordinatorProtocol {
    private let navigationController: UINavigationController
    private let rootAssembly: SettingsRootAssemblyProtocol
    private let profileEditAssembly: SettingsProfileEditAssemblyProtocol
    private let securityAssembly: SettingsSecurityAssemblyProtocol
    private let onSessionFinished: @MainActor () -> Void

    init(
        navigationController: UINavigationController,
        rootAssembly: SettingsRootAssemblyProtocol,
        profileEditAssembly: SettingsProfileEditAssemblyProtocol,
        securityAssembly: SettingsSecurityAssemblyProtocol,
        onSessionFinished: @escaping @MainActor () -> Void
    ) {
        self.navigationController = navigationController
        self.rootAssembly = rootAssembly
        self.profileEditAssembly = profileEditAssembly
        self.securityAssembly = securityAssembly
        self.onSessionFinished = onSessionFinished
    }

    func start() {
        showRoot()
    }
}

private extension SettingsCoordinator {
    func showRoot() {
        let viewController = rootAssembly.makeViewController(
            onOpenProfile: { [weak self] in
                self?.showProfile()
            },
            onOpenSecurity: { [weak self] in
                self?.showSecurity()
            },
            onSessionFinished: onSessionFinished
        )

        navigationController.setViewControllers([viewController], animated: false)
    }

    func showProfile() {
        let viewController = profileEditAssembly.makeViewController(onSessionFinished: onSessionFinished)
        push(viewController, animated: true)
    }

    func showSecurity() {
        let viewController = securityAssembly.makeViewController()
        push(viewController, animated: true)
    }

    func push(_ viewController: UIViewController, animated: Bool) {
        viewController.hidesBottomBarWhenPushed = navigationController.viewControllers.isEmpty == false
        navigationController.pushViewController(viewController, animated: animated)
    }
}

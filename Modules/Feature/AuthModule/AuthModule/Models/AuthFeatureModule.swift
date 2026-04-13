import UIKit

@MainActor
public protocol AuthCoordinatorProtocol: AnyObject {
    func start()
}

@MainActor
public struct AuthFeatureModule {
    public let rootViewController: UIViewController
    public let coordinator: AuthCoordinatorProtocol

    public init(
        rootViewController: UIViewController,
        coordinator: AuthCoordinatorProtocol
    ) {
        self.rootViewController = rootViewController
        self.coordinator = coordinator
    }
}

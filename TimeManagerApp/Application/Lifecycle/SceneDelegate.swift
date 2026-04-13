//
//  SceneDelegate.swift
//  TimeManagerApp
//
//  Created by Aleksey Ruban on 30.03.2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var appCoordinator: AppCoordinator?
    private var dependencyContainer: AppDependencyContainer?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        do {
            let dependencyContainer = try AppDependencyContainer()
            let coordinator = dependencyContainer.makeAppCoordinator(window: window)

            self.dependencyContainer = dependencyContainer
            self.appCoordinator = coordinator
            coordinator.start()
        } catch {
            window.rootViewController = makeBootstrapErrorViewController(error: error)
        }

        window.makeKeyAndVisible()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        do {
            try dependencyContainer?.saveApplicationState()
        } catch {
            assertionFailure("Failed to save application state: \(error.localizedDescription)")
        }
    }
}

private extension SceneDelegate {
    func makeBootstrapErrorViewController(error: Error) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "Failed to start app:\n\(error.localizedDescription)"

        viewController.view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
        ])

        return viewController
    }
}

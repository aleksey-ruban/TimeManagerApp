import UIKit
import DesignTokens

@MainActor
final class MainTabBarController: UITabBarController {
    enum Tab: Int {
        case home
//        case calendar
        case analytics
        case settings
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
    }

    func selectTab(_ tab: Tab) {
        selectedIndex = tab.rawValue
    }
}

private extension MainTabBarController {
    func configureAppearance() {
        view.backgroundColor = DesignColor.backgroundPrimary
        delegate = self
        view.tintColor = .systemBlue

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.18)

        [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance]
            .forEach { itemAppearance in
                itemAppearance.normal.iconColor = UIColor.secondaryLabel
                itemAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor.secondaryLabel
                ]
                itemAppearance.selected.iconColor = .systemBlue
                itemAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor.systemBlue
                ]
            }

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = true
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = UIColor.secondaryLabel
        tabBar.itemPositioning = .automatic
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        true
    }
}

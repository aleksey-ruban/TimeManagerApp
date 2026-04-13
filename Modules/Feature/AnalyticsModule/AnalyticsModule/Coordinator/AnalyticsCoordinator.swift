import UIKit

@MainActor
final class AnalyticsCoordinator: AnalyticsCoordinatorProtocol {
    private let navigationController: UINavigationController
    private let service: AnalyticsFeatureServiceProtocol

    init(
        navigationController: UINavigationController,
        service: AnalyticsFeatureServiceProtocol
    ) {
        self.navigationController = navigationController
        self.service = service
    }

    func start() {
        showDashboard()
    }

    func showDashboard() {
        let presenter = ChronometryDashboardPresenter(
            service: service,
            onOpenChronometry: { [weak self] chronometryID in
                self?.showChronometryDetails(id: chronometryID)
            }
        )
        let viewController = ChronometryDashboardViewController(presenter: presenter)

        if navigationController.viewControllers.isEmpty {
            viewController.tabBarItem = UITabBarItem(
                title: "Аналитика",
                image: UIImage(systemName: "sparkles.rectangle.stack"),
                selectedImage: UIImage(systemName: "sparkles.rectangle.stack")
            )
            navigationController.setViewControllers([viewController], animated: false)
        } else if navigationController.topViewController is ChronometryDashboardViewController {
            viewController.tabBarItem = UITabBarItem(
                title: "Аналитика",
                image: UIImage(systemName: "sparkles.rectangle.stack"),
                selectedImage: UIImage(systemName: "sparkles.rectangle.stack")
            )
            navigationController.setViewControllers([viewController], animated: false)
        } else {
            push(viewController, animated: true)
        }
    }
}

private extension AnalyticsCoordinator {
    func showChronometryDetails(id: UUID) {
        let presenter = ChronometryDetailsPresenter(
            service: service,
            chronometryID: id,
            onOpenRecords: { [weak self] chronometryID in
                self?.showRecordTimeline(chronometryID: chronometryID)
            },
            onOpenWeeklyIssue: { [weak self] chronometryID, code in
                self?.showWeeklyIssueDetails(chronometryID: chronometryID, code: code)
            },
            onOpenDayIssues: { [weak self] chronometryID, date in
                self?.showDayIssues(chronometryID: chronometryID, date: date)
            },
            onDeleted: { [weak self] in
                self?.navigationController.popViewController(animated: true)
            }
        )
        let viewController = ChronometryDetailsViewController(presenter: presenter)
        push(viewController, animated: true)
    }

    func showRecordTimeline(chronometryID: UUID) {
        let presenter = ChronometryRecordTimelinePresenter(service: service, chronometryID: chronometryID)
        let viewController = ChronometryRecordTimelineViewController(presenter: presenter)
        push(viewController, animated: true)
    }

    func showWeeklyIssueDetails(chronometryID: UUID, code: ChronometryIssueCode) {
        let presenter = ChronometryWeeklyIssueDetailsPresenter(
            service: service,
            chronometryID: chronometryID,
            code: code
        )
        let viewController = ChronometryWeeklyIssueDetailsViewController(presenter: presenter)
        push(viewController, animated: true)
    }

    func showDayIssues(chronometryID: UUID, date: Date) {
        let presenter = ChronometryDayIssuesPresenter(
            service: service,
            chronometryID: chronometryID,
            date: date
        )
        let viewController = ChronometryDayIssuesViewController(presenter: presenter)
        push(viewController, animated: true)
    }

    func push(_ viewController: UIViewController, animated: Bool) {
        viewController.hidesBottomBarWhenPushed = navigationController.viewControllers.isEmpty == false
        navigationController.pushViewController(viewController, animated: animated)
    }
}

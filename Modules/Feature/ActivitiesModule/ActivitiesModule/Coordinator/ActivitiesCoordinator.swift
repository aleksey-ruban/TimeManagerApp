import UIKit
import Domain
import CommonCalendar

@MainActor
final class ActivitiesCoordinator: ActivitiesCoordinatorProtocol {
    private let navigationController: UINavigationController
    private let service: ActivitiesFeatureServiceProtocol
    private let calendarAssembly: CommonCalendarAssemblyProtocol

    init(
        navigationController: UINavigationController,
        service: ActivitiesFeatureServiceProtocol,
        calendarAssembly: CommonCalendarAssemblyProtocol
    ) {
        self.navigationController = navigationController
        self.service = service
        self.calendarAssembly = calendarAssembly
    }

    func start() {
        showActivityList()
    }

    func showActivityList() {
        let presenter = ActivityListPresenter(
            service: service,
            onAdd: { [weak self] in
                self?.showActivityEditor(activityID: nil)
            },
            onEdit: { [weak self] activityID in
                self?.showActivityEditor(activityID: activityID)
            },
            onLaunch: { [weak self] in
                self?.showActivityLauncher()
            }
        )
        let viewController = ActivityListViewController(presenter: presenter)
        presenter.view = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func showActivityOverview() {
        let presenter = ActivityOverviewPresenter(
            service: service,
            onCreateRecord: { [weak self] in
                self?.showActivityRecordCreation()
            },
            onEditRecord: { [weak self] recordID in
                self?.showActivityRecordEditor(activityRecordID: recordID)
            }
        )
        let viewController = ActivityOverviewViewController(
            presenter: presenter,
            dateNavigatorView: calendarAssembly.makeDateNavigatorView(),
            calendarAssembly: calendarAssembly
        )
        presenter.view = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func showActivityLauncher() {
        let presenter = ActivityLauncherPresenter(
            service: service,
            onCreateRecord: { [weak self] in
                self?.showActivityRecordCreation()
            },
            onFinished: { _ in
            }
        )
        let viewController = ActivityLauncherViewController(presenter: presenter)
        presenter.view = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func showActivityEditor(activityID: UUID?) {
        let presenter = ActivityEditorPresenter(
            service: service,
            activityID: activityID,
            onSelectIcon: { [weak self] selectedIconName, selectedColor, onApply in
                self?.showIconPicker(
                    selectedIconName: selectedIconName,
                    selectedColor: selectedColor,
                    onApply: onApply
                )
            },
            onSelectCategory: { [weak self] selectedCategoryID, onApply in
                self?.showCategoryPicker(
                    selectedCategoryID: selectedCategoryID,
                    onApply: onApply
                )
            },
            onSaved: { [weak self] _ in
                self?.navigationController.popViewController(animated: true)
            }
        )
        let viewController = ActivityEditorViewController(presenter: presenter)
        presenter.view = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func showActivityRecordCreation() {
        let returnViewController = navigationController.topViewController
        let presenter = ActivityRecordPickerPresenter(
            service: service,
            onSelect: { [weak self, weak returnViewController] activityID in
                self?.showActivityRecordEditor(
                    activityID: activityID,
                    activityRecordID: nil,
                    returnViewController: returnViewController
                )
            }
        )
        let viewController = ActivityRecordPickerViewController(presenter: presenter)
        presenter.view = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func showActivityRecordEditor(activityRecordID: UUID) {
        showActivityRecordEditor(
            activityID: nil,
            activityRecordID: activityRecordID,
            returnViewController: nil
        )
    }
}

private extension ActivitiesCoordinator {
    func showActivityRecordEditor(
        activityID: UUID?,
        activityRecordID: UUID?,
        returnViewController: UIViewController?
    ) {
        let presenter = ActivityRecordEditorPresenter(
            service: service,
            activityID: activityID,
            activityRecordID: activityRecordID,
            onSaved: { [weak self, weak returnViewController] _ in
                if let returnViewController {
                    self?.navigationController.popToViewController(returnViewController, animated: true)
                } else {
                    self?.navigationController.popViewController(animated: true)
                }
            }
        )
        let viewController = ActivityRecordEditorViewController(presenter: presenter)
        presenter.view = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func showIconPicker(
        selectedIconName: String,
        selectedColor: ActivityColor,
        onApply: @escaping @MainActor (String, ActivityColor) -> Void
    ) {
        let presenter = ActivityIconPickerPresenter(
            selectedIconName: selectedIconName,
            selectedColor: selectedColor,
            onApply: { [weak self] iconName, color in
                onApply(iconName, color)
                self?.navigationController.presentedViewController?.dismiss(animated: true)
            }
        )
        let viewController = ActivityIconPickerViewController(presenter: presenter)
        presenter.view = viewController
        let modalNavigationController = UINavigationController(rootViewController: viewController)
        if let sheet = modalNavigationController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        modalNavigationController.modalPresentationStyle = .pageSheet
        navigationController.present(modalNavigationController, animated: true)
    }

    func showCategoryPicker(
        selectedCategoryID: UUID?,
        onApply: @escaping @MainActor (UUID?) -> Void
    ) {
        let presenter = CategoryPickerPresenter(
            service: service,
            selectedCategoryID: selectedCategoryID,
            onApply: { [weak self] categoryID in
                onApply(categoryID)
                self?.navigationController.popViewController(animated: true)
            }
        )
        let viewController = CategoryPickerViewController(presenter: presenter)
        presenter.view = viewController
        navigationController.pushViewController(viewController, animated: true)
    }
}

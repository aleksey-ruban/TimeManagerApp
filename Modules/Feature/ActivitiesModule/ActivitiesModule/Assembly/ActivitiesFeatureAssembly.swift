import UIKit
import CommonSync
import CoreStorage
import CommonCalendar

public protocol ActivitiesFeatureAssemblyProtocol: Sendable {
    @MainActor
    func makeCoordinator(navigationController: UINavigationController) -> ActivitiesCoordinatorProtocol

    @MainActor
    func makeFrequentlyUsedWidget(
        onOpenAll: @escaping @MainActor () -> Void,
        onAddNew: @escaping @MainActor () -> Void
    ) -> FrequentlyUsedActivitiesWidgetView

    @MainActor
    func makeActivitySummaryWidget() -> ActivitySummaryWidgetView

    @MainActor
    func makeMyActivitiesWidget(onOpen: @escaping @MainActor () -> Void) -> MyActivitiesWidgetView
}

public struct ActivitiesFeatureAssembly: ActivitiesFeatureAssemblyProtocol, @unchecked Sendable {
    private let serviceBox = ActivitiesFeatureServiceBox()
    private let coreDataStack: CoreDataStackProtocol
    private let syncService: AppSyncServiceProtocol
    private let calendarAssembly: CommonCalendarAssemblyProtocol

    public init(
        coreDataStack: CoreDataStackProtocol,
        syncService: AppSyncServiceProtocol,
        calendarAssembly: CommonCalendarAssemblyProtocol = CommonCalendarAssembly()
    ) {
        self.coreDataStack = coreDataStack
        self.syncService = syncService
        self.calendarAssembly = calendarAssembly
    }

    @MainActor
    public func makeCoordinator(navigationController: UINavigationController) -> ActivitiesCoordinatorProtocol {
        ActivitiesCoordinator(
            navigationController: navigationController,
            service: serviceBox.service(
                coreDataStack: coreDataStack,
                syncService: syncService
            ),
            calendarAssembly: calendarAssembly
        )
    }

    @MainActor
    public func makeFrequentlyUsedWidget(
        onOpenAll: @escaping @MainActor () -> Void,
        onAddNew: @escaping @MainActor () -> Void
    ) -> FrequentlyUsedActivitiesWidgetView {
        FrequentlyUsedActivitiesWidgetView(
            service: serviceBox.service(
                coreDataStack: coreDataStack,
                syncService: syncService
            ),
            onOpenAll: onOpenAll,
            onAddNew: onAddNew
        )
    }

    @MainActor
    public func makeActivitySummaryWidget() -> ActivitySummaryWidgetView {
        ActivitySummaryWidgetView(
            service: serviceBox.service(
                coreDataStack: coreDataStack,
                syncService: syncService
            )
        )
    }

    @MainActor
    public func makeMyActivitiesWidget(onOpen: @escaping @MainActor () -> Void) -> MyActivitiesWidgetView {
        MyActivitiesWidgetView(onOpen: onOpen)
    }
}

private final class ActivitiesFeatureServiceBox: @unchecked Sendable {
    @MainActor
    func service(
        coreDataStack: CoreDataStackProtocol,
        syncService: AppSyncServiceProtocol
    ) -> ActivitiesFeatureServiceProtocol {
        if let cachedService {
            return cachedService
        }

        let service = ActivitiesFeatureService(
            coreDataStack: coreDataStack,
            syncService: syncService
        )
        cachedService = service
        return service
    }

    @MainActor
    private var cachedService: ActivitiesFeatureServiceProtocol?
}

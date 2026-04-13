import CommonSync
import CoreNetwork
import CoreStorage
import UIKit

public protocol AnalyticsFeatureAssemblyProtocol: Sendable {
    @MainActor
    func makeCoordinator(navigationController: UINavigationController) -> AnalyticsCoordinatorProtocol

    @MainActor
    func makeOverviewWidget(onOpen: @escaping @MainActor () -> Void) -> ChronometryAnalyticsWidgetView
}

public struct AnalyticsFeatureAssembly: AnalyticsFeatureAssemblyProtocol, @unchecked Sendable {
    private let serviceBox = AnalyticsFeatureServiceBox()
    private let coreDataStack: CoreDataStackProtocol
    private let syncService: AppSyncServiceProtocol
    private let networkExecutorFactory: NetworkExecutorFactoryProtocol
    private let configuration: AnalyticsFeatureAPIConfiguration

    public init(
        coreDataStack: CoreDataStackProtocol,
        syncService: AppSyncServiceProtocol,
        networkExecutorFactory: NetworkExecutorFactoryProtocol,
        configuration: AnalyticsFeatureAPIConfiguration
    ) {
        self.coreDataStack = coreDataStack
        self.syncService = syncService
        self.networkExecutorFactory = networkExecutorFactory
        self.configuration = configuration
    }

    @MainActor
    public func makeCoordinator(navigationController: UINavigationController) -> AnalyticsCoordinatorProtocol {
        AnalyticsCoordinator(
            navigationController: navigationController,
            service: serviceBox.service(
                coreDataStack: coreDataStack,
                syncService: syncService,
                networkExecutorFactory: networkExecutorFactory,
                configuration: configuration
            )
        )
    }

    @MainActor
    public func makeOverviewWidget(onOpen: @escaping @MainActor () -> Void) -> ChronometryAnalyticsWidgetView {
        ChronometryAnalyticsWidgetView(
            service: serviceBox.service(
                coreDataStack: coreDataStack,
                syncService: syncService,
                networkExecutorFactory: networkExecutorFactory,
                configuration: configuration
            ),
            onOpen: onOpen
        )
    }
}

private final class AnalyticsFeatureServiceBox: @unchecked Sendable {
    @MainActor
    func service(
        coreDataStack: CoreDataStackProtocol,
        syncService: AppSyncServiceProtocol,
        networkExecutorFactory: NetworkExecutorFactoryProtocol,
        configuration: AnalyticsFeatureAPIConfiguration
    ) -> AnalyticsFeatureServiceProtocol {
        if let cachedService {
            return cachedService
        }

        let service = AnalyticsFeatureService(
            coreDataStack: coreDataStack,
            syncService: syncService,
            remoteService: AnalyticsFeatureRemoteService(
                executorFactory: networkExecutorFactory,
                configuration: configuration
            ),
            cacheRepository: ChronometryAnalyticsCacheRepository(coreDataStack: coreDataStack)
        )

        cachedService = service
        return service
    }

    @MainActor
    private var cachedService: AnalyticsFeatureServiceProtocol?
}

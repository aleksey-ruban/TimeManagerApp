import CoreUserProfile
import CoreNetwork
import CoreStorage
import CoreSync
import Domain
import Foundation

public protocol CommonSyncAssemblyProtocol {
    func makeSyncService() -> AppSyncServiceProtocol
}

public struct CommonSyncAssembly: CommonSyncAssemblyProtocol {
    private let syncAssembly: SyncAssemblyProtocol
    private let networkExecutorFactory: NetworkExecutorFactoryProtocol
    private let coreDataStack: CoreDataStackProtocol
    private let apiConfiguration: SyncAPIConfiguration
    private let userProfileService: UserProfileServiceProtocol

    public init(
        syncAssembly: SyncAssemblyProtocol,
        networkExecutorFactory: NetworkExecutorFactoryProtocol,
        coreDataStack: CoreDataStackProtocol,
        apiConfiguration: SyncAPIConfiguration,
        userProfileService: UserProfileServiceProtocol
    ) {
        self.syncAssembly = syncAssembly
        self.networkExecutorFactory = networkExecutorFactory
        self.coreDataStack = coreDataStack
        self.apiConfiguration = apiConfiguration
        self.userProfileService = userProfileService
    }

    public func makeSyncService() -> AppSyncServiceProtocol {
        let remoteAPI = NetworkSyncRemoteAPIService(
            executorFactory: networkExecutorFactory,
            configuration: apiConfiguration
        )

        let categoryRepository = CategorySyncRepository(coreDataStack: coreDataStack)
        let activityRepository = ActivitySyncRepository(coreDataStack: coreDataStack)
        let activityRecordRepository = ActivityRecordSyncRepository(coreDataStack: coreDataStack)
        let chronometryRepository = ChronometrySyncRepository(coreDataStack: coreDataStack)

        let pullStages: [any SyncPullStageProtocol] = [
            CategoriesPullStage(repository: categoryRepository),
            ActivitiesPullStage(repository: activityRepository),
            ActivityRecordsPullStage(repository: activityRecordRepository),
            ChronometriesPullStage(repository: chronometryRepository),
        ]

        let pushStages: [any SyncPushStageProtocol] = [
            CategoriesPushStage(repository: categoryRepository, remoteAPI: remoteAPI),
            ActivitiesPushStage(repository: activityRepository, remoteAPI: remoteAPI),
            ActivityRecordsPushStage(repository: activityRecordRepository, remoteAPI: remoteAPI),
            ChronometriesPushStage(
                repository: chronometryRepository,
                remoteAPI: remoteAPI,
                userProfileService: userProfileService
            ),
        ]

        return AppSyncService(
            engine: syncAssembly.makeEngine(),
            remoteAPI: remoteAPI,
            userProfileService: userProfileService,
            pullStages: pullStages,
            pushStages: pushStages
        )
    }
}

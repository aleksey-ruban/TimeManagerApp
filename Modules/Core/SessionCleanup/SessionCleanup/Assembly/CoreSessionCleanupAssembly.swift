import CoreStorage

public protocol CoreSessionCleanupAssemblyProtocol: Sendable {
    func makeService() -> SessionCleanupServiceProtocol
}

public struct CoreSessionCleanupAssembly: CoreSessionCleanupAssemblyProtocol, @unchecked Sendable {
    private let userArtifactsStore: SessionCleanupUserArtifactsStoreProtocol
    private let coreDataStack: CoreDataStackProtocol

    public init(
        userArtifactsStore: SessionCleanupUserArtifactsStoreProtocol,
        coreDataStack: CoreDataStackProtocol
    ) {
        self.userArtifactsStore = userArtifactsStore
        self.coreDataStack = coreDataStack
    }

    public func makeService() -> SessionCleanupServiceProtocol {
        SessionCleanupService(
            userArtifactsStore: userArtifactsStore,
            coreDataStack: coreDataStack
        )
    }
}

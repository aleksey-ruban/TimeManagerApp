import CoreStorage
import Foundation

actor SessionCleanupService: SessionCleanupServiceProtocol {
    private let userArtifactsStore: SessionCleanupUserArtifactsStoreProtocol
    private let coreDataStack: CoreDataStackProtocol
    private var inFlightCleanupTask: Task<Void, Error>?

    init(
        userArtifactsStore: SessionCleanupUserArtifactsStoreProtocol,
        coreDataStack: CoreDataStackProtocol
    ) {
        self.userArtifactsStore = userArtifactsStore
        self.coreDataStack = coreDataStack
    }

    func clearLocalSessionArtifacts() async throws {
        if let inFlightCleanupTask {
            try await inFlightCleanupTask.value
            return
        }

        let cleanupTask = Task { [userArtifactsStore, coreDataStack] in
            var cleanupError: Error?

            await userArtifactsStore.clearUser()
            await userArtifactsStore.clearSessions()
            clearUserDefaults()

            do {
                try await coreDataStack.destroyAllData()
            } catch {
                cleanupError = cleanupError ?? error
            }

            if let cleanupError {
                throw cleanupError
            }
        }

        inFlightCleanupTask = cleanupTask
        defer { inFlightCleanupTask = nil }

        try await cleanupTask.value
    }
}

private extension SessionCleanupService {
    func clearUserDefaults() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        UserDefaults.standard.synchronize()
    }
}

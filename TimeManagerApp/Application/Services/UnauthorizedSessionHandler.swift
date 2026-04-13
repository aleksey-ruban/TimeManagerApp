import CoreSessionCleanup

protocol UnauthorizedSessionHandlerProtocol: Sendable {
    func handleUnauthorizedSession() async throws
}

struct UnauthorizedSessionHandler: UnauthorizedSessionHandlerProtocol {
    private let sessionCleanupService: SessionCleanupServiceProtocol

    init(sessionCleanupService: SessionCleanupServiceProtocol) {
        self.sessionCleanupService = sessionCleanupService
    }

    func handleUnauthorizedSession() async throws {
        try await sessionCleanupService.clearLocalSessionArtifacts()
    }
}

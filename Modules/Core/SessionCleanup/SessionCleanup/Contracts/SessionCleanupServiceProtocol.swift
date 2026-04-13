public protocol SessionCleanupUserArtifactsStoreProtocol: Sendable {
    func clearUser() async
    func clearSessions() async
}

public protocol SessionCleanupServiceProtocol: Sendable {
    func clearLocalSessionArtifacts() async throws
}

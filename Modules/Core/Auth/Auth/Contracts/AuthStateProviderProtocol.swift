import Foundation

public protocol AuthStateProviderProtocol: Sendable {
    func authState() async -> AuthState
    func stateUpdates() async -> AsyncStream<AuthState>
}

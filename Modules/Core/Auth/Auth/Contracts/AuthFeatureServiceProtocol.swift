import Foundation

public protocol AuthFeatureServiceProtocol: Sendable {
    func login(email: String, password: String) async throws
    func acceptAuthenticatedSession(
        email: String,
        password: String,
        accessToken: String,
        refreshToken: String
    ) async throws
    func currentDeviceID() async throws -> String
    func logout() async throws
}

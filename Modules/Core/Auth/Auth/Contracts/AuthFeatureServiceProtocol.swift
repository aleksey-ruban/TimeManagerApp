import Foundation

public protocol AuthFeatureServiceProtocol: Sendable {
    func login(email: String, password: String) async throws
    func logout() async throws
}

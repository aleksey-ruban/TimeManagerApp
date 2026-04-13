import Foundation

protocol AuthFlowServiceProtocol: Sendable {
    func start(email: String, locale: String) async throws -> AuthStartResponse
    func verifyRegistrationCode(email: String, code: String) async throws
    func resendRegistrationCode(email: String, locale: String) async throws
    func completeRegistration(email: String, firstName: String, password: String) async throws
    func startPasswordReset(email: String, locale: String) async throws -> AuthCodeDeliveryResponse
    func resendPasswordResetCode(email: String, locale: String) async throws
    func verifyPasswordResetCode(email: String, code: String) async throws
    func completePasswordReset(email: String, newPassword: String, deviceID: String) async throws
}

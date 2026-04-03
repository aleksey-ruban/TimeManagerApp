import Foundation

public struct AuthFeatureAPIConfiguration: Sendable, Equatable {
    public let baseURL: URL
    public let startPath: String
    public let registrationVerifyPath: String
    public let registrationResendPath: String
    public let registrationCompletePath: String
    public let passwordResetStartPath: String
    public let passwordResetResendPath: String
    public let passwordResetVerifyPath: String
    public let passwordResetCompletePath: String

    public init(
        baseURL: URL,
        startPath: String = "/api/v1/auth/start",
        registrationVerifyPath: String = "/api/v1/auth/registration/verify",
        registrationResendPath: String = "/api/v1/auth/registration/resend-code",
        registrationCompletePath: String = "/api/v1/auth/registration/complete",
        passwordResetStartPath: String = "/api/v1/auth/password/reset/start",
        passwordResetResendPath: String = "/api/v1/auth/password/reset/resend-code",
        passwordResetVerifyPath: String = "/api/v1/auth/password/reset/verify",
        passwordResetCompletePath: String = "/api/v1/auth/password/reset/complete"
    ) {
        self.baseURL = baseURL
        self.startPath = startPath
        self.registrationVerifyPath = registrationVerifyPath
        self.registrationResendPath = registrationResendPath
        self.registrationCompletePath = registrationCompletePath
        self.passwordResetStartPath = passwordResetStartPath
        self.passwordResetResendPath = passwordResetResendPath
        self.passwordResetVerifyPath = passwordResetVerifyPath
        self.passwordResetCompletePath = passwordResetCompletePath
    }
}

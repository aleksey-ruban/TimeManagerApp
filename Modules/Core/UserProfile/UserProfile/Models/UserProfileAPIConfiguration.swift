import Foundation

public struct UserProfileAPIConfiguration: Sendable, Hashable {
    public let baseURL: URL
    public let userPath: String
    public let updateProfilePath: String
    public let sessionsPath: String
    public let logoutDevicePath: String
    public let logoutOthersPath: String

    public init(
        baseURL: URL,
        userPath: String = "/api/v1/auth/user",
        updateProfilePath: String = "/api/v1/auth/user/update-profile",
        sessionsPath: String = "/api/v1/auth/sessions",
        logoutDevicePath: String = "/api/v1/auth/logout/device",
        logoutOthersPath: String = "/api/v1/auth/logout/others"
    ) {
        self.baseURL = baseURL
        self.userPath = userPath
        self.updateProfilePath = updateProfilePath
        self.sessionsPath = sessionsPath
        self.logoutDevicePath = logoutDevicePath
        self.logoutOthersPath = logoutOthersPath
    }
}

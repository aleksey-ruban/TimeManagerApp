import Foundation

public struct UserResponseDTO: Sendable, Codable, Hashable {
    public let firstName: String?
    public let email: String?

    public init(
        firstName: String?,
        email: String?
    ) {
        self.firstName = firstName
        self.email = email
    }
}

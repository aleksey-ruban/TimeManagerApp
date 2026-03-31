import Foundation

struct AuthCredentials: Sendable, Codable, Equatable {
    let email: String
    let password: String

    init(
        email: String,
        password: String
    ) {
        self.email = email
        self.password = password
    }
}

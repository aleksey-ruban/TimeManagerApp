import Foundation

protocol AuthCodeResendDateProviding: Sendable {
    func makeResendAvailableAt() -> Date
}

struct DefaultAuthCodeResendDateProvider: AuthCodeResendDateProviding {
    func makeResendAvailableAt() -> Date {
        Date().addingTimeInterval(60)
    }
}

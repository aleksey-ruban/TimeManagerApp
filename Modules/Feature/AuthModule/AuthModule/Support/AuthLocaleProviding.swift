import Foundation

protocol AuthLocaleProviding: Sendable {
    func localeCode() -> String
}

import Foundation

struct SystemAuthLocaleProvider: AuthLocaleProviding {
    func localeCode() -> String {
        guard
            let preferredLanguage = Locale.preferredLanguages.first,
            let languageCode = preferredLanguage.split(separator: "-").first,
            languageCode.isEmpty == false
        else {
            return "en"
        }

        return String(languageCode)
    }
}

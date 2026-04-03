import Foundation
import CoreNetwork

enum AppConfiguration {
    static func apiBaseURL() -> URL {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
            let url = URL(string: rawValue)
        else {
            assertionFailure("Missing or invalid APIBaseURL in Info.plist")
            return URL(string: "https://armap-design.ru")!
        }

        return url
    }

    static func networkLoggingConfiguration() -> NetworkLoggingConfiguration {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: "NetworkLoggingMode") as? String else {
            return .debugOnly
        }

        return NetworkLoggingConfiguration(mode: NetworkLoggingMode(rawValue: rawValue) ?? .debugOnly)
    }
}

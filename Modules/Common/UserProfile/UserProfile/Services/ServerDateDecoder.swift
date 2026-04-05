import Foundation

enum ServerDateDecoder {
    static func decode(from decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)

        if let date = fractionalSecondsFormatter.date(from: stringValue) {
            return date
        }

        if let date = standardFormatter.date(from: stringValue) {
            return date
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid server date: \(stringValue)"
        )
    }

    private nonisolated(unsafe) static let fractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private nonisolated(unsafe) static let standardFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

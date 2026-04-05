import Foundation

public struct SnapshotVersion: Sendable, Hashable, Comparable, Codable {
    public static let zero = SnapshotVersion(Int64(0))

    public let rawValue: Decimal

    public init(_ rawValue: Decimal) {
        self.rawValue = rawValue
    }

    public init(_ value: Int64) {
        self.rawValue = Decimal(value)
    }

    public static func < (lhs: SnapshotVersion, rhs: SnapshotVersion) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let decimal = try? container.decode(Decimal.self) {
            self.rawValue = decimal
            return
        }

        let stringValue = try container.decode(String.self)
        guard let decimal = Decimal(string: stringValue, locale: Locale(identifier: "en_US_POSIX")) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid snapshot version: \(stringValue)")
        }

        self.rawValue = decimal
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

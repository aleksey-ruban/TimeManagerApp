import Foundation

enum SyncDateCodec {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func day(from string: String) throws -> Date {
        guard let date = dayFormatter.date(from: string) else {
            throw CommonSyncError.invalidDateString(string)
        }
        return date
    }
}

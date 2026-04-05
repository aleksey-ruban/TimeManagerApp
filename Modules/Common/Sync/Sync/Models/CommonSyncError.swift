import Foundation

public enum CommonSyncError: Error, LocalizedError, Sendable {
    case responseCountMismatch(stage: String, expected: Int, received: Int)
    case unsupportedPayload(stage: String)
    case invalidDateString(String)
    case pushRejected(stage: String, localID: UUID, status: String?)

    public var errorDescription: String? {
        switch self {
        case let .responseCountMismatch(stage, expected, received):
            return "Sync response count mismatch for stage \(stage). Expected \(expected), received \(received)."
        case let .unsupportedPayload(stage):
            return "Unsupported pull payload for stage \(stage)."
        case let .invalidDateString(value):
            return "Invalid date string: \(value)"
        case let .pushRejected(stage, localID, status):
            return "Push rejected for stage \(stage), localID \(localID.uuidString), status: \(status ?? "UNKNOWN")."
        }
    }
}

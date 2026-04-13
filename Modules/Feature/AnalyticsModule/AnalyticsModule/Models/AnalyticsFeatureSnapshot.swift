import Domain
import Foundation

struct AnalyticsFeatureSnapshot: Sendable {
    let controlState: ChronometryControlState
    let historyItems: [ChronometryHistoryItem]
}

enum ChronometryControlState: Sendable {
    case readyToStart(ReadyToStartState)
    case inProgress(ActiveChronometryState)
    case readyToFinish(ActiveChronometryState)
    case cooldown(CooldownState)
}

struct ReadyToStartState: Sendable, Equatable {
    let suggestedFirstDay: Date
    let startsToday: Bool
}

struct ActiveChronometryState: Sendable, Equatable {
    let chronometryID: UUID
    let firstDay: Date
    let lastDay: Date
    let recordedDays: Int
    let remainingDays: Int
    let finishAvailableFrom: Date
    let isScheduled: Bool
}

struct CooldownState: Sendable, Equatable {
    let previousChronometryID: UUID
    let previousLastDay: Date
    let recommendedStartDate: Date
}

struct ChronometryHistoryItem: Sendable {
    let chronometry: Chronometry
    let analyticsStatus: ChronometryAnalyticsStatus
}

enum ChronometryAnalyticsStatus: Sendable {
    case ready(ChronometryAnalyticsReport)
    case awaitingSync
    case pendingRemoteFetch
}

struct ChronometryAnalyticsReport: Sendable {
    let fetchedAt: Date
    let daySummaries: [ChronometryAnalyticsDaySummary]
    let recommendationGroups: [ChronometryRecommendationGroup]

    var recommendationCount: Int {
        recommendationGroups.count
    }
}

struct ChronometryAnalyticsDaySummary: Sendable, Equatable {
    let date: Date
    let workTime: Int64
    let leisureTime: Int64
    let restTime: Int64
    let isWorkDay: Bool
    let workDayDuration: Int64
    let focusScore: Double?
    let issues: [ChronometryDayIssueSummary]
}

struct ChronometryDayIssueSummary: Sendable, Equatable {
    let code: ChronometryIssueCode
    let severity: ChronometryIssueSeverity
    let recommendation: String
    let parameters: [ChronometryIssueParameter]
}

struct ChronometryRecommendationGroup: Sendable, Equatable {
    let code: ChronometryIssueCode
    let severity: ChronometryIssueSeverity
    let recommendation: String
    let parameters: [ChronometryIssueParameter]
    let dayOccurrences: [ChronometryRecommendationDayOccurrence]
    let isWeeklySummary: Bool
}

struct ChronometryRecommendationDayOccurrence: Sendable, Equatable {
    let date: Date
    let severity: ChronometryIssueSeverity
    let parameters: [ChronometryIssueParameter]
}

struct ChronometryIssueParameter: Sendable, Equatable, Codable {
    let key: String
    let value: AnalyticsPrimitiveValue
}

enum AnalyticsPrimitiveValue: Sendable, Equatable, Hashable, Codable {
    case string(String)
    case integer(Int64)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .integer(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.typeMismatch(
                AnalyticsPrimitiveValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported primitive value")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .integer(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

enum ChronometryIssueCode: String, Sendable, CaseIterable, Codable {
    case lowFocus = "LOW_FOCUS"
    case noBreaks = "NO_BREAKS"
    case tooManyTaskSwitches = "TOO_MANY_TASK_SWITCHES"
    case excessiveMultitasking = "EXCESSIVE_MULTITASKING"
    case fragmentedWorkday = "FRAGMENTED_WORKDAY"
    case longWorkday = "LONG_WORKDAY"
    case noDaysOff = "NO_DAYS_OFF"
    case insufficientSleep = "INSUFFICIENT_SLEEP"
    case irregularSleep = "IRREGULAR_SLEEP"
}

enum ChronometryIssueSeverity: String, Sendable, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}

struct CachedChronometryAnalytics: Sendable, Equatable {
    let analyticsID: Int64?
    let userID: Int64?
    let chronometryRemoteID: Int64
    let cachedAt: Date
    let days: [CachedChronometryDayAnalytics]
    let weeklyIssues: [CachedChronometryIssue]
}

struct CachedChronometryDayAnalytics: Sendable, Equatable {
    let dayID: Int64?
    let chronometryRemoteID: Int64
    let date: Date
    let workTime: Int64
    let leisureTime: Int64
    let restTime: Int64
    let isWorkDay: Bool
    let workDayDuration: Int64
    let focusScore: Double?
    let issues: [CachedChronometryIssue]
}

struct CachedChronometryIssue: Sendable, Equatable {
    let issueID: Int64?
    let code: ChronometryIssueCode
    let severity: ChronometryIssueSeverity
    let parameters: [ChronometryIssueParameter]
    let chronometryRemoteID: Int64?
    let dayRemoteID: Int64?
    let recommendation: String
}

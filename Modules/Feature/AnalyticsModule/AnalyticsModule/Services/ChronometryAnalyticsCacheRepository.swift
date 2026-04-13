import CoreData
import CoreStorage
import Foundation

protocol ChronometryAnalyticsCacheRepositoryProtocol: Sendable {
    func fetchCachedAnalytics(chronometryRemoteID: Int64) async throws -> CachedChronometryAnalytics?
    func save(_ analytics: CachedChronometryAnalytics) async throws
    func deleteCache(chronometryRemoteID: Int64) async throws
}

final class ChronometryAnalyticsCacheRepository: ChronometryAnalyticsCacheRepositoryProtocol, @unchecked Sendable {
    private let coreDataStack: CoreDataStackProtocol

    init(coreDataStack: CoreDataStackProtocol) {
        self.coreDataStack = coreDataStack
    }

    func fetchCachedAnalytics(chronometryRemoteID: Int64) async throws -> CachedChronometryAnalytics? {
        try await coreDataStack.performBackgroundTask { context in
            try self.fetchAnalyticsObject(chronometryRemoteID: chronometryRemoteID, context: context)?.toCachedModel()
        }
    }

    func save(_ analytics: CachedChronometryAnalytics) async throws {
        try await coreDataStack.performBackgroundTransaction { context in
            let object = try self.fetchAnalyticsObject(
                chronometryRemoteID: analytics.chronometryRemoteID,
                context: context
            ) ?? ChronometryAnalyticsCacheMO(context: context)

            object.analyticsID = analytics.analyticsID.map(NSNumber.init(value:))
            object.userID = analytics.userID.map(NSNumber.init(value:))
            object.chronometryRemoteID = NSNumber(value: analytics.chronometryRemoteID)
            object.cachedAt = analytics.cachedAt

            (object.days ?? []).forEach(context.delete)
            (object.issues ?? []).forEach(context.delete)

            for day in analytics.days {
                let dayObject = ChronometryDayAnalyticsMO(context: context)
                dayObject.dayID = day.dayID.map(NSNumber.init(value:))
                dayObject.chronometryRemoteID = NSNumber(value: day.chronometryRemoteID)
                dayObject.date = day.date
                dayObject.workTime = NSNumber(value: day.workTime)
                dayObject.leisureTime = NSNumber(value: day.leisureTime)
                dayObject.restTime = NSNumber(value: day.restTime)
                dayObject.isWorkDay = day.isWorkDay
                dayObject.workDayDuration = NSNumber(value: day.workDayDuration)
                dayObject.focusScore = day.focusScore.map(NSNumber.init(value:))
                dayObject.analytics = object

                for issue in day.issues {
                    let issueObject = ChronometryIssueAnalyticsMO(context: context)
                    try self.apply(issue: issue, to: issueObject)
                    issueObject.day = dayObject
                }
            }

            for issue in analytics.weeklyIssues {
                let issueObject = ChronometryIssueAnalyticsMO(context: context)
                try self.apply(issue: issue, to: issueObject)
                issueObject.analytics = object
            }
        }
    }

    func deleteCache(chronometryRemoteID: Int64) async throws {
        try await coreDataStack.performBackgroundTransaction { context in
            guard let object = try self.fetchAnalyticsObject(chronometryRemoteID: chronometryRemoteID, context: context) else {
                return
            }
            context.delete(object)
        }
    }

    private func fetchAnalyticsObject(
        chronometryRemoteID: Int64,
        context: NSManagedObjectContext
    ) throws -> ChronometryAnalyticsCacheMO? {
        let request = ChronometryAnalyticsCacheMO.fetchRequest()
        request.predicate = NSPredicate(format: "chronometryRemoteID == %@", NSNumber(value: chronometryRemoteID))

        let matches = try context.fetch(request)
        guard let primary = matches.first else { return nil }
        for duplicate in matches.dropFirst() {
            context.delete(duplicate)
        }
        return primary
    }

    private func apply(issue: CachedChronometryIssue, to object: ChronometryIssueAnalyticsMO) throws {
        object.issueID = issue.issueID.map(NSNumber.init(value:))
        object.codeRawValue = issue.code.rawValue
        object.severityRawValue = issue.severity.rawValue
        object.paramsData = try JSONEncoder().encode(issue.parameters)
        object.recommendation = issue.recommendation
        object.chronometryRemoteID = issue.chronometryRemoteID.map(NSNumber.init(value:))
        object.dayRemoteID = issue.dayRemoteID.map(NSNumber.init(value:))
    }
}

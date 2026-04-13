import CommonSync
import CoreData
import CoreNetwork
import CoreStorage
import CoreSync
import Domain
import Foundation
import OSLog

protocol AnalyticsFeatureServiceProtocol: AnyObject, Sendable {
    func loadSnapshotAsync() async throws -> AnalyticsFeatureSnapshot
    func loadChronometryDetail(id: UUID) async throws -> ChronometryDetailSnapshot
    func refreshAnalyticsIfNeeded() async
    func startChronometry(force: Bool) async throws
    func finishActiveChronometry() async throws
    func deleteChronometry(id: UUID) async throws
}

final class AnalyticsFeatureService: AnalyticsFeatureServiceProtocol, @unchecked Sendable {
    private static let logger = Logger(
        subsystem: "com.alekseyruban.TimeManagerApp",
        category: "AnalyticsFeatureService"
    )

    private let coreDataStack: CoreDataStackProtocol
    private let syncService: AppSyncServiceProtocol
    private let updateCenter: AnalyticsFeatureUpdateCenter
    private let remoteService: AnalyticsFeatureRemoteServiceProtocol
    private let cacheRepository: ChronometryAnalyticsCacheRepositoryProtocol
    private let timelinePolicy: ChronometryTimelinePolicy
    private let reportBuilder: ChronometryAnalyticsReportBuilder
    private let nowProvider: @Sendable () -> Date
    private let timeZoneProvider: @Sendable () -> TimeZone
    private let syncScheduler = AnalyticsFeatureTaskScheduler()
    private let refreshScheduler = AnalyticsFeatureTaskScheduler()

    init(
        coreDataStack: CoreDataStackProtocol,
        syncService: AppSyncServiceProtocol,
        remoteService: AnalyticsFeatureRemoteServiceProtocol,
        cacheRepository: ChronometryAnalyticsCacheRepositoryProtocol,
        updateCenter: AnalyticsFeatureUpdateCenter = .shared,
        timelinePolicy: ChronometryTimelinePolicy = .init(),
        reportBuilder: ChronometryAnalyticsReportBuilder = .init(),
        nowProvider: @escaping @Sendable () -> Date = Date.init,
        timeZoneProvider: @escaping @Sendable () -> TimeZone = { .current }
    ) {
        self.coreDataStack = coreDataStack
        self.syncService = syncService
        self.remoteService = remoteService
        self.cacheRepository = cacheRepository
        self.updateCenter = updateCenter
        self.timelinePolicy = timelinePolicy
        self.reportBuilder = reportBuilder
        self.nowProvider = nowProvider
        self.timeZoneProvider = timeZoneProvider
    }

    func loadSnapshotAsync() async throws -> AnalyticsFeatureSnapshot {
        let chronometries = try await fetchChronometries()
        let historyChronometries = chronometries
            .filter { $0.isDeleted == false && $0.isFinished }
            .sorted { lhs, rhs in
                if lhs.endDate == rhs.endDate {
                    return lhs.startDate > rhs.startDate
                }
                return lhs.endDate > rhs.endDate
            }

        let caches = try await fetchAnalyticsCacheMap(
            for: historyChronometries.compactMap(\.remoteID)
        )

        return AnalyticsFeatureSnapshot(
            controlState: makeControlState(from: chronometries),
            historyItems: historyChronometries.map { chronometry in
                ChronometryHistoryItem(
                    chronometry: chronometry,
                    analyticsStatus: makeAnalyticsStatus(for: chronometry, caches: caches)
                )
            }
        )
    }

    func loadChronometryDetail(id: UUID) async throws -> ChronometryDetailSnapshot {
        let chronometry = try await fetchChronometry(id: id)
        let analyticsStatus = try await loadAnalyticsStatus(for: chronometry)

        return ChronometryDetailSnapshot(
            chronometry: chronometry,
            analyticsStatus: analyticsStatus,
            activityTimelineEntries: makeActivityTimelineEntries(from: chronometry)
        )
    }

    func refreshAnalyticsIfNeeded() async {
        await refreshScheduler.schedule { [weak self] in
            guard let self else { return }
            await self.performAnalyticsRefresh()
        }
    }

    func startChronometry(force: Bool) async throws {
        let now = nowProvider()
        let timeZone = timeZoneProvider()
        let activeChronometry = try await fetchActiveChronometry()

        guard activeChronometry == nil else {
            throw AnalyticsFeatureServiceError.activeChronometryExists
        }

        if force == false, let latestFinished = try await fetchLatestFinishedChronometry() {
            let recommendedDate = timelinePolicy.recommendedStartDate(after: latestFinished)
            if now < recommendedDate {
                throw AnalyticsFeatureServiceError.cooldownActive(recommendedDate)
            }
        }

        let firstDay = timelinePolicy.proposedFirstDay(for: now, timeZone: timeZone)
        let lastDay = timelinePolicy.lastDay(forFirstDay: firstDay, timeZone: timeZone)

        try await coreDataStack.performBackgroundTransaction { context in
            let object = ChronometryMO(context: context)
            object.localID = UUID()
            object.remoteID = nil
            object.lastModifiedVersion = nil
            object.startDate = firstDay
            object.endDate = lastDay
            object.isFinished = false
            object.timeZone = timeZone.identifier
            object.isDirty = true
            object.syncDeleted = false
        }

        notifyDidChange()
        scheduleSync()
    }

    func finishActiveChronometry() async throws {
        try await markActiveChronometryFinished(at: nowProvider())

        notifyDidChange()
        do {
            _ = try await syncService.run(trigger: .localChange)
        } catch {
            guard shouldRetryFinishAfterSync(for: error) else {
                throw error
            }

            Self.logger.info("Chronometry finish rejected due to outdated version. Retrying after sync.")
            _ = try await syncService.run(trigger: .retry)
            try await markActiveChronometryFinished(at: nowProvider())
            notifyDidChange()
            _ = try await syncService.run(trigger: .localChange)
        }

        await refreshAnalyticsIfNeeded()
    }

    func deleteChronometry(id: UUID) async throws {
        let remoteID = try await coreDataStack.performBackgroundTransaction { context in
            let request = ChronometryMO.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "localID == %@", id as CVarArg)
            guard let object = try context.fetch(request).first else {
                throw AnalyticsFeatureServiceError.objectNotFound
            }

            let remoteID = object.remoteIDValue
            object.syncDeleted = true
            object.isDirty = true
            return remoteID
        }

        if let remoteID {
            try? await cacheRepository.deleteCache(chronometryRemoteID: remoteID)
        }

        notifyDidChange()
        scheduleSync()
    }
}

private extension AnalyticsFeatureService {
    func markActiveChronometryFinished(at now: Date) async throws {
        try await coreDataStack.performBackgroundTransaction { context in
            guard let object = try self.fetchMostRecentActiveChronometry(context: context) else {
                throw AnalyticsFeatureServiceError.objectNotFound
            }

            let chronometry = object.toDTO()
            guard self.timelinePolicy.canFinish(chronometry, now: now) else {
                throw AnalyticsFeatureServiceError.finishUnavailable(
                    self.timelinePolicy.finishAvailableFrom(chronometry)
                )
            }

            object.isFinished = true
            object.isDirty = true
        }
    }

    func shouldRetryFinishAfterSync(for error: Error) -> Bool {
        guard case let CommonSyncError.pushRejected(stage, _, _, errorCode, errorMessage) = error else {
            return false
        }

        guard stage == CommonSyncStageIDs.chronometries.rawValue else {
            return false
        }

        return errorCode == "CHRONOMETRY_ERROR" && errorMessage == "Version of object outdated"
    }

    func fetchChronometries() async throws -> [Chronometry] {
        try await coreDataStack.performBackgroundTask { context in
            let request = ChronometryMO.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
            return try context.fetch(request)
                .map { $0.toDTO() }
                .filter { $0.isDeleted == false }
        }
    }

    func fetchLatestFinishedChronometry() async throws -> Chronometry? {
        try await coreDataStack.performBackgroundTask { context in
            let request = ChronometryMO.fetchRequest()
            request.fetchLimit = 1
            request.sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: false)]
            request.predicate = NSPredicate(format: "isFinished == YES AND syncDeleted == NO")
            return try context.fetch(request).first?.toDTO()
        }
    }

    func fetchChronometry(id: UUID) async throws -> Chronometry {
        try await coreDataStack.performBackgroundTask { context in
            let request = ChronometryMO.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "localID == %@", id as CVarArg)

            guard let object = try context.fetch(request).first else {
                throw AnalyticsFeatureServiceError.objectNotFound
            }

            return object.toDTO()
        }
    }

    func fetchActiveChronometry() async throws -> Chronometry? {
        try await coreDataStack.performBackgroundTask { context in
            try self.fetchMostRecentActiveChronometry(context: context)?.toDTO()
        }
    }

    func fetchMostRecentActiveChronometry(
        context: NSManagedObjectContext
    ) throws -> ChronometryMO? {
        let request = ChronometryMO.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.predicate = NSPredicate(format: "isFinished == NO AND syncDeleted == NO")
        return try context.fetch(request).first
    }

    func fetchAnalyticsCacheMap(for remoteIDs: [Int64]) async throws -> [Int64: CachedChronometryAnalytics] {
        try await coreDataStack.performBackgroundTask { context in
            guard remoteIDs.isEmpty == false else { return [:] }
            let request = ChronometryAnalyticsCacheMO.fetchRequest()
            request.predicate = NSPredicate(format: "chronometryRemoteID IN %@", remoteIDs.map(NSNumber.init(value:)))
            let objects = try context.fetch(request)
            return Dictionary(uniqueKeysWithValues: objects.map { ($0.chronometryRemoteIDValue, $0.toCachedModel()) })
        }
    }

    func makeControlState(from chronometries: [Chronometry]) -> ChronometryControlState {
        let activeChronometries = chronometries
            .filter { $0.isDeleted == false && $0.isFinished == false }
            .sorted { $0.startDate > $1.startDate }

        let now = nowProvider()
        if let active = activeChronometries.first {
            let recordedDays = timelinePolicy.recordedDays(for: active, asOf: now)
            let lastDay = active.endDate
            let state = ActiveChronometryState(
                chronometryID: active.localID,
                firstDay: active.startDate,
                lastDay: lastDay,
                recordedDays: recordedDays,
                remainingDays: max(0, ChronometryTimelinePolicy.trackingDurationDays - recordedDays),
                finishAvailableFrom: timelinePolicy.finishAvailableFrom(active),
                isScheduled: timelinePolicy.isScheduled(active, now: now)
            )
            if timelinePolicy.canFinish(active, now: now) {
                return .readyToFinish(state)
            }
            return .inProgress(state)
        }

        let finished = chronometries
            .filter { $0.isDeleted == false && $0.isFinished }
            .sorted { $0.endDate > $1.endDate }

        if let latestFinished = finished.first {
            let recommendedDate = timelinePolicy.recommendedStartDate(after: latestFinished)
            if now < recommendedDate {
                return .cooldown(
                    CooldownState(
                        previousChronometryID: latestFinished.localID,
                        previousLastDay: latestFinished.endDate,
                        recommendedStartDate: recommendedDate
                    )
                )
            }
        }

        let suggestedFirstDay = timelinePolicy.proposedFirstDay(for: now, timeZone: timeZoneProvider())
        return .readyToStart(
            ReadyToStartState(
                suggestedFirstDay: suggestedFirstDay,
                startsToday: Calendar.current.isDate(now, inSameDayAs: suggestedFirstDay)
            )
        )
    }

    func makeAnalyticsStatus(
        for chronometry: Chronometry,
        caches: [Int64: CachedChronometryAnalytics]
    ) -> ChronometryAnalyticsStatus {
        guard let remoteID = chronometry.remoteID else {
            return .awaitingSync
        }

        guard let cache = caches[remoteID] else {
            return .pendingRemoteFetch
        }

        return .ready(reportBuilder.build(from: cache))
    }

    func loadAnalyticsStatus(for chronometry: Chronometry) async throws -> ChronometryAnalyticsStatus {
        guard let remoteID = chronometry.remoteID else {
            return .awaitingSync
        }

        if let cachedAnalytics = try await cacheRepository.fetchCachedAnalytics(chronometryRemoteID: remoteID) {
            return .ready(reportBuilder.build(from: cachedAnalytics))
        }

        return .pendingRemoteFetch
    }

    func makeActivityTimelineEntries(from chronometry: Chronometry) -> [ChronometryActivityTimelineEntry] {
        let categoriesByRemoteID = Dictionary(
            uniqueKeysWithValues: chronometry.categorySnapshots.compactMap { category in
                category.remoteID.map { ($0, category) }
            }
        )
        let activitiesByRemoteID = Dictionary(
            uniqueKeysWithValues: chronometry.activitySnapshots.compactMap { activity in
                activity.remoteID.map { ($0, activity) }
            }
        )

        return chronometry.activityRecordSnapshots.map { record in
            let activity = record.activitySnapshotRemoteID.flatMap { activitiesByRemoteID[$0] }
            let category = activity?.categorySnapshotRemoteID.flatMap { categoriesByRemoteID[$0] }
            let variationName = activity?.variations.first(where: {
                $0.remoteID == record.variationSnapshotRemoteID
            })?.value

            return ChronometryActivityTimelineEntry(
                startedAt: record.startedAt,
                endedAt: record.endedAt,
                activityName: activity?.name ?? "Активность",
                categoryName: category?.baseName,
                variationName: variationName,
                iconName: activity?.iconName ?? "circle.fill",
                color: activity?.color.analyticsUIColor ?? .gray
            )
        }
        .sorted { $0.startedAt < $1.startedAt }
    }

    func performAnalyticsRefresh() async {
        do {
            let snapshot = try await loadSnapshotAsync()
            let remoteIDs = snapshot.historyItems.compactMap { item -> Int64? in
                guard item.chronometry.remoteID != nil else { return nil }
                switch item.analyticsStatus {
                case let .ready(report):
                    let cacheAge = nowProvider().timeIntervalSince(report.fetchedAt)
                    return cacheAge >= 24 * 60 * 60 ? item.chronometry.remoteID : nil
                case .pendingRemoteFetch:
                    return item.chronometry.remoteID
                case .awaitingSync:
                    return nil
                }
            }

            guard remoteIDs.isEmpty == false else { return }

            var changed = false
            for remoteID in remoteIDs {
                do {
                    if let analytics = try await remoteService.fetchAnalytics(for: remoteID) {
                        try await cacheRepository.save(analytics)
                        changed = true
                    }
                } catch let error as NetworkError {
                    if case .transportError = error {
                        Self.logger.info("Analytics refresh fell back to cache for chronometryRemoteID=\(remoteID)")
                        continue
                    }
                } catch {
                    Self.logger.error("Analytics refresh failed. chronometryRemoteID=\(remoteID) error='\(error.localizedDescription, privacy: .public)'")
                }
            }

            if changed {
                notifyDidChange()
            }
        } catch {
            Self.logger.error("Analytics refresh preflight failed. error='\(error.localizedDescription, privacy: .public)'")
        }
    }

    func scheduleSync() {
        Task { [syncScheduler] in
            await syncScheduler.schedule { [weak self] in
                guard let self else { return }
                do {
                    _ = try await self.syncService.run(trigger: .localChange)
                } catch {
                    Self.logger.error("Local chronometry sync failed. error='\(error.localizedDescription, privacy: .public)'")
                }
            }
        }
    }

    func notifyDidChange() {
        updateCenter.notifyDidChange()
    }
}

enum AnalyticsFeatureServiceError: LocalizedError {
    case objectNotFound
    case activeChronometryExists
    case cooldownActive(Date)
    case finishUnavailable(Date)

    var errorDescription: String? {
        switch self {
        case .objectNotFound:
            return "Хронометраж не найден."
        case .activeChronometryExists:
            return "Сначала завершите или удалите текущий хронометраж."
        case let .cooldownActive(date):
            return "Новый хронометраж лучше начать после \(Self.recommendedDateFormatter.string(from: date))."
        case let .finishUnavailable(date):
            return "Завершение станет доступно после \(Self.finishDateFormatter.string(from: date))."
        }
    }

    private static let recommendedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        return formatter
    }()

    private static let finishDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private actor AnalyticsFeatureTaskScheduler {
    private var activeTask: Task<Void, Never>?
    private var hasPendingRun = false

    func schedule(_ operation: @escaping @Sendable () async -> Void) {
        guard activeTask == nil else {
            hasPendingRun = true
            return
        }

        activeTask = Task {
            await operation()
            finish(operation)
        }
    }

    private func finish(_ operation: @escaping @Sendable () async -> Void) {
        activeTask = nil
        guard hasPendingRun else { return }
        hasPendingRun = false
        schedule(operation)
    }
}

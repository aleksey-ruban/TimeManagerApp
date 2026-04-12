import CommonSync
import CoreData
import CoreStorage
import CoreSync
import Domain
import Foundation
import OSLog

protocol ActivitiesFeatureServiceProtocol: AnyObject, Sendable {
    @MainActor
    func loadSnapshot() throws -> ActivitiesFeatureSnapshot
    func loadSnapshotAsync() async throws -> ActivitiesFeatureSnapshot
    func createCategory(named name: String) async throws -> Domain.Category
    func deleteCategory(id: UUID) async throws
    func saveActivity(_ draft: ActivityDraft, editingActivityID: UUID?) async throws -> Activity
    func deleteActivity(id: UUID) async throws
    func launchActivity(id: UUID, variationID: UUID?) async throws -> ActivityRecord?
    func saveActivityRecord(
        activityID: UUID,
        startedAt: Date,
        endedAt: Date?,
        variationID: UUID?,
        editingRecordID: UUID?
    ) async throws -> ActivityRecord
    func stopActivityRecord(id: UUID, endedAt: Date) async throws -> ActivityRecord?
    func updateActivityRecord(
        id: UUID,
        startedAt: Date,
        endedAt: Date?,
        variationID: UUID?
    ) async throws -> ActivityRecord?
    func deleteActivityRecord(id: UUID) async throws
}

struct ActivitiesFeatureSnapshot {
    let categories: [Domain.Category]
    let activities: [Activity]
    let activityRecords: [ActivityRecord]
}

final class ActivitiesFeatureService: ActivitiesFeatureServiceProtocol, @unchecked Sendable {
    private static let logger = Logger(
        subsystem: "com.alekseyruban.TimeManagerApp",
        category: "ActivitiesFeatureService"
    )

    private let coreDataStack: CoreDataStackProtocol
    private let syncService: AppSyncServiceProtocol
    private let updateCenter: ActivitiesFeatureUpdateCenter
    private let syncScheduler = ActivitiesFeatureSyncScheduler()

    init(
        coreDataStack: CoreDataStackProtocol,
        syncService: AppSyncServiceProtocol,
        updateCenter: ActivitiesFeatureUpdateCenter = .shared
    ) {
        self.coreDataStack = coreDataStack
        self.syncService = syncService
        self.updateCenter = updateCenter
        let storeURL = coreDataStack.persistentContainer.persistentStoreDescriptions.first?.url?.absoluteString ?? "nil"
        Self.logger.info("ActivitiesFeatureService initialized. persistentStoreURL=\(storeURL, privacy: .public)")
    }

    @MainActor
    func loadSnapshot() throws -> ActivitiesFeatureSnapshot {
        try makeSnapshot(context: coreDataStack.viewContext)
    }

    func loadSnapshotAsync() async throws -> ActivitiesFeatureSnapshot {
        try await coreDataStack.performBackgroundTask { context in
            try self.makeSnapshot(context: context)
        }
    }

    func createCategory(named name: String) async throws -> Domain.Category {
        Self.logger.info("createCategory started. name='\(name, privacy: .public)'")
        let localID: UUID = try await coreDataStack.performBackgroundTransaction { context in
            let category = CategoryMO(context: context)
            category.localID = UUID()
            category.baseName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            category.code = nil
            category.isDirty = true
            category.syncDeleted = false
            category.remoteID = nil
            category.lastModifiedVersion = nil
            return category.localID
        }
        Self.logger.info("createCategory persisted locally. localID=\(localID.uuidString, privacy: .public)")
        await logDatabaseState(stage: "createCategory after local persist")

        let category = try await fetchCategory(id: localID)
        notifyDidChange()
        scheduleSyncIfPossible()
        return category
    }

    func deleteCategory(id: UUID) async throws {
        Self.logger.info("deleteCategory started. id=\(id.uuidString, privacy: .public)")
        try await coreDataStack.performBackgroundTransaction { context in
            guard let category = try self.fetchCategoryMO(id: id, context: context) else { return }

            category.syncDeleted = true
            category.isDirty = true

            let request = ActivityMO.fetchRequest()
            request.predicate = NSPredicate(format: "category.localID == %@", id as CVarArg)
            let linkedActivities = try context.fetch(request)
            linkedActivities.forEach {
                $0.category = nil
                $0.isDirty = true
            }
        }
        Self.logger.info("deleteCategory persisted locally. id=\(id.uuidString, privacy: .public)")

        notifyDidChange()
        scheduleSyncIfPossible()
    }

    func saveActivity(_ draft: ActivityDraft, editingActivityID: UUID?) async throws -> Activity {
        Self.logger.info(
            "saveActivity started. editingActivityID=\(editingActivityID?.uuidString ?? "nil", privacy: .public), name='\(draft.name, privacy: .public)', categoryID=\(draft.categoryID?.uuidString ?? "nil", privacy: .public), variationsCount=\(draft.variations.count)"
        )
        let localID: UUID = try await coreDataStack.performBackgroundTransaction { context in
            let existingActivity = try self.fetchActivityMO(id: editingActivityID, context: context)

            if let editingActivityID, existingActivity == nil {
                Self.logger.error(
                    "saveActivity failed to find existing activity for editing. editingActivityID=\(editingActivityID.uuidString, privacy: .public)"
                )
                throw ActivitiesFeatureServiceError.objectNotFound
            }

            let activity = existingActivity ?? ActivityMO(context: context)
            if let existingActivity {
                Self.logger.info(
                    "saveActivity will update existing activity. localID=\(existingActivity.localID.uuidString, privacy: .public), remoteID=\(existingActivity.remoteIDValue.map(String.init) ?? "nil", privacy: .public)"
                )
            } else {
                activity.localID = UUID()
                activity.remoteID = nil
                activity.lastModifiedVersion = nil
                Self.logger.info(
                    "saveActivity will create new activity. localID=\(activity.localID.uuidString, privacy: .public)"
                )
            }

            activity.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            activity.iconName = draft.iconName
            activity.color = draft.color
            activity.category = try self.fetchCategoryMO(id: draft.categoryID, context: context)
            activity.isDirty = true
            activity.syncDeleted = false

            try self.applyVariations(draft.variations, to: activity, context: context)
            return activity.localID
        }
        Self.logger.info("saveActivity persisted locally. localID=\(localID.uuidString, privacy: .public)")
        await logDatabaseState(stage: "saveActivity after local persist")

        let activity = try await fetchActivity(id: localID)
        notifyDidChange()
        scheduleSyncIfPossible()
        return activity
    }

    func deleteActivity(id: UUID) async throws {
        Self.logger.info("deleteActivity started. id=\(id.uuidString, privacy: .public)")
        try await coreDataStack.performBackgroundTransaction { context in
            guard let activity = try self.fetchActivityMO(id: id, context: context) else { return }
            activity.syncDeleted = true
            activity.isDirty = true
        }
        Self.logger.info("deleteActivity persisted locally. id=\(id.uuidString, privacy: .public)")

        notifyDidChange()
        scheduleSyncIfPossible()
    }

    func launchActivity(id: UUID, variationID: UUID?) async throws -> ActivityRecord? {
        Self.logger.info(
            "launchActivity started. activityID=\(id.uuidString, privacy: .public), variationID=\(variationID?.uuidString ?? "nil", privacy: .public)"
        )
        return try await saveActivityRecord(
            activityID: id,
            startedAt: Date(),
            endedAt: nil,
            variationID: variationID,
            editingRecordID: nil
        )
    }

    func saveActivityRecord(
        activityID: UUID,
        startedAt: Date,
        endedAt: Date?,
        variationID: UUID?,
        editingRecordID: UUID?
    ) async throws -> ActivityRecord {
        if let endedAt, endedAt < startedAt {
            throw ActivitiesFeatureServiceError.invalidDateRange
        }

        Self.logger.info(
            "saveActivityRecord started. editingRecordID=\(editingRecordID?.uuidString ?? "nil", privacy: .public), activityID=\(activityID.uuidString, privacy: .public), startedAt=\(startedAt.ISO8601Format(), privacy: .public), endedAt=\(endedAt?.ISO8601Format() ?? "nil", privacy: .public), variationID=\(variationID?.uuidString ?? "nil", privacy: .public)"
        )

        let localID: UUID = try await coreDataStack.performBackgroundTransaction { context in
            guard let activity = try self.fetchActivityMO(id: activityID, context: context) else {
                throw ActivitiesFeatureServiceError.objectNotFound
            }

            let existingRecord = try self.fetchActivityRecordMO(id: editingRecordID, context: context)

            if let editingRecordID, existingRecord == nil {
                Self.logger.error(
                    "saveActivityRecord failed to find existing record. editingRecordID=\(editingRecordID.uuidString, privacy: .public)"
                )
                throw ActivitiesFeatureServiceError.objectNotFound
            }

            let record = existingRecord ?? ActivityRecordMO(context: context)
            if existingRecord == nil {
                record.localID = UUID()
                record.remoteID = nil
                record.lastModifiedVersion = nil
                record.timeZone = TimeZone.current.identifier
                record.syncDeleted = false
            }

            record.activity = activity
            record.variation = try self.fetchVariationMO(id: variationID, context: context)
            record.startedAt = startedAt
            record.endedAt = endedAt
            record.timeZone = TimeZone.current.identifier
            record.isDirty = true
            record.syncDeleted = false

            return record.localID
        }

        Self.logger.info("saveActivityRecord persisted locally. id=\(localID.uuidString, privacy: .public)")
        await logDatabaseState(stage: "saveActivityRecord after local persist")
        let record = try await fetchActivityRecord(id: localID)
        notifyDidChange()
        scheduleSyncIfPossible()
        return record
    }

    func stopActivityRecord(id: UUID, endedAt: Date) async throws -> ActivityRecord? {
        Self.logger.info(
            "stopActivityRecord started. id=\(id.uuidString, privacy: .public), endedAt=\(endedAt.ISO8601Format(), privacy: .public)"
        )
        let localID: UUID? = try await coreDataStack.performBackgroundTransaction { context in
            guard let record = try self.fetchActivityRecordMO(id: id, context: context) else { return nil }
            record.endedAt = endedAt
            record.isDirty = true
            return record.localID
        }

        guard let localID else {
            Self.logger.error("stopActivityRecord failed to persist locally. id=\(id.uuidString, privacy: .public)")
            return nil
        }
        Self.logger.info("stopActivityRecord persisted locally. id=\(localID.uuidString, privacy: .public)")
        await logDatabaseState(stage: "stopActivityRecord after local persist")
        let record = try await fetchActivityRecord(id: localID)
        notifyDidChange()
        scheduleSyncIfPossible()
        return record
    }

    func updateActivityRecord(
        id: UUID,
        startedAt: Date,
        endedAt: Date?,
        variationID: UUID?
    ) async throws -> ActivityRecord? {
        Self.logger.info(
            "updateActivityRecord started. id=\(id.uuidString, privacy: .public), startedAt=\(startedAt.ISO8601Format(), privacy: .public), endedAt=\(endedAt?.ISO8601Format() ?? "nil", privacy: .public), variationID=\(variationID?.uuidString ?? "nil", privacy: .public)"
        )
        let localID: UUID? = try await coreDataStack.performBackgroundTransaction { context in
            guard let record = try self.fetchActivityRecordMO(id: id, context: context) else { return nil }
            record.startedAt = startedAt
            record.endedAt = endedAt
            record.variation = try self.fetchVariationMO(id: variationID, context: context)
            record.isDirty = true
            return record.localID
        }

        guard let localID else {
            Self.logger.error("updateActivityRecord failed to persist locally. id=\(id.uuidString, privacy: .public)")
            return nil
        }
        Self.logger.info("updateActivityRecord persisted locally. id=\(localID.uuidString, privacy: .public)")
        await logDatabaseState(stage: "updateActivityRecord after local persist")
        let record = try await fetchActivityRecord(id: localID)
        notifyDidChange()
        scheduleSyncIfPossible()
        return record
    }

    func deleteActivityRecord(id: UUID) async throws {
        Self.logger.info("deleteActivityRecord started. id=\(id.uuidString, privacy: .public)")
        try await coreDataStack.performBackgroundTransaction { context in
            guard let record = try self.fetchActivityRecordMO(id: id, context: context) else { return }
            record.syncDeleted = true
            record.isDirty = true
        }
        Self.logger.info("deleteActivityRecord persisted locally. id=\(id.uuidString, privacy: .public)")

        notifyDidChange()
        scheduleSyncIfPossible()
    }
}

private extension ActivitiesFeatureService {
    func makeSnapshot(context: NSManagedObjectContext) throws -> ActivitiesFeatureSnapshot {
        let categoriesRequest = CategoryMO.fetchRequest()
        categoriesRequest.sortDescriptors = [NSSortDescriptor(key: "baseName", ascending: true)]

        let activitiesRequest = ActivityMO.fetchRequest()
        activitiesRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let recordsRequest = ActivityRecordMO.fetchRequest()
        recordsRequest.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]

        let categories = try context.fetch(categoriesRequest).map { $0.toDTO() }
        let activities = try context.fetch(activitiesRequest).map { $0.toDTO() }
        let activityRecords = try context.fetch(recordsRequest).map { $0.toDTO() }

        if categories.isEmpty == false {
            Self.logger.info("loadSnapshot loaded categories from DB. count=\(categories.count)")
        }
        if activities.isEmpty == false {
            Self.logger.info("loadSnapshot loaded activities from DB. count=\(activities.count)")
        }
        if activityRecords.isEmpty == false {
            Self.logger.info("loadSnapshot loaded activityRecords from DB. count=\(activityRecords.count)")
        }
        if categories.isEmpty && activities.isEmpty && activityRecords.isEmpty {
            Self.logger.info("loadSnapshot loaded no objects from DB.")
        }

        return ActivitiesFeatureSnapshot(
            categories: categories,
            activities: activities,
            activityRecords: activityRecords
        )
    }

    func scheduleSyncIfPossible() {
        Task { [syncScheduler] in
            await syncScheduler.schedule { [self] in
                await runSyncIfPossible()
            }
        }
    }

    func runSyncIfPossible() async {
        Self.logger.info("runSyncIfPossible started. trigger=localChange")
        do {
            _ = try await syncService.run(trigger: .localChange)
            Self.logger.info("runSyncIfPossible finished successfully.")
            await logDatabaseState(stage: "runSyncIfPossible after sync")
        } catch {
            Self.logger.error("runSyncIfPossible failed. error='\(error.localizedDescription, privacy: .public)'")
            // Local state is already persisted; sync failures should not roll it back.
        }
    }

    func notifyDidChange() {
        updateCenter.notifyDidChange()
    }

    func logDatabaseState(stage: String) async {
        do {
            let state = try await coreDataStack.performBackgroundTask { context in
                let categoriesRequest = CategoryMO.fetchRequest()
                let activitiesRequest = ActivityMO.fetchRequest()
                let recordsRequest = ActivityRecordMO.fetchRequest()

                let categoryCount = try context.count(for: categoriesRequest)
                let activityCount = try context.count(for: activitiesRequest)
                let recordCount = try context.count(for: recordsRequest)
                return (categoryCount, activityCount, recordCount)
            }

            Self.logger.info(
                "\(stage, privacy: .public). dbState categories=\(state.0) activities=\(state.1) activityRecords=\(state.2)"
            )
        } catch {
            Self.logger.error(
                "\(stage, privacy: .public). failed to inspect dbState. error='\(error.localizedDescription, privacy: .public)'"
            )
        }
    }

    func fetchCategory(id: UUID) async throws -> Domain.Category {
        guard let category = try await fetchCategoryIfExists(id: id) else {
            throw ActivitiesFeatureServiceError.objectNotFound
        }
        return category
    }

    func fetchActivity(id: UUID) async throws -> Activity {
        guard let activity = try await fetchActivityIfExists(id: id) else {
            throw ActivitiesFeatureServiceError.objectNotFound
        }
        return activity
    }

    func fetchActivityRecord(id: UUID) async throws -> ActivityRecord {
        guard let record = try await fetchActivityRecordIfExists(id: id) else {
            throw ActivitiesFeatureServiceError.objectNotFound
        }
        return record
    }

    func fetchCategoryIfExists(id: UUID) async throws -> Domain.Category? {
        try await coreDataStack.performBackgroundTask { context in
            try self.fetchCategoryMO(id: id, context: context)?.toDTO()
        }
    }

    func fetchActivityIfExists(id: UUID) async throws -> Activity? {
        try await coreDataStack.performBackgroundTask { context in
            try self.fetchActivityMO(id: id, context: context)?.toDTO()
        }
    }

    func fetchActivityRecordIfExists(id: UUID) async throws -> ActivityRecord? {
        try await coreDataStack.performBackgroundTask { context in
            try self.fetchActivityRecordMO(id: id, context: context)?.toDTO()
        }
    }

    func fetchCategoryMO(id: UUID?, context: NSManagedObjectContext) throws -> CategoryMO? {
        guard let id else { return nil }
        let request = CategoryMO.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "localID == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    func fetchActivityMO(id: UUID?, context: NSManagedObjectContext) throws -> ActivityMO? {
        guard let id else { return nil }
        let request = ActivityMO.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "localID == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    func fetchActivityRecordMO(id: UUID?, context: NSManagedObjectContext) throws -> ActivityRecordMO? {
        guard let id else { return nil }
        let request = ActivityRecordMO.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "localID == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    func fetchVariationMO(id: UUID?, context: NSManagedObjectContext) throws -> ActivityVariationMO? {
        guard let id else { return nil }
        let request = ActivityVariationMO.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "localID == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    func applyVariations(
        _ variations: [ActivityDraft.VariationDraft],
        to activity: ActivityMO,
        context: NSManagedObjectContext
    ) throws {
        let currentByLocalID = Dictionary(uniqueKeysWithValues: (activity.variations ?? []).map { ($0.localID, $0) })
        let incomingIDs = Set(variations.map(\.localID))

        for variation in variations {
            let object = currentByLocalID[variation.localID] ?? ActivityVariationMO(context: context)
            object.localID = variation.localID
            object.remoteID = variation.remoteID.map(NSNumber.init(value:))
            object.value = variation.value
            object.position = Int64(variation.position)
            object.syncDeleted = variation.isDeleted
            object.activity = activity
        }

        for existing in activity.variations ?? [] where incomingIDs.contains(existing.localID) == false {
            existing.syncDeleted = true
        }
    }
}

enum ActivitiesFeatureServiceError: Error {
    case objectNotFound
    case invalidDateRange
}

private actor ActivitiesFeatureSyncScheduler {
    private var activeTask: Task<Void, Never>?
    private var hasPendingRun = false

    func schedule(_ operation: @escaping @Sendable () async -> Void) {
        guard activeTask == nil else {
            hasPendingRun = true
            return
        }

        activeTask = Task {
            await operation()
            self.finish(operation)
        }
    }

    private func finish(_ operation: @escaping @Sendable () async -> Void) {
        activeTask = nil
        guard hasPendingRun else { return }
        hasPendingRun = false
        schedule(operation)
    }
}

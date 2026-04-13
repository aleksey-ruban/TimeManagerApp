import Foundation
import Domain
@testable import FeatureActivitiesModule

final class ActivitiesFeatureServiceSpy: ActivitiesFeatureServiceProtocol, @unchecked Sendable {
    var snapshot = ActivitiesFeatureSnapshot(categories: [], activities: [], activityRecords: [])
    var snapshotError: Error?

    var createdCategoryName: String?
    var createdCategoryResult: Result<Domain.Category, Error> = .failure(TestError.notStubbed)

    var deletedCategoryID: UUID?
    var deletedCategoryError: Error?

    var savedActivityDraft: ActivityDraft?
    var savedActivityEditingID: UUID?
    var savedActivityResult: Result<Activity, Error> = .failure(TestError.notStubbed)

    var deletedActivityID: UUID?
    var deletedActivityError: Error?

    var launchedActivityID: UUID?
    var launchedVariationID: UUID?
    var launchedActivityResult: Result<ActivityRecord?, Error> = .success(nil)

    var savedRecordInput: (activityID: UUID, startedAt: Date, endedAt: Date?, variationID: UUID?, editingRecordID: UUID?)?
    var savedRecordResult: Result<ActivityRecord, Error> = .failure(TestError.notStubbed)

    var stoppedRecordID: UUID?
    var stoppedRecordEndedAt: Date?
    var stoppedRecordResult: Result<ActivityRecord?, Error> = .success(nil)

    var deletedRecordID: UUID?
    var deletedRecordError: Error?

    @MainActor
    func loadSnapshot() throws -> ActivitiesFeatureSnapshot {
        if let snapshotError { throw snapshotError }
        return snapshot
    }

    func loadSnapshotAsync() async throws -> ActivitiesFeatureSnapshot {
        if let snapshotError { throw snapshotError }
        return snapshot
    }

    func createCategory(named name: String) async throws -> Domain.Category {
        createdCategoryName = name
        return try createdCategoryResult.get()
    }

    func deleteCategory(id: UUID) async throws {
        deletedCategoryID = id
        if let deletedCategoryError { throw deletedCategoryError }
    }

    func saveActivity(_ draft: ActivityDraft, editingActivityID: UUID?) async throws -> Activity {
        savedActivityDraft = draft
        savedActivityEditingID = editingActivityID
        return try savedActivityResult.get()
    }

    func deleteActivity(id: UUID) async throws {
        deletedActivityID = id
        if let deletedActivityError { throw deletedActivityError }
    }

    func launchActivity(id: UUID, variationID: UUID?) async throws -> ActivityRecord? {
        launchedActivityID = id
        launchedVariationID = variationID
        return try launchedActivityResult.get()
    }

    func saveActivityRecord(
        activityID: UUID,
        startedAt: Date,
        endedAt: Date?,
        variationID: UUID?,
        editingRecordID: UUID?
    ) async throws -> ActivityRecord {
        savedRecordInput = (activityID, startedAt, endedAt, variationID, editingRecordID)
        return try savedRecordResult.get()
    }

    func stopActivityRecord(id: UUID, endedAt: Date) async throws -> ActivityRecord? {
        stoppedRecordID = id
        stoppedRecordEndedAt = endedAt
        return try stoppedRecordResult.get()
    }

    func updateActivityRecord(
        id: UUID,
        startedAt: Date,
        endedAt: Date?,
        variationID: UUID?
    ) async throws -> ActivityRecord? {
        nil
    }

    func deleteActivityRecord(id: UUID) async throws {
        deletedRecordID = id
        if let deletedRecordError { throw deletedRecordError }
    }
}

enum TestError: Error {
    case notStubbed
}

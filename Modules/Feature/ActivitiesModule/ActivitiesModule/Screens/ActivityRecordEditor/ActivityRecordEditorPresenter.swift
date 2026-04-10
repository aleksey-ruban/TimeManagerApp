import CommonSync
import Domain
import Foundation

@MainActor
protocol ActivityRecordEditorView: AnyObject {
    func render(viewModel: ActivityRecordEditorViewModel)
}

@MainActor
final class ActivityRecordEditorPresenter {
    weak var view: ActivityRecordEditorView?

    private let service: ActivitiesFeatureServiceProtocol
    private let initialActivityID: UUID?
    private let activityRecordID: UUID?
    private let onSaved: (String) -> Void

    private var categories: [Domain.Category] = []
    private var activities: [Activity] = []
    private var draft = ActivityRecordEditorDraft(
        activityID: nil,
        variationID: nil,
        startedAt: Date(),
        endedAt: nil
    )
    private let observerBag = NotificationObserverBag()

    init(
        service: ActivitiesFeatureServiceProtocol,
        activityID: UUID?,
        activityRecordID: UUID?,
        onSaved: @escaping (String) -> Void
    ) {
        self.service = service
        self.initialActivityID = activityID
        self.activityRecordID = activityRecordID
        self.onSaved = onSaved
    }

    func viewDidLoad() {
        startObservingUpdates()
        Task { [weak self] in
            await self?.reloadFromSource()
        }
    }

    func didUpdateStartedAt(_ date: Date) {
        draft.startedAt = date
        if let endedAt = draft.endedAt, endedAt < date {
            draft.endedAt = date
        }
        reload()
    }

    func didToggleEndedAt(_ isEnabled: Bool) {
        if isEnabled {
            draft.endedAt = max(draft.startedAt, draft.endedAt ?? draft.startedAt)
        } else {
            draft.endedAt = nil
        }
        reload()
    }

    func didUpdateEndedAt(_ date: Date) {
        draft.endedAt = max(draft.startedAt, date)
        reload()
    }

    func didSelectVariation(_ variationID: UUID?) {
        draft.variationID = variationID
        reload()
    }

    func didTapSave() {
        guard let activityID = draft.activityID, validationMessage == nil else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                let record = try await service.saveActivityRecord(
                    activityID: activityID,
                    startedAt: draft.startedAt,
                    endedAt: draft.endedAt,
                    variationID: draft.variationID,
                    editingRecordID: activityRecordID
                )
                let activityName = activity(id: record.activityLocalID)?.name ?? "задача"
                onSaved(activityRecordID == nil ? "Запись для «\(activityName)» создана" : "Запись для «\(activityName)» обновлена")
            } catch {
                if let serviceError = error as? ActivitiesFeatureServiceError {
                    switch serviceError {
                    case .objectNotFound:
                        onSaved("Не удалось найти задачу или запись.")
                    case .invalidDateRange:
                        onSaved("Время окончания не может быть раньше времени начала.")
                    }
                } else {
                    onSaved(error.localizedDescription)
                }
            }
        }
    }

}

private extension ActivityRecordEditorPresenter {
    func startObservingUpdates() {
        guard observerBag.observers.isEmpty else { return }

        let notificationCenter = NotificationCenter.default
        observerBag.observers = [
            notificationCenter.addObserver(
                forName: ActivitiesFeatureUpdateCenter.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { [weak self] in
                    await self?.reloadFromSource()
                }
            },
            notificationCenter.addObserver(
                forName: .appSyncServiceDidFinishRun,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { [weak self] in
                    await self?.reloadFromSource()
                }
            }
        ]
    }

    var validationMessage: String? {
        guard let endedAt = draft.endedAt, endedAt < draft.startedAt else { return nil }
        return "Время окончания не может быть раньше времени начала."
    }

    func reloadFromSource() async {
        do {
            let snapshot = try await service.loadSnapshotAsync()
            categories = snapshot.categories
            activities = snapshot.activities

            if let activityRecordID,
               let activityRecord = snapshot.activityRecords.first(where: { $0.localID == activityRecordID && $0.isDeleted == false }) {
                draft = ActivityRecordEditorDraft(
                    activityID: activityRecord.activityLocalID,
                    variationID: activityRecord.variationLocalID,
                    startedAt: activityRecord.startedAt,
                    endedAt: activityRecord.endedAt
                )
            } else if draft.activityID == nil {
                draft.activityID = initialActivityID
            }
        } catch {
            categories = []
            activities = []
        }

        reload()
    }

    func reload() {
        guard let activity = activity(id: draft.activityID) else {
            view?.render(
                viewModel: ActivityRecordEditorViewModel(
                    title: activityRecordID == nil ? "Новая запись" : "Редактирование записи",
                    activity: nil,
                    categoryName: nil,
                    startedAt: draft.startedAt,
                    endedAt: draft.endedAt,
                    variationOptions: [],
                    selectedVariationID: nil,
                    validationMessage: validationMessage,
                    isSaveEnabled: false
                )
            )
            return
        }

        let variationOptions = [ActivityRecordVariationOption(id: nil, title: "Без вариации")]
            + activity.variations
                .filter { $0.isDeleted == false }
                .sorted { $0.position < $1.position }
                .map { ActivityRecordVariationOption(id: $0.localID, title: $0.value) }

        view?.render(
            viewModel: ActivityRecordEditorViewModel(
                title: activityRecordID == nil ? "Новая запись" : "Редактирование записи",
                activity: activity,
                categoryName: category(id: activity.categoryLocalID)?.baseName,
                startedAt: draft.startedAt,
                endedAt: draft.endedAt,
                variationOptions: variationOptions,
                selectedVariationID: draft.variationID,
                validationMessage: validationMessage,
                isSaveEnabled: draft.activityID != nil && validationMessage == nil
            )
        )
    }

    func activity(id: UUID?) -> Activity? {
        guard let id else { return nil }
        return activities.first(where: { $0.localID == id })
    }

    func category(id: UUID?) -> Domain.Category? {
        guard let id else { return nil }
        return categories.first(where: { $0.localID == id && $0.isDeleted == false })
    }
}

private struct ActivityRecordEditorDraft {
    var activityID: UUID?
    var variationID: UUID?
    var startedAt: Date
    var endedAt: Date?
}

struct ActivityRecordEditorViewModel {
    let title: String
    let activity: Activity?
    let categoryName: String?
    let startedAt: Date
    let endedAt: Date?
    let variationOptions: [ActivityRecordVariationOption]
    let selectedVariationID: UUID?
    let validationMessage: String?
    let isSaveEnabled: Bool
}

struct ActivityRecordVariationOption {
    let id: UUID?
    let title: String
}

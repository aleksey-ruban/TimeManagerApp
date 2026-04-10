import CommonSync
import Domain
import Foundation

@MainActor
protocol ActivityLauncherView: AnyObject {
    func render(viewModel: ActivityLauncherViewModel)
}

@MainActor
final class ActivityLauncherPresenter {
    weak var view: ActivityLauncherView?

    private let service: ActivitiesFeatureServiceProtocol
    private let onCreateRecord: () -> Void
    private let onFinished: (String) -> Void
    private var searchQuery = ""
    private var categories: [Domain.Category] = []
    private var activities: [Activity] = []
    private var activityRecords: [ActivityRecord] = []
    private let observerBag = NotificationObserverBag()

    init(
        service: ActivitiesFeatureServiceProtocol,
        onCreateRecord: @escaping () -> Void,
        onFinished: @escaping (String) -> Void
    ) {
        self.service = service
        self.onCreateRecord = onCreateRecord
        self.onFinished = onFinished
    }

    func viewDidLoad() {
        startObservingUpdates()
        Task { [weak self] in
            await self?.reloadFromSource()
        }
    }

    func didUpdateSearchQuery(_ query: String) {
        searchQuery = query
        reload()
    }

    func didSelectItem(at index: Int) {
        let items = makeItems()
        guard items.indices.contains(index) else { return }
        toggleActivity(item: items[index])
    }

    func didTapStart(at index: Int) {
        didSelectItem(at: index)
    }

    func didTapAdd() {
        onCreateRecord()
    }

}

private extension ActivityLauncherPresenter {
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

    func reloadFromSource() async {
        do {
            let snapshot = try await service.loadSnapshotAsync()
            categories = snapshot.categories
            activities = snapshot.activities
            activityRecords = snapshot.activityRecords
        } catch {
            categories = []
            activities = []
            activityRecords = []
        }
        reload()
    }

    func reload() {
        view?.render(
            viewModel: .init(
                items: makeItems(),
                emptyTitle: "Нет задач для запуска"
            )
        )
    }

    func makeItems() -> [ActivityLauncherItemViewModel] {
        filteredActivities().map { activity in
            .init(
                id: activity.localID,
                name: activity.name,
                categoryName: category(id: activity.categoryLocalID)?.baseName,
                iconName: activity.iconName,
                color: activity.color,
                activeRecord: activeRecord(for: activity.localID)
            )
        }
    }

    func toggleActivity(item: ActivityLauncherItemViewModel) {
        Task { [weak self] in
            guard let self else { return }
            let message: String?

            if let activeRecord = item.activeRecord {
                let record = try? await service.stopActivityRecord(id: activeRecord.localID, endedAt: Date())
                message = record == nil ? nil : "Остановлена задача «\(item.name)»"
            } else {
                let record = try? await service.launchActivity(id: item.id, variationID: nil)
                message = record == nil ? nil : "Запущена задача «\(item.name)»"
            }

            await reloadFromSource()

            if let message {
                onFinished(message)
            }
        }
    }

    func filteredActivities() -> [Activity] {
        let normalizedQuery = searchQuery.normalizedSearchText
        return activities
            .filter { $0.isDeleted == false }
            .filter {
                normalizedQuery.isEmpty || $0.name.normalizedSearchText.contains(normalizedQuery)
            }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    func category(id: UUID?) -> Domain.Category? {
        guard let id else { return nil }
        return categories.first(where: { $0.localID == id && $0.isDeleted == false })
    }

    func activeRecord(for activityID: UUID) -> ActivityRecord? {
        activityRecords
            .filter { $0.activityLocalID == activityID && $0.endedAt == nil && $0.isDeleted == false }
            .max(by: { $0.startedAt < $1.startedAt })
    }
}

struct ActivityLauncherViewModel {
    let items: [ActivityLauncherItemViewModel]
    let emptyTitle: String
}

struct ActivityLauncherItemViewModel {
    let id: UUID
    let name: String
    let categoryName: String?
    let iconName: String
    let color: ActivityColor
    let activeRecord: ActivityRecord?
}

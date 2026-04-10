import CommonSync
import Foundation
import Domain

@MainActor
protocol ActivityListView: AnyObject {
    func render(viewModel: ActivityListViewModel)
}

@MainActor
final class ActivityListPresenter {
    weak var view: ActivityListView?

    private let service: ActivitiesFeatureServiceProtocol
    private let onAdd: () -> Void
    private let onEdit: (UUID) -> Void
    private let onLaunch: () -> Void

    private var searchQuery = ""
    private var categories: [Domain.Category] = []
    private var activities: [Activity] = []
    private var activityRecords: [ActivityRecord] = []
    private let observerBag = NotificationObserverBag()

    init(
        service: ActivitiesFeatureServiceProtocol,
        onAdd: @escaping () -> Void,
        onEdit: @escaping (UUID) -> Void,
        onLaunch: @escaping () -> Void
    ) {
        self.service = service
        self.onAdd = onAdd
        self.onEdit = onEdit
        self.onLaunch = onLaunch
    }

    func viewDidLoad() {
        startObservingUpdates()
        reloadFromSource()
    }

    func viewWillAppear() {
        reloadFromSource()
    }

    func didUpdateSearchQuery(_ query: String) {
        searchQuery = query
        reload()
    }

    func didTapAdd() {
        onAdd()
    }

    func didTapLaunch() {
        onLaunch()
    }

    func didSelectItem(at index: Int) {
        let items = makeItems()
        guard items.indices.contains(index) else { return }
        onEdit(items[index].id)
    }

    func didDeleteItem(at index: Int) {
        let items = makeItems()
        guard items.indices.contains(index) else { return }

        let activityID = items[index].id
        Task { [weak self] in
            guard let self else { return }
            do {
                try await service.deleteActivity(id: activityID)
                reloadFromSource()
            } catch {
                reload()
            }
        }
    }

}

private extension ActivityListPresenter {
    func startObservingUpdates() {
        guard observerBag.observers.isEmpty else { return }

        let notificationCenter = NotificationCenter.default
        observerBag.observers = [
            notificationCenter.addObserver(
                forName: ActivitiesFeatureUpdateCenter.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reloadFromSource()
            },
            notificationCenter.addObserver(
                forName: .appSyncServiceDidFinishRun,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reloadFromSource()
            }
        ]
    }

    func reloadFromSource() {
        Task { [weak self] in
            guard let self else { return }
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
    }

    func reload() {
        view?.render(
            viewModel: ActivityListViewModel(
                items: makeItems(),
                emptyStateTitle: searchQuery.isEmpty ? "Добавь первую задачу" : "Ничего не найдено",
                emptyStateSubtitle: searchQuery.isEmpty
                    ? "Создай активность через кнопку внизу"
                    : "Попробуй изменить поисковый запрос."
            )
        )
    }

    func makeItems() -> [ActivityListItemViewModel] {
        filteredActivities().map { activity in
            ActivityListItemViewModel(
                id: activity.localID,
                name: activity.name,
                categoryName: category(id: activity.categoryLocalID)?.baseName,
                iconName: activity.iconName,
                color: activity.color,
                variationCount: activity.variations.count,
                usageCount: usageCount(for: activity.localID)
            )
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

    func usageCount(for activityID: UUID) -> Int {
        activityRecords.filter { $0.activityLocalID == activityID && $0.isDeleted == false }.count
    }
}

struct ActivityListViewModel {
    let items: [ActivityListItemViewModel]
    let emptyStateTitle: String
    let emptyStateSubtitle: String
}

struct ActivityListItemViewModel {
    let id: UUID
    let name: String
    let categoryName: String?
    let iconName: String
    let color: ActivityColor
    let variationCount: Int
    let usageCount: Int
}

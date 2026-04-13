import CommonSync
import Domain
import Foundation

@MainActor
protocol ActivityRecordPickerView: AnyObject {
    func render(viewModel: ActivityRecordPickerViewModel)
}

@MainActor
final class ActivityRecordPickerPresenter {
    weak var view: ActivityRecordPickerView?

    private let service: ActivitiesFeatureServiceProtocol
    private let onSelect: (UUID) -> Void
    private var searchQuery = ""
    private var categories: [Domain.Category] = []
    private var activities: [Activity] = []
    private let observerBag = NotificationObserverBag()

    init(
        service: ActivitiesFeatureServiceProtocol,
        onSelect: @escaping (UUID) -> Void
    ) {
        self.service = service
        self.onSelect = onSelect
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
        onSelect(items[index].id)
    }

}

private extension ActivityRecordPickerPresenter {
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
        } catch {
            categories = []
            activities = []
        }
        reload()
    }

    func reload() {
        view?.render(
            viewModel: .init(
                items: makeItems(),
                emptyTitle: "Нет задач для записи"
            )
        )
    }

    func makeItems() -> [ActivityRecordPickerItemViewModel] {
        filteredActivities().map { activity in
            .init(
                id: activity.localID,
                name: activity.name,
                categoryName: category(id: activity.categoryLocalID)?.baseName,
                iconName: activity.iconName,
                color: activity.color
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
}

struct ActivityRecordPickerViewModel {
    let items: [ActivityRecordPickerItemViewModel]
    let emptyTitle: String
}

struct ActivityRecordPickerItemViewModel {
    let id: UUID
    let name: String
    let categoryName: String?
    let iconName: String
    let color: ActivityColor
}

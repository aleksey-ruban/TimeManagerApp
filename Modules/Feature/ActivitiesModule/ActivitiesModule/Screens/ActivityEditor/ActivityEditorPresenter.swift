import CommonSync
import Domain
import Foundation

@MainActor
protocol ActivityEditorView: AnyObject {
    func render(viewModel: ActivityEditorViewModel)
}

@MainActor
final class ActivityEditorPresenter {
    weak var view: ActivityEditorView?

    private let service: ActivitiesFeatureServiceProtocol
    private let activityID: UUID?
    private let onSelectIcon: (String, ActivityColor, @escaping @MainActor (String, ActivityColor) -> Void) -> Void
    private let onSelectCategory: (UUID?, @escaping @MainActor (UUID?) -> Void) -> Void
    private let onSaved: (String) -> Void

    private var categories: [Domain.Category] = []
    private var draft = ActivityDraft(
        name: "",
        iconName: "bolt.fill",
        color: .amber,
        categoryID: nil,
        variations: []
    )
    private let observerBag = NotificationObserverBag()

    init(
        service: ActivitiesFeatureServiceProtocol,
        activityID: UUID?,
        onSelectIcon: @escaping (String, ActivityColor, @escaping @MainActor (String, ActivityColor) -> Void) -> Void,
        onSelectCategory: @escaping (UUID?, @escaping @MainActor (UUID?) -> Void) -> Void,
        onSaved: @escaping (String) -> Void
    ) {
        self.service = service
        self.activityID = activityID
        self.onSelectIcon = onSelectIcon
        self.onSelectCategory = onSelectCategory
        self.onSaved = onSaved
    }

    func viewDidLoad() {
        startObservingUpdates()
        Task { [weak self] in
            await self?.reloadFromSource()
        }
    }

    func didUpdateName(_ value: String) {
        draft.name = value
        reload()
    }

    func didTapSelectIcon() {
        onSelectIcon(draft.iconName, draft.color) { [weak self] iconName, color in
            self?.draft.iconName = iconName
            self?.draft.color = color
            self?.reload()
        }
    }

    func didTapSelectCategory() {
        onSelectCategory(draft.categoryID) { [weak self] categoryID in
            self?.draft.categoryID = categoryID
            self?.reload()
        }
    }

    func didSelectQuickCategory(_ categoryID: UUID?) {
        draft.categoryID = draft.categoryID == categoryID ? nil : categoryID
        reload()
    }

    func didUpdateVariationInput(_ value: String) {}

    func didTapAddVariation(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        draft.variations.append(
            .init(
                localID: UUID(),
                remoteID: nil,
                value: trimmed,
                position: visibleVariations().count,
                isDeleted: false
            )
        )
        reload()
    }

    func moveVariationUp(at index: Int) {
        guard index > 0, draft.variations.indices.contains(index) else { return }
        draft.variations.swapAt(index, index - 1)
        reload()
    }

    func moveVariationDown(at index: Int) {
        guard draft.variations.indices.contains(index), index < draft.variations.count - 1 else { return }
        draft.variations.swapAt(index, index + 1)
        reload()
    }

    func moveVariation(from sourceIndex: Int, to destinationIndex: Int) {
        let visible = visibleVariationIndices()
        guard visible.indices.contains(sourceIndex),
              visible.indices.contains(destinationIndex),
              sourceIndex != destinationIndex else { return }
        let source = visible[sourceIndex]
        let destination = visible[destinationIndex]
        let item = draft.variations.remove(at: source)
        draft.variations.insert(item, at: destination)
        normalizeVariationPositions()
        reload()
    }

    func deleteVariation(at index: Int) {
        let visible = visibleVariationIndices()
        guard visible.indices.contains(index) else { return }
        let actualIndex = visible[index]
        let item = draft.variations[actualIndex]
        if item.remoteID == nil {
            draft.variations.remove(at: actualIndex)
        } else {
            draft.variations[actualIndex] = .init(
                localID: item.localID,
                remoteID: item.remoteID,
                value: item.value,
                position: item.position,
                isDeleted: true
            )
        }
        normalizeVariationPositions()
        reload()
    }

    func didTapSave() {
        guard draft.isValid else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let saved = try await service.saveActivity(draft, editingActivityID: activityID)
                onSaved(activityID == nil ? "Активность «\(saved.name)» создана" : "Активность «\(saved.name)» обновлена")
            } catch {
                onSaved(error.localizedDescription)
            }
        }
    }

}

private extension ActivityEditorPresenter {
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

            if let activityID,
               let activity = snapshot.activities.first(where: { $0.localID == activityID && $0.isDeleted == false }) {
                draft = ActivityDraft(
                    name: activity.name,
                    iconName: activity.iconName,
                    color: activity.color,
                    categoryID: activity.categoryLocalID,
                    variations: activity.variations
                        .sorted(by: { $0.position < $1.position })
                        .map {
                            .init(
                                localID: $0.localID,
                                remoteID: $0.remoteID,
                                value: $0.value,
                                position: $0.position,
                                isDeleted: $0.isDeleted
                            )
                        }
                )
            }
        } catch {
            categories = []
        }

        reload()
    }

    func visibleVariations() -> [ActivityDraft.VariationDraft] {
        draft.variations.filter { $0.isDeleted == false }
    }

    func visibleVariationIndices() -> [Int] {
        draft.variations.enumerated().compactMap { $0.element.isDeleted ? nil : $0.offset }
    }

    func normalizeVariationPositions() {
        draft.variations = draft.variations.enumerated().map { index, variation in
            .init(
                localID: variation.localID,
                remoteID: variation.remoteID,
                value: variation.value,
                position: index,
                isDeleted: variation.isDeleted
            )
        }
    }

    func reload() {
        view?.render(
            viewModel: ActivityEditorViewModel(
                title: activityID == nil ? "Новая активность" : "Редактирование активности",
                name: draft.name,
                iconName: draft.iconName,
                color: draft.color,
                selectedCategoryName: category(id: draft.categoryID)?.baseName,
                selectedCategoryID: draft.categoryID,
                quickCategories: orderedQuickCategories(),
                variations: visibleVariations().map(\.value),
                isSaveEnabled: draft.isValid
            )
        )
    }

    func category(id: UUID?) -> Domain.Category? {
        guard let id else { return nil }
        return categories.first(where: { $0.localID == id && $0.isDeleted == false })
    }

    func orderedQuickCategories() -> [Domain.Category] {
        let visibleCategories = categories
            .filter { $0.isDeleted == false }
            .sorted { $0.baseName.localizedCaseInsensitiveCompare($1.baseName) == .orderedAscending }

        guard let selectedCategory = category(id: draft.categoryID) else {
            return Array(visibleCategories.prefix(8))
        }

        let remainingCategories = visibleCategories.filter { $0.localID != selectedCategory.localID }
        return Array(([selectedCategory] + remainingCategories).prefix(8))
    }
}

struct ActivityEditorViewModel {
    let title: String
    let name: String
    let iconName: String
    let color: ActivityColor
    let selectedCategoryName: String?
    let selectedCategoryID: UUID?
    let quickCategories: [Domain.Category]
    let variations: [String]
    let isSaveEnabled: Bool
}

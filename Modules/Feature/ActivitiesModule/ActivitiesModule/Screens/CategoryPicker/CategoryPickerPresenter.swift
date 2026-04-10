import CommonSync
import Domain
import Foundation

@MainActor
protocol CategoryPickerView: AnyObject {
    func render(viewModel: CategoryPickerViewModel)
    func renderSearchResults(viewModel: CategoryPickerSearchViewModel)
}

@MainActor
final class CategoryPickerPresenter {
    weak var view: CategoryPickerView?

    private let service: ActivitiesFeatureServiceProtocol
    private let onApply: (UUID?) -> Void

    private var selectedCategoryID: UUID?
    private var newCategoryName = ""
    private var categories: [Domain.Category] = []
    private let observerBag = NotificationObserverBag()

    init(
        service: ActivitiesFeatureServiceProtocol,
        selectedCategoryID: UUID?,
        onApply: @escaping (UUID?) -> Void
    ) {
        self.service = service
        self.selectedCategoryID = selectedCategoryID
        self.onApply = onApply
    }

    func viewDidLoad() {
        startObservingUpdates()
        Task { [weak self] in
            guard let self else { return }
            await reloadFromSource()
        }
    }

    func didUpdateNewCategoryName(_ value: String) {
        newCategoryName = value
        reload()
    }

    func didTapContinue() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let category = try await service.createCategory(named: trimmed)
                selectedCategoryID = category.localID
                newCategoryName = ""
                await reloadFromSource()
                onApply(category.localID)
            } catch {
                reload()
            }
        }
    }

    func didSelectCategory(_ categoryID: UUID) {
        selectedCategoryID = categoryID
        reload()
    }

    func didClearSelectedCategory() {
        selectedCategoryID = nil
        reload()
    }

    func didDeleteCategory(_ categoryID: UUID) {
        Task { [weak self] in
            guard let self else { return }
            try? await service.deleteCategory(id: categoryID)
            if selectedCategoryID == categoryID {
                selectedCategoryID = nil
            }
            await reloadFromSource()
        }
    }

    func didTapApplySelectedCategory() {
        onApply(selectedCategoryID)
    }

    func didUpdateSearchQuery(_ query: String) {
        view?.renderSearchResults(
            viewModel: .init(
                items: filteredCategories(matching: query).map {
                    .init(id: $0.localID, title: $0.baseName, isSelected: $0.localID == selectedCategoryID)
                }
            )
        )
    }

}

private extension CategoryPickerPresenter {
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
        } catch {
            categories = []
        }
        reload()
    }

    func reload() {
        view?.render(
            viewModel: CategoryPickerViewModel(
                newCategoryName: newCategoryName,
                selectedCategory: category(id: selectedCategoryID),
                myCategories: filteredCategories(),
                canContinueWithNewCategory: newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            )
        )
    }

    func category(id: UUID?) -> Domain.Category? {
        guard let id else { return nil }
        return categories.first(where: { $0.localID == id && $0.isDeleted == false })
    }

    func filteredCategories(matching query: String = "") -> [Domain.Category] {
        let normalizedQuery = query.normalizedSearchText
        return categories
            .filter { $0.isDeleted == false }
            .filter {
                normalizedQuery.isEmpty || $0.baseName.normalizedSearchText.contains(normalizedQuery)
            }
            .sorted {
                $0.baseName.localizedCaseInsensitiveCompare($1.baseName) == .orderedAscending
            }
    }
}

struct CategoryPickerViewModel {
    let newCategoryName: String
    let selectedCategory: Domain.Category?
    let myCategories: [Domain.Category]
    let canContinueWithNewCategory: Bool
}

struct CategoryPickerSearchViewModel {
    let items: [CategoryPickerSearchItemViewModel]
}

struct CategoryPickerSearchItemViewModel {
    let id: UUID
    let title: String
    let isSelected: Bool
}

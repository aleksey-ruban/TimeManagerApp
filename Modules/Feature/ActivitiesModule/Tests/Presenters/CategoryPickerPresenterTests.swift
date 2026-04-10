import XCTest
import Domain
@testable import FeatureActivitiesModule

@MainActor
final class CategoryPickerPresenterTests: XCTestCase {
    func testDidTapContinueCreatesCategoryAndAppliesSelection() async {
        let created = TestFactories.category(name: "Reading")
        let service = ActivitiesFeatureServiceSpy()
        service.createdCategoryResult = .success(created)
        service.snapshot = .init(categories: [created], activities: [], activityRecords: [])
        var appliedID: UUID?

        let presenter = CategoryPickerPresenter(
            service: service,
            selectedCategoryID: nil,
            onApply: { appliedID = $0 }
        )
        let view = CategoryPickerViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didUpdateNewCategoryName(" Reading ")
        presenter.didTapContinue()
        await flushMainActor()

        XCTAssertEqual(service.createdCategoryName, "Reading")
        XCTAssertEqual(appliedID, created.localID)
    }

    func testDidUpdateSearchQueryRendersFilteredResults() async {
        let travel = TestFactories.category(name: "Travel")
        let work = TestFactories.category(name: "Work")
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [travel, work], activities: [], activityRecords: [])

        let presenter = CategoryPickerPresenter(
            service: service,
            selectedCategoryID: travel.localID,
            onApply: { _ in }
        )
        let view = CategoryPickerViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didUpdateSearchQuery("tra")

        XCTAssertEqual(view.searchViewModel?.items.map(\.title), ["Travel"])
        XCTAssertEqual(view.searchViewModel?.items.first?.isSelected, true)
    }

    func testDidClearSelectedCategoryRendersNilSelection() async {
        let category = TestFactories.category(name: "Study")
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [category], activities: [], activityRecords: [])

        let presenter = CategoryPickerPresenter(
            service: service,
            selectedCategoryID: category.localID,
            onApply: { _ in }
        )
        let view = CategoryPickerViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didClearSelectedCategory()

        XCTAssertNil(view.viewModel?.selectedCategory)
    }
}

@MainActor
private final class CategoryPickerViewSpy: CategoryPickerView {
    private(set) var viewModel: CategoryPickerViewModel?
    private(set) var searchViewModel: CategoryPickerSearchViewModel?

    func render(viewModel: CategoryPickerViewModel) {
        self.viewModel = viewModel
    }

    func renderSearchResults(viewModel: CategoryPickerSearchViewModel) {
        searchViewModel = viewModel
    }
}

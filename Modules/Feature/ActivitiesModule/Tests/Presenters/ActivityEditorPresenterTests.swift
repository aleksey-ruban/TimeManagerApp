import XCTest
import Domain
@testable import FeatureActivitiesModule

@MainActor
final class ActivityEditorPresenterTests: XCTestCase {
    func testSelectedQuickCategoryIsRenderedFirstAndLimitedToEight() async throws {
        let selected = TestFactories.category(name: "Inbox")
        let otherCategories = (0..<10).map { index in
            TestFactories.category(name: "Category \(index)")
        }
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [selected] + otherCategories, activities: [], activityRecords: [])

        let presenter = ActivityEditorPresenter(
            service: service,
            activityID: nil,
            onSelectIcon: { _, _, _ in },
            onSelectCategory: { _, apply in apply(selected.localID) },
            onSaved: { _ in }
        )
        let view = ActivityEditorViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didSelectQuickCategory(selected.localID)

        let quickCategories = try XCTUnwrap(view.lastViewModel?.quickCategories)
        XCTAssertEqual(quickCategories.first?.localID, selected.localID)
        XCTAssertEqual(quickCategories.count, 8)
    }

    func testSelectingAlreadySelectedQuickCategoryClearsSelection() async {
        let category = TestFactories.category(name: "Work")
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [category], activities: [], activityRecords: [])

        let presenter = ActivityEditorPresenter(
            service: service,
            activityID: nil,
            onSelectIcon: { _, _, _ in },
            onSelectCategory: { _, _ in },
            onSaved: { _ in }
        )
        let view = ActivityEditorViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didSelectQuickCategory(category.localID)
        presenter.didSelectQuickCategory(category.localID)

        XCTAssertNil(view.lastViewModel?.selectedCategoryID)
    }

    func testAddingVariationTrimsInputAndEnablesSaveForValidDraft() {
        let presenter = ActivityEditorPresenter(
            service: ActivitiesFeatureServiceSpy(),
            activityID: nil,
            onSelectIcon: { _, _, _ in },
            onSelectCategory: { _, _ in },
            onSaved: { _ in }
        )
        let view = ActivityEditorViewSpy()
        presenter.view = view

        presenter.didUpdateName("Deep Work")
        presenter.didTapAddVariation("  Pomodoro  ")

        XCTAssertEqual(view.lastViewModel?.variations, ["Pomodoro"])
        XCTAssertEqual(view.lastViewModel?.isSaveEnabled, true)
    }
}

@MainActor
private final class ActivityEditorViewSpy: ActivityEditorView {
    private(set) var lastViewModel: ActivityEditorViewModel?

    func render(viewModel: ActivityEditorViewModel) {
        lastViewModel = viewModel
    }
}

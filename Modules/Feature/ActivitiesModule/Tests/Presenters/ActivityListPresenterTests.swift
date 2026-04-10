import XCTest
import Domain
@testable import FeatureActivitiesModule

@MainActor
final class ActivityListPresenterTests: XCTestCase {
    func testSearchFiltersActivitiesAndKeepsUsageCount() async throws {
        let category = TestFactories.category(name: "Work")
        let focus = TestFactories.activity(name: "Deep Focus", categoryID: category.localID, variations: [
            TestFactories.activityVariation(value: "Pomodoro", position: 0)
        ])
        let walk = TestFactories.activity(name: "Walk")
        let firstRecord = TestFactories.activityRecord(
            activityID: focus.localID,
            startedAt: Date(timeIntervalSince1970: 1_000),
            endedAt: Date(timeIntervalSince1970: 1_600)
        )
        let secondRecord = TestFactories.activityRecord(
            activityID: focus.localID,
            startedAt: Date(timeIntervalSince1970: 2_000),
            endedAt: Date(timeIntervalSince1970: 2_300)
        )
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(
            categories: [category],
            activities: [walk, focus],
            activityRecords: [firstRecord, secondRecord]
        )

        let presenter = ActivityListPresenter(
            service: service,
            onAdd: {},
            onEdit: { _ in },
            onLaunch: {}
        )
        let view = ActivityListViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didUpdateSearchQuery("focus")

        let item = try XCTUnwrap(view.lastViewModel?.items.first)
        XCTAssertEqual(view.lastViewModel?.items.count, 1)
        XCTAssertEqual(item.name, "Deep Focus")
        XCTAssertEqual(item.categoryName, "Work")
        XCTAssertEqual(item.variationCount, 1)
        XCTAssertEqual(item.usageCount, 2)
    }

    func testSelectingItemRoutesToEditUsingFilteredOrder() async {
        let alpha = TestFactories.activity(name: "Alpha")
        let beta = TestFactories.activity(name: "Beta")
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [], activities: [beta, alpha], activityRecords: [])
        var selectedID: UUID?

        let presenter = ActivityListPresenter(
            service: service,
            onAdd: {},
            onEdit: { selectedID = $0 },
            onLaunch: {}
        )
        let view = ActivityListViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didSelectItem(at: 0)

        XCTAssertEqual(selectedID, alpha.localID)
    }

    func testDeleteItemUsesVisibleFilteredItem() async {
        let alpha = TestFactories.activity(name: "Alpha")
        let beta = TestFactories.activity(name: "Beta")
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [], activities: [alpha, beta], activityRecords: [])

        let presenter = ActivityListPresenter(
            service: service,
            onAdd: {},
            onEdit: { _ in },
            onLaunch: {}
        )
        let view = ActivityListViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didUpdateSearchQuery("beta")
        presenter.didDeleteItem(at: 0)
        await flushMainActor()

        XCTAssertEqual(service.deletedActivityID, beta.localID)
    }
}

@MainActor
private final class ActivityListViewSpy: ActivityListView {
    private(set) var lastViewModel: ActivityListViewModel?

    func render(viewModel: ActivityListViewModel) {
        lastViewModel = viewModel
    }
}

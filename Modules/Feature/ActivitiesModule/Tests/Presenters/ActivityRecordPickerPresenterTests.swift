import XCTest
import Domain
@testable import FeatureActivitiesModule

@MainActor
final class ActivityRecordPickerPresenterTests: XCTestCase {
    func testSearchFiltersActivitiesByNormalizedName() async {
        let focus = TestFactories.activity(name: "Deep Focus")
        let breakActivity = TestFactories.activity(name: "Break")
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [], activities: [focus, breakActivity], activityRecords: [])

        let presenter = ActivityRecordPickerPresenter(
            service: service,
            onSelect: { _ in }
        )
        let view = ActivityRecordPickerViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didUpdateSearchQuery("focus")

        XCTAssertEqual(view.lastViewModel?.items.map(\.name), ["Deep Focus"])
    }

    func testSelectingItemRoutesWithActivityID() async {
        let activity = TestFactories.activity(name: "Meditation")
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [], activities: [activity], activityRecords: [])
        var selectedID: UUID?

        let presenter = ActivityRecordPickerPresenter(
            service: service,
            onSelect: { selectedID = $0 }
        )
        let view = ActivityRecordPickerViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didSelectItem(at: 0)

        XCTAssertEqual(selectedID, activity.localID)
    }
}

@MainActor
private final class ActivityRecordPickerViewSpy: ActivityRecordPickerView {
    private(set) var lastViewModel: ActivityRecordPickerViewModel?

    func render(viewModel: ActivityRecordPickerViewModel) {
        lastViewModel = viewModel
    }
}

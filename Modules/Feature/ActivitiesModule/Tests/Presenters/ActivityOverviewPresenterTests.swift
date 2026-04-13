import XCTest
import Domain
@testable import FeatureActivitiesModule

@MainActor
final class ActivityOverviewPresenterTests: XCTestCase {
    func testNonTodayDateHidesActiveItems() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let activity = TestFactories.activity(name: "Coding")
        let activeRecord = TestFactories.activityRecord(activityID: activity.localID, startedAt: now.addingTimeInterval(-300), endedAt: nil)
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [], activities: [activity], activityRecords: [activeRecord])

        let presenter = ActivityOverviewPresenter(
            service: service,
            onCreateRecord: {},
            onEditRecord: { _ in },
            nowProvider: { now }
        )
        let view = ActivityOverviewViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didTapPreviousDate()

        XCTAssertEqual(view.lastViewModel?.activeItems.count, 0)
    }

    func testTodayDateShowsActiveItems() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let category = TestFactories.category(name: "Health")
        let activity = TestFactories.activity(name: "Run", categoryID: category.localID)
        let activeRecord = TestFactories.activityRecord(activityID: activity.localID, startedAt: now.addingTimeInterval(-600), endedAt: nil)
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [category], activities: [activity], activityRecords: [activeRecord])

        let presenter = ActivityOverviewPresenter(
            service: service,
            onCreateRecord: {},
            onEditRecord: { _ in },
            nowProvider: { now }
        )
        let view = ActivityOverviewViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()

        XCTAssertEqual(view.lastViewModel?.activeItems.first?.activity.name, "Run")
        XCTAssertEqual(view.lastViewModel?.activeItems.first?.categoryName, "Health")
    }

    func testEmptyDataRendersGrayFallbackChartSummary() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let service = ActivitiesFeatureServiceSpy()

        let presenter = ActivityOverviewPresenter(
            service: service,
            onCreateRecord: {},
            onEditRecord: { _ in },
            nowProvider: { now }
        )
        let view = ActivityOverviewViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()

        XCTAssertEqual(view.lastViewModel?.chartSegments.count, 1)
        XCTAssertEqual(view.lastViewModel?.chartSummary, "За выбранный день нет данных")
    }

    func testDeleteRecordUsesFilteredSelectedDayItems() async {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let activity = TestFactories.activity(name: "Reading")
        let todayRecord = TestFactories.activityRecord(activityID: activity.localID, startedAt: now.addingTimeInterval(-1_200), endedAt: now.addingTimeInterval(-600))
        let oldRecord = TestFactories.activityRecord(activityID: activity.localID, startedAt: now.addingTimeInterval(-200_000), endedAt: now.addingTimeInterval(-199_000))
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [], activities: [activity], activityRecords: [todayRecord, oldRecord])

        let presenter = ActivityOverviewPresenter(
            service: service,
            onCreateRecord: {},
            onEditRecord: { _ in },
            nowProvider: { now }
        )
        let view = ActivityOverviewViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didDeleteRecord(at: 0)
        await flushMainActor()

        XCTAssertEqual(service.deletedRecordID, todayRecord.localID)
    }

    func testCalendarSelectionClosureUpdatesSelectedDate() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let service = ActivitiesFeatureServiceSpy()
        let presenter = ActivityOverviewPresenter(
            service: service,
            onCreateRecord: {},
            onEditRecord: { _ in },
            nowProvider: { now }
        )
        let view = ActivityOverviewViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didTapDate()

        let onSelectDate = try XCTUnwrap(view.onSelectDate)
        let selectedDate = now.addingTimeInterval(-86_400)
        onSelectDate(selectedDate)

        XCTAssertEqual(view.lastViewModel?.selectedDate, selectedDate)
    }
}

@MainActor
private final class ActivityOverviewViewSpy: ActivityOverviewView {
    private(set) var lastViewModel: ActivityOverviewViewModel?
    private(set) var onSelectDate: ((Date) -> Void)?

    func render(viewModel: ActivityOverviewViewModel) {
        lastViewModel = viewModel
    }

    func presentCalendar(selectedDate: Date, highlightedDates: Set<Date>, onSelectDate: @escaping (Date) -> Void) {
        self.onSelectDate = onSelectDate
    }
}

import XCTest
import Domain
@testable import FeatureActivitiesModule

@MainActor
final class ActivityLauncherPresenterTests: XCTestCase {
    func testSelectingInactiveItemLaunchesActivity() async {
        let activity = TestFactories.activity(name: "Inbox Zero")
        let launchedRecord = TestFactories.activityRecord(activityID: activity.localID, startedAt: Date(), endedAt: nil)
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [], activities: [activity], activityRecords: [])
        service.launchedActivityResult = .success(launchedRecord)
        var messages: [String] = []

        let presenter = ActivityLauncherPresenter(
            service: service,
            onCreateRecord: {},
            onFinished: { messages.append($0) }
        )
        let view = ActivityLauncherViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didSelectItem(at: 0)
        await flushMainActor()

        XCTAssertEqual(service.launchedActivityID, activity.localID)
        XCTAssertEqual(messages.last, "Запущена задача «Inbox Zero»")
    }

    func testSelectingActiveItemStopsLatestActiveRecord() async {
        let activity = TestFactories.activity(name: "Workout")
        let older = TestFactories.activityRecord(activityID: activity.localID, startedAt: Date(timeIntervalSince1970: 100), endedAt: nil)
        let newer = TestFactories.activityRecord(activityID: activity.localID, startedAt: Date(timeIntervalSince1970: 200), endedAt: nil)
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [], activities: [activity], activityRecords: [older, newer])
        service.stoppedRecordResult = .success(newer)

        let presenter = ActivityLauncherPresenter(
            service: service,
            onCreateRecord: {},
            onFinished: { _ in }
        )
        let view = ActivityLauncherViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didSelectItem(at: 0)
        await flushMainActor()

        XCTAssertEqual(service.stoppedRecordID, newer.localID)
    }
}

@MainActor
private final class ActivityLauncherViewSpy: ActivityLauncherView {
    private(set) var lastViewModel: ActivityLauncherViewModel?

    func render(viewModel: ActivityLauncherViewModel) {
        lastViewModel = viewModel
    }
}

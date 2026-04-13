import XCTest
import Domain
@testable import FeatureActivitiesModule

@MainActor
final class ActivityRecordEditorPresenterTests: XCTestCase {
    func testUpdatingStartedAtMovesEndedAtForwardWhenNeeded() async {
        let activity = TestFactories.activity(name: "Run")
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [], activities: [activity], activityRecords: [])
        let presenter = ActivityRecordEditorPresenter(
            service: service,
            activityID: activity.localID,
            activityRecordID: nil,
            onSaved: { _ in }
        )
        let view = ActivityRecordEditorViewSpy()
        presenter.view = view
        let started = Date(timeIntervalSince1970: 1_000)
        let earlierEnd = Date(timeIntervalSince1970: 900)

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didUpdateStartedAt(started)
        presenter.didToggleEndedAt(true)
        presenter.didUpdateEndedAt(earlierEnd)

        XCTAssertEqual(view.lastViewModel?.endedAt, started)
    }

    func testSaveUsesSelectedVariationAndEditingRecordID() async {
        let variation = TestFactories.activityVariation(value: "Outside", position: 0)
        let activity = TestFactories.activity(name: "Walk", variations: [variation])
        let recordID = UUID()
        let savedRecord = TestFactories.activityRecord(id: recordID, activityID: activity.localID, variationID: variation.localID, startedAt: Date(), endedAt: nil)
        let service = ActivitiesFeatureServiceSpy()
        service.snapshot = .init(categories: [], activities: [activity], activityRecords: [])
        service.savedRecordResult = .success(savedRecord)

        let presenter = ActivityRecordEditorPresenter(
            service: service,
            activityID: activity.localID,
            activityRecordID: recordID,
            onSaved: { _ in }
        )
        let view = ActivityRecordEditorViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()
        presenter.didSelectVariation(variation.localID)
        presenter.didTapSave()
        await flushMainActor()

        XCTAssertEqual(service.savedRecordInput?.activityID, activity.localID)
        XCTAssertEqual(service.savedRecordInput?.variationID, variation.localID)
        XCTAssertEqual(service.savedRecordInput?.editingRecordID, recordID)
    }

    func testWithoutActivitySaveIsDisabled() async {
        let presenter = ActivityRecordEditorPresenter(
            service: ActivitiesFeatureServiceSpy(),
            activityID: nil,
            activityRecordID: nil,
            onSaved: { _ in }
        )
        let view = ActivityRecordEditorViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        await flushMainActor()

        XCTAssertEqual(view.lastViewModel?.isSaveEnabled, false)
    }
}

@MainActor
private final class ActivityRecordEditorViewSpy: ActivityRecordEditorView {
    private(set) var lastViewModel: ActivityRecordEditorViewModel?

    func render(viewModel: ActivityRecordEditorViewModel) {
        lastViewModel = viewModel
    }
}

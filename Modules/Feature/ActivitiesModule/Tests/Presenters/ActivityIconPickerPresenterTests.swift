import XCTest
import Domain
@testable import FeatureActivitiesModule

@MainActor
final class ActivityIconPickerPresenterTests: XCTestCase {
    func testViewDidLoadRendersInitialSelection() {
        let presenter = ActivityIconPickerPresenter(
            selectedIconName: "book.fill",
            selectedColor: .blue,
            onApply: { _, _ in }
        )
        let view = ActivityIconPickerViewSpy()
        presenter.view = view

        presenter.viewDidLoad()

        XCTAssertEqual(view.lastViewModel?.selectedIconName, "book.fill")
        XCTAssertEqual(view.lastViewModel?.selectedColor, .blue)
        XCTAssertTrue(view.lastViewModel?.availableIcons.contains("timer") == true)
    }

    func testSelectingColorAndIconUpdatesViewModel() {
        let presenter = ActivityIconPickerPresenter(
            selectedIconName: "book.fill",
            selectedColor: .blue,
            onApply: { _, _ in }
        )
        let view = ActivityIconPickerViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        presenter.didSelectColor(.green)
        presenter.didSelectIcon("timer")

        XCTAssertEqual(view.lastViewModel?.selectedColor, .green)
        XCTAssertEqual(view.lastViewModel?.selectedIconName, "timer")
    }

    func testApplyReturnsCurrentSelection() {
        var appliedIcon: String?
        var appliedColor: ActivityColor?
        let presenter = ActivityIconPickerPresenter(
            selectedIconName: "book.fill",
            selectedColor: .blue,
            onApply: {
                appliedIcon = $0
                appliedColor = $1
            }
        )

        presenter.didSelectColor(.teal)
        presenter.didSelectIcon("moon.fill")
        presenter.didTapApply()

        XCTAssertEqual(appliedIcon, "moon.fill")
        XCTAssertEqual(appliedColor, .teal)
    }
}

@MainActor
private final class ActivityIconPickerViewSpy: ActivityIconPickerView {
    private(set) var lastViewModel: ActivityIconPickerViewModel?

    func render(viewModel: ActivityIconPickerViewModel) {
        lastViewModel = viewModel
    }
}

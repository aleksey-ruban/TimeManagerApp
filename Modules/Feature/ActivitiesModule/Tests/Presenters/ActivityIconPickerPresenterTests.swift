import XCTest
import Domain
@testable import FeatureActivitiesModule

@MainActor
final class ActivityIconPickerPresenterTests: XCTestCase {
    func testViewDidLoadRendersInitialSelection() {
        let presenter = ActivityIconPickerPresenter(
            iconCatalogService: ActivityIconCatalogServiceStub(),
            selectedIconName: "book.fill",
            selectedColor: .blue,
            onApply: { _, _ in }
        )
        let view = ActivityIconPickerViewSpy()
        presenter.view = view

        presenter.viewDidLoad()

        XCTAssertEqual(view.lastViewModel?.selectedIconName, "book.fill")
        XCTAssertEqual(view.lastViewModel?.selectedColor, .blue)
        XCTAssertEqual(view.lastViewModel?.availableIcons, ActivityIconCatalogServiceStub.icons)
    }

    func testSelectingColorAndIconUpdatesViewModel() {
        let presenter = ActivityIconPickerPresenter(
            iconCatalogService: ActivityIconCatalogServiceStub(),
            selectedIconName: "book.fill",
            selectedColor: .blue,
            onApply: { _, _ in }
        )
        let view = ActivityIconPickerViewSpy()
        presenter.view = view

        presenter.viewDidLoad()
        presenter.didSelectColor(.green)
        presenter.didSelectIcon("figure.run")

        XCTAssertEqual(view.lastViewModel?.selectedColor, .green)
        XCTAssertEqual(view.lastViewModel?.selectedIconName, "figure.run")
    }

    func testApplyReturnsCurrentSelection() {
        var appliedIcon: String?
        var appliedColor: ActivityColor?
        let presenter = ActivityIconPickerPresenter(
            iconCatalogService: ActivityIconCatalogServiceStub(),
            selectedIconName: "book.fill",
            selectedColor: .blue,
            onApply: {
                appliedIcon = $0
                appliedColor = $1
            }
        )

        presenter.didSelectColor(.teal)
        presenter.didSelectIcon("figure.run")
        presenter.didTapApply()

        XCTAssertEqual(appliedIcon, "figure.run")
        XCTAssertEqual(appliedColor, .teal)
    }
}

private struct ActivityIconCatalogServiceStub: ActivityIconCatalogServiceProtocol {
    static let icons = ["book.fill", "figure.run", "house.fill"]

    func availableIcons() -> [String] {
        Self.icons
    }
}

@MainActor
private final class ActivityIconPickerViewSpy: ActivityIconPickerView {
    private(set) var lastViewModel: ActivityIconPickerViewModel?

    func render(viewModel: ActivityIconPickerViewModel) {
        lastViewModel = viewModel
    }
}

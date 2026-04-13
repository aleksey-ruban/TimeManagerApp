import UIKit

public protocol CommonCalendarAssemblyProtocol: Sendable {
    @MainActor
    func makeDateNavigatorView() -> UIView & CommonDateNavigatorViewProtocol

    @MainActor
    func makeCalendarViewController(
        configuration: CommonCalendarConfiguration,
        onSelectDate: @escaping @MainActor (Date) -> Void
    ) -> UIViewController
}

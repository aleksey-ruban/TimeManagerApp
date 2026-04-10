import UIKit

public struct CommonCalendarAssembly: CommonCalendarAssemblyProtocol, @unchecked Sendable {
    public init() {}

    @MainActor
    public func makeDateNavigatorView() -> UIView & CommonDateNavigatorViewProtocol {
        CommonDateNavigatorView()
    }

    @MainActor
    public func makeCalendarViewController(
        configuration: CommonCalendarConfiguration,
        onSelectDate: @escaping @MainActor (Date) -> Void
    ) -> UIViewController {
        CommonCalendarViewController(
            configuration: configuration,
            onSelectDate: onSelectDate
        )
    }
}

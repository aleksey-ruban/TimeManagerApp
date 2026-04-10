import Foundation

@MainActor
public protocol CommonDateNavigatorViewProtocol: AnyObject {
    var onPreviousDate: (() -> Void)? { get set }
    var onNextDate: (() -> Void)? { get set }
    var onTapDate: (() -> Void)? { get set }

    func apply(date: Date)
}

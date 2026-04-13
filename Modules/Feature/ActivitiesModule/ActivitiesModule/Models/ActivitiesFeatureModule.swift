import UIKit
import Foundation

@MainActor
public protocol ActivitiesCoordinatorProtocol: AnyObject {
    func start()
    func showActivityList()
    func showActivityOverview()
    func showActivityLauncher()
    func showActivityEditor(activityID: UUID?)
    func showActivityRecordCreation()
    func showActivityRecordEditor(activityRecordID: UUID)
}

@MainActor
public struct ActivitiesFeatureModule {
    public let coordinator: ActivitiesCoordinatorProtocol

    public init(coordinator: ActivitiesCoordinatorProtocol) {
        self.coordinator = coordinator
    }
}

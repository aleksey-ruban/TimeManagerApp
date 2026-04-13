import FeatureAuthModule
import UIKit

@MainActor
struct AuthFlow {
    let rootViewController: UIViewController
    let coordinator: AuthCoordinatorProtocol
}

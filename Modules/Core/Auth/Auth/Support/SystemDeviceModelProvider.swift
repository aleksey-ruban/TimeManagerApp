import Foundation

#if canImport(UIKit)
import UIKit
#endif

struct SystemDeviceModelProvider: DeviceModelProviderProtocol {
    init() {}

    @MainActor
    func deviceModel() -> String {
        #if canImport(UIKit)
        UIDevice.current.model
        #else
        ProcessInfo.processInfo.hostName
        #endif
    }
}

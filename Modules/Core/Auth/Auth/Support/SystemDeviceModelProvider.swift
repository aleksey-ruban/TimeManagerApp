import Foundation

#if canImport(UIKit)
import UIKit
#endif

struct SystemDeviceModelProvider: DeviceModelProviderProtocol {
    init() {}

    func deviceModel() -> String {
        #if canImport(UIKit)
        UIDevice.current.model
        #else
        ProcessInfo.processInfo.hostName
        #endif
    }
}

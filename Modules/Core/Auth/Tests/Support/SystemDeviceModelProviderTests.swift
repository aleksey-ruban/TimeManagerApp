import XCTest
@testable import CoreAuth

final class SystemDeviceModelProviderTests: XCTestCase {
    func testResolvedModelNamePrefersSimulatorIdentifierWhenAvailable() {
        let provider = SystemDeviceModelProvider()

        let model = provider.resolvedModelName(
            simulatorModelIdentifier: "iPhone17,1",
            machineIdentifier: "arm64"
        )

        XCTAssertEqual(model, "iPhone 16 Pro")
    }

    func testResolvedModelNameMapsPhysicalDeviceIdentifier() {
        let provider = SystemDeviceModelProvider()

        let model = provider.resolvedModelName(
            simulatorModelIdentifier: nil,
            machineIdentifier: "iPad7,11"
        )

        XCTAssertEqual(model, "iPad (7th generation)")
    }

    func testResolvedModelNameMapsOlderIOS15CompatibleIPhone() {
        let provider = SystemDeviceModelProvider()

        let model = provider.resolvedModelName(
            simulatorModelIdentifier: nil,
            machineIdentifier: "iPhone8,1"
        )

        XCTAssertEqual(model, "iPhone 6s")
    }

    func testResolvedModelNameFallsBackToIdentifierWhenModelIsUnknown() {
        let provider = SystemDeviceModelProvider()

        let model = provider.resolvedModelName(
            simulatorModelIdentifier: nil,
            machineIdentifier: "UnknownDevice1,1"
        )

        XCTAssertEqual(model, "UnknownDevice1,1")
    }
}

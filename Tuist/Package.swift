// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // SnapKit is consumed by several dynamic feature frameworks.
        // Keeping it as Tuist's default `.staticFramework` duplicates its
        // symbols in each feature module and triggers Objective-C runtime
        // duplicate-class warnings inside the app bundle.
        productTypes: [
            "SnapKit": .framework,
        ]
    )
#endif

let package = Package(
    name: "TimeManagerApp",
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
    ]
)

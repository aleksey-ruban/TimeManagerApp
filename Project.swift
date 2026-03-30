import ProjectDescription

private enum AppConfig {
    static let name = "TimeManagerApp"
    static let bundleId = "com.alekseyruban.TimeManagerApp"
    static let deploymentTarget: DeploymentTargets = .iOS("26.2")
    static let developmentTeam = "5P2MVJMNMA"
    static let marketingVersion = "1.0"
    static let currentProjectVersion = "1"
}

private let baseSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": .string(AppConfig.developmentTeam),
    "MARKETING_VERSION": .string(AppConfig.marketingVersion),
    "CURRENT_PROJECT_VERSION": .string(AppConfig.currentProjectVersion),
    "SWIFT_VERSION": "6.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
]

private let appSettings: SettingsDictionary = baseSettings.merging([
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "LD_RUNPATH_SEARCH_PATHS": [
        "$(inherited)",
        "@executable_path/Frameworks",
    ],
    "SWIFT_EMIT_LOC_STRINGS": "YES",
])

private let testSettings: SettingsDictionary = baseSettings.merging([
    "SWIFT_EMIT_LOC_STRINGS": "NO",
])

private let appSources: SourceFilesList = [
    "TimeManagerApp/**/*.swift",
    "Modules/Core/**/*.swift",
    "Modules/Common/**/*.swift",
    "Modules/Feature/**/*.swift",
]

private let appResources: ResourceFileElements = [
    "TimeManagerApp/Assets.xcassets",
    "TimeManagerApp/Base.lproj/**",
    "TimeManagerApp/**/*.xcdatamodeld",
]

let project = Project(
    name: AppConfig.name,
    organizationName: "Aleksey Ruban",
    options: .options(
        defaultKnownRegions: ["en", "Base"],
        developmentRegion: "en"
    ),
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": .string(AppConfig.developmentTeam),
        ]
    ),
    targets: [
        .target(
            name: AppConfig.name,
            destinations: .iOS,
            product: .app,
            bundleId: AppConfig.bundleId,
            deploymentTargets: AppConfig.deploymentTarget,
            infoPlist: .file(path: "TimeManagerApp/Info.plist"),
            sources: appSources,
            resources: appResources,
            settings: .settings(base: appSettings)
        ),
        .target(
            name: "\(AppConfig.name)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(AppConfig.bundleId)Tests",
            deploymentTargets: AppConfig.deploymentTarget,
            infoPlist: .default,
            sources: ["Tests/TimeManagerAppTests/**/*.swift"],
            dependencies: [
                .target(name: AppConfig.name),
            ],
            settings: .settings(base: testSettings)
        ),
        .target(
            name: "\(AppConfig.name)UITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "\(AppConfig.bundleId)UITests",
            deploymentTargets: AppConfig.deploymentTarget,
            infoPlist: .default,
            sources: ["Tests/TimeManagerAppUITests/**/*.swift"],
            dependencies: [
                .target(name: AppConfig.name),
            ],
            settings: .settings(base: testSettings)
        ),
    ]
)

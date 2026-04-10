import ProjectDescription

private enum ModuleConfig {
    static let name = "FeatureActivitiesModule"
    static let bundleId = "com.alekseyruban.TimeManagerApp.FeatureActivitiesModule"
    static let deploymentTarget: DeploymentTargets = .iOS("16.0")
    static let developmentTeam = "5P2MVJMNMA"
    static let marketingVersion = "1.0"
    static let currentProjectVersion = "1"
}

private let moduleSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": .string(ModuleConfig.developmentTeam),
    "MARKETING_VERSION": .string(ModuleConfig.marketingVersion),
    "CURRENT_PROJECT_VERSION": .string(ModuleConfig.currentProjectVersion),
    "SWIFT_VERSION": "6.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
]

let project = Project(
    name: ModuleConfig.name,
    organizationName: "Aleksey Ruban",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": .string(ModuleConfig.developmentTeam),
        ]
    ),
    targets: [
        .target(
            name: ModuleConfig.name,
            destinations: .iOS,
            product: .framework,
            bundleId: ModuleConfig.bundleId,
            deploymentTargets: ModuleConfig.deploymentTarget,
            infoPlist: .default,
            sources: [
                "ActivitiesModule/**/*.swift",
            ],
            dependencies: [
                .project(target: "Domain", path: "../../Common/Domain"),
                .project(target: "DesignSystem", path: "../../Common/DesignSystem"),
                .project(target: "DesignTokens", path: "../../Common/DesignTokens"),
                .project(target: "CommonCalendar", path: "../../Common/Calendar"),
                .project(target: "CoreStorage", path: "../../Core/Storage"),
                .project(target: "CommonSync", path: "../../Common/Sync"),
                .project(target: "CoreSync", path: "../../Core/Sync"),
                .external(name: "SnapKit"),
            ],
            settings: .settings(base: moduleSettings)
        ),
        .target(
            name: "\(ModuleConfig.name)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(ModuleConfig.bundleId)Tests",
            deploymentTargets: ModuleConfig.deploymentTarget,
            infoPlist: .default,
            sources: [
                "Tests/**/*.swift",
            ],
            dependencies: [
                .target(name: ModuleConfig.name),
                .project(target: "Domain", path: "../../Common/Domain"),
            ],
            settings: .settings(base: moduleSettings.merging([
                "SWIFT_EMIT_LOC_STRINGS": "NO",
                "CODE_SIGNING_ALLOWED": "NO",
                "CODE_SIGNING_REQUIRED": "NO",
            ]))
        ),
    ]
)

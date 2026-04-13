import ProjectDescription

private enum ModuleConfig {
    static let name = "FeatureSettingsModule"
    static let bundleId = "com.alekseyruban.TimeManagerApp.FeatureSettingsModule"
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
                "SettingsModule/**/*.swift",
            ],
            dependencies: [
                .project(target: "Domain", path: "../../Common/Domain"),
                .project(target: "DesignSystem", path: "../../Common/DesignSystem"),
                .project(target: "DesignTokens", path: "../../Common/DesignTokens"),
                .project(target: "CoreAuth", path: "../../Core/Auth"),
                .project(target: "CoreSessionCleanup", path: "../../Core/SessionCleanup"),
                .project(target: "CoreUserProfile", path: "../../Core/UserProfile"),
                .external(name: "SnapKit"),
            ],
            settings: .settings(base: moduleSettings)
        ),
    ]
)

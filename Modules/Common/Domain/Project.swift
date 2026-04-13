import ProjectDescription

private enum ModuleConfig {
    static let name = "Domain"
    static let bundleId = "com.alekseyruban.TimeManagerApp.Domain"
    static let deploymentTarget: DeploymentTargets = .multiplatform(
        iOS: "16.0",
        macOS: "13.0"
    )
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
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: ModuleConfig.bundleId,
            deploymentTargets: ModuleConfig.deploymentTarget,
            infoPlist: .default,
            sources: [
                "Domain/**/*.swift",
            ],
            settings: .settings(base: moduleSettings)
        ),
        .target(
            name: "\(ModuleConfig.name)Tests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "\(ModuleConfig.bundleId)Tests",
            deploymentTargets: ModuleConfig.deploymentTarget,
            infoPlist: .default,
            sources: [
                "Tests/**/*.swift",
            ],
            dependencies: [
                .target(name: ModuleConfig.name),
                .project(target: "CoreStorage", path: "../../Core/Storage"),
            ],
            settings: .settings(base: moduleSettings.merging([
                "SWIFT_EMIT_LOC_STRINGS": "NO",
            ]))
        ),
    ]
)

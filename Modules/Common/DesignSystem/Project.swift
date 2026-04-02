import ProjectDescription

private enum ModuleConfig {
    static let name = "DesignSystem"
    static let bundleId = "com.alekseyruban.TimeManagerApp.DesignSystem"
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
                "DesignSystem/Components/Button/PrimaryButton.swift",
                "DesignSystem/Components/Button/PrimaryButtonConfiguration.swift",
                "DesignSystem/Components/Button/LinkButton.swift",
                "DesignSystem/Components/Button/LinkButtonConfiguration.swift",
                "DesignSystem/Components/Container/FloatingBottomContainer.swift",
                "DesignSystem/Components/Container/FloatingBottomContainerConfiguration.swift",
                "DesignSystem/Components/TextField/CommonTextField.swift",
                "DesignSystem/Components/TextField/CommonTextFieldConfiguration.swift",
            ],
            dependencies: [
                .project(target: "DesignTokens", path: "../DesignTokens"),
            ],
            settings: .settings(base: moduleSettings)
        ),
    ]
)

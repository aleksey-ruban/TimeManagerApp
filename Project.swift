import ProjectDescription

private enum AppConfig {
    static let name = "TimeManagerApp"
    static let usesCustomAppIdentity = true
    static let deploymentTarget: DeploymentTargets = .iOS("16.0")
    static let marketingVersion = "1.0"
    static let currentProjectVersion = "1"
}

private enum AppIdentity {
    private static let defaultBundleId = "com.alekseyruban.TimeManagerApp"
    private static let defaultDevelopmentTeam = "5P2MVJMNMA"
    private static let customBundleId = "com.masondavis.TimeManagerApp"
    private static let customDevelopmentTeam = "HD98KJX72K"

    static let bundleId = AppConfig.usesCustomAppIdentity ? customBundleId : defaultBundleId
    static let developmentTeam = AppConfig.usesCustomAppIdentity ? customDevelopmentTeam : defaultDevelopmentTeam
}

private enum NetworkSettings {
    static let localDynamicBaseURL = "http://10.0.1.28:8080"
    static let localBaseURL = "http://10.0.1.2:80"
    static let globalBaseURL = "https://timespan.pro"
}

private let baseSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": .string(AppIdentity.developmentTeam),
    "MARKETING_VERSION": .string(AppConfig.marketingVersion),
    "CURRENT_PROJECT_VERSION": .string(AppConfig.currentProjectVersion),
    "SWIFT_VERSION": "6.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
]

private let appSettings: SettingsDictionary = baseSettings.merging([
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": [
        "UIInterfaceOrientationPortrait",
    ],
    "LD_RUNPATH_SEARCH_PATHS": [
        "$(inherited)",
        "@executable_path/Frameworks",
    ],
    "SWIFT_EMIT_LOC_STRINGS": "YES",
])

private let testSettings: SettingsDictionary = baseSettings.merging([
    "SWIFT_EMIT_LOC_STRINGS": "NO",
])

private let appConfigurations: [Configuration] = [
    .debug(
        name: "Debug",
        settings: [
            "API_BASE_URL": .string(NetworkSettings.globalBaseURL),
            "NETWORK_LOGGING_MODE": "debugOnly",
        ]
    ),
    .release(
        name: "Release",
        settings: [
            "API_BASE_URL": .string(NetworkSettings.globalBaseURL),
            "NETWORK_LOGGING_MODE": "disabled",
        ]
    ),
]

private let testConfigurations: [Configuration] = [
    .debug(
        name: "Debug",
        settings: [
            "API_BASE_URL": .string(NetworkSettings.localBaseURL),
            "NETWORK_LOGGING_MODE": "debugOnly",
        ]
    ),
    .release(
        name: "Release",
        settings: [
            "API_BASE_URL": .string(NetworkSettings.globalBaseURL),
            "NETWORK_LOGGING_MODE": "disabled",
        ]
    ),
]

private let appSources: SourceFilesList = [
    .glob("TimeManagerApp/**/*.swift"),
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
            "DEVELOPMENT_TEAM": .string(AppIdentity.developmentTeam),
        ]
    ),
    targets: [
        .target(
            name: AppConfig.name,
            destinations: .iOS,
            product: .app,
            bundleId: AppIdentity.bundleId,
            deploymentTargets: AppConfig.deploymentTarget,
            infoPlist: .file(path: "TimeManagerApp/Info.plist"),
            sources: appSources,
            resources: appResources,
            dependencies: [
                .project(target: "CommonSync", path: "Modules/Common/Sync"),
                .project(target: "Domain", path: "Modules/Common/Domain"),
                .project(target: "DesignSystem", path: "Modules/Common/DesignSystem"),
                .project(target: "DesignTokens", path: "Modules/Common/DesignTokens"),
                .project(target: "CoreNetwork", path: "Modules/Core/Network"),
                .project(target: "CoreAuth", path: "Modules/Core/Auth"),
                .project(target: "CoreSessionCleanup", path: "Modules/Core/SessionCleanup"),
                .project(target: "CoreStorage", path: "Modules/Core/Storage"),
                .project(target: "CoreSync", path: "Modules/Core/Sync"),
                .project(target: "CoreUserProfile", path: "Modules/Core/UserProfile"),
                .project(target: "FeatureAuthModule", path: "Modules/Feature/AuthModule"),
                .project(target: "FeatureActivitiesModule", path: "Modules/Feature/ActivitiesModule"),
                .project(target: "FeatureAnalyticsModule", path: "Modules/Feature/AnalyticsModule"),
                .project(target: "FeatureSettingsModule", path: "Modules/Feature/SettingsModule"),
            ],
            settings: .settings(
                base: appSettings,
                configurations: appConfigurations
            )
        ),
        .target(
            name: "\(AppConfig.name)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(AppIdentity.bundleId)Tests",
            deploymentTargets: AppConfig.deploymentTarget,
            infoPlist: .default,
            sources: ["Tests/TimeManagerAppTests/**/*.swift"],
            dependencies: [
                .target(name: AppConfig.name),
                .project(target: "CommonSync", path: "Modules/Common/Sync"),
                .project(target: "Domain", path: "Modules/Common/Domain"),
                .project(target: "DesignSystem", path: "Modules/Common/DesignSystem"),
                .project(target: "DesignTokens", path: "Modules/Common/DesignTokens"),
                .project(target: "CoreNetwork", path: "Modules/Core/Network"),
                .project(target: "CoreAuth", path: "Modules/Core/Auth"),
                .project(target: "CoreSessionCleanup", path: "Modules/Core/SessionCleanup"),
                .project(target: "CoreStorage", path: "Modules/Core/Storage"),
                .project(target: "CoreSync", path: "Modules/Core/Sync"),
                .project(target: "CoreUserProfile", path: "Modules/Core/UserProfile"),
                .project(target: "FeatureAuthModule", path: "Modules/Feature/AuthModule"),
                .project(target: "FeatureActivitiesModule", path: "Modules/Feature/ActivitiesModule"),
                .project(target: "FeatureAnalyticsModule", path: "Modules/Feature/AnalyticsModule"),
                .project(target: "FeatureSettingsModule", path: "Modules/Feature/SettingsModule"),
            ],
            settings: .settings(
                base: testSettings,
                configurations: testConfigurations
            )
        ),
        .target(
            name: "\(AppConfig.name)UITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "\(AppIdentity.bundleId)UITests",
            deploymentTargets: AppConfig.deploymentTarget,
            infoPlist: .default,
            sources: ["Tests/TimeManagerAppUITests/**/*.swift"],
            dependencies: [
                .target(name: AppConfig.name),
            ],
            settings: .settings(
                base: testSettings,
                configurations: testConfigurations
            )
        ),
    ]
)

import ProjectDescription

private let workspaceProjects: [Path] = [
    ".",
    "Modules/Common/Calendar",
    "Modules/Common/DesignSystem",
    "Modules/Common/DesignTokens",
    "Modules/Common/Domain",
    "Modules/Common/Sync",
    "Modules/Core/Auth",
    "Modules/Core/Network",
    "Modules/Core/SessionCleanup",
    "Modules/Core/Storage",
    "Modules/Core/Sync",
    "Modules/Core/UserProfile",
    "Modules/Feature/ActivitiesModule",
    "Modules/Feature/AnalyticsModule",
    "Modules/Feature/AuthModule",
    "Modules/Feature/SettingsModule",
]

private let allTestTargets: [TestableTarget] = [
    .testableTarget(target: .project(path: ".", target: "TimeManagerAppTests")),
    .testableTarget(target: .project(path: ".", target: "TimeManagerAppUITests")),
    .testableTarget(target: .project(path: "Modules/Common/Calendar", target: "CommonCalendarTests")),
    .testableTarget(target: .project(path: "Modules/Common/Domain", target: "DomainTests")),
    .testableTarget(target: .project(path: "Modules/Common/Sync", target: "CommonSyncTests")),
    .testableTarget(target: .project(path: "Modules/Core/Auth", target: "CoreAuthTests")),
    .testableTarget(target: .project(path: "Modules/Core/Network", target: "CoreNetworkTests")),
    .testableTarget(target: .project(path: "Modules/Core/Storage", target: "CoreStorageTests")),
    .testableTarget(target: .project(path: "Modules/Core/Sync", target: "CoreSyncTests")),
    .testableTarget(target: .project(path: "Modules/Core/UserProfile", target: "CoreUserProfileTests")),
    .testableTarget(target: .project(path: "Modules/Feature/ActivitiesModule", target: "FeatureActivitiesModuleTests")),
    .testableTarget(target: .project(path: "Modules/Feature/AnalyticsModule", target: "FeatureAnalyticsModuleTests")),
    .testableTarget(target: .project(path: "Modules/Feature/AuthModule", target: "FeatureAuthModuleTests")),
]

private let allCoverageTargets: [TargetReference] = [
    .project(path: ".", target: "TimeManagerApp"),
    .project(path: "Modules/Common/Calendar", target: "CommonCalendar"),
    .project(path: "Modules/Common/Domain", target: "Domain"),
    .project(path: "Modules/Common/Sync", target: "CommonSync"),
    .project(path: "Modules/Core/Auth", target: "CoreAuth"),
    .project(path: "Modules/Core/Network", target: "CoreNetwork"),
    .project(path: "Modules/Core/Storage", target: "CoreStorage"),
    .project(path: "Modules/Core/Sync", target: "CoreSync"),
    .project(path: "Modules/Core/UserProfile", target: "CoreUserProfile"),
    .project(path: "Modules/Feature/ActivitiesModule", target: "FeatureActivitiesModule"),
    .project(path: "Modules/Feature/AnalyticsModule", target: "FeatureAnalyticsModule"),
    .project(path: "Modules/Feature/AuthModule", target: "FeatureAuthModule"),
]

let workspace = Workspace(
    name: "TimeManagerApp",
    projects: workspaceProjects,
    schemes: [
        .scheme(
            name: "TimeManagerApp-AllTests",
            shared: true,
            buildAction: .buildAction(targets: [
                .project(path: ".", target: "TimeManagerApp"),
            ]),
            testAction: .targets(
                allTestTargets,
                configuration: .debug,
                attachDebugger: false,
                options: .options(
                    coverage: true,
                    codeCoverageTargets: allCoverageTargets
                )
            ),
            runAction: .runAction(
                attachDebugger: true,
                executable: .project(path: ".", target: "TimeManagerApp")
            )
        ),
    ]
)

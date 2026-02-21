//
//  Target+TripFit.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import ProjectDescription

public enum TripFitTarget {
    public static func app(
        name: String = "TripFit",
        sources: SourceFilesList = ["App/**"],
        resources: ResourceFileElements = ["Resources/**"]
    ) -> Target {
        .target(
            name: name,
            destinations: .iOS,
            product: .app,
            bundleId: TripFitBuild.bundleId,
            deploymentTargets: TripFitBuild.deployment,
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "UIUserInterfaceStyle": "Dark",
                "UILaunchScreen": [:],
                "UIApplicationSupportsIndirectInputEvents": true,
                "UIAppFonts": [
                    "PlusJakartaSans-Variable.ttf",
                    "Fonts/PlusJakartaSans-Variable.ttf",
                    "MaterialSymbolsOutlined.ttf",
                    "Fonts/MaterialSymbolsOutlined.ttf",
                ],
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": [
                        "UIWindowSceneSessionRoleApplication": [
                            [
                                "UISceneConfigurationName": "Default Configuration",
                                "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
                            ]
                        ]
                    ]
                ],
            ]),
            sources: sources,
            resources: resources,
            entitlements: .file(path: "App/TripFit.entitlements"),
            scripts: [
                .pre(
                    path: .relativeToRoot("Scripts/swiftlint.sh"),
                    name: "SwiftLint",
                    basedOnDependencyAnalysis: false
                ),
            ],
            dependencies: [
                .target(name: "Core"),
                .target(name: "Domain"),
                .target(name: "Features"),
                .external(name: "SnapKit"),
            ],
            settings: .tripFitTargetSettings()
        )
    }

    public static func framework(
        name: String,
        path: String,
        resources: ResourceFileElements = [],
        dependencies: [TargetDependency]
    ) -> Target {
        .target(
            name: name,
            destinations: .iOS,
            product: .framework,
            bundleId: "\(TripFitBuild.bundleId).\(name)",
            deploymentTargets: TripFitBuild.deployment,
            sources: [.glob("\(path)/**", excluding: ["\(path)/Resources/**"])],
            resources: resources,
            dependencies: dependencies
        )
    }
}

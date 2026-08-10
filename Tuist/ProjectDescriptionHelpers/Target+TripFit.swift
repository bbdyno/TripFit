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
                "NSCalendarsFullAccessUsageDescription": "TripFit은 사용자가 선택한 여행 후보 날짜의 바쁜 시간만 기기에서 확인하며, 일정 제목이나 내용은 업로드하지 않습니다. TripFit checks only busy times for selected travel dates on this device and never uploads calendar details.",
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
                    path: .relativeToRoot("Scripts/validate-firebase-config.sh"),
                    name: "Validate Firebase Configuration",
                    basedOnDependencyAnalysis: false
                ),
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
                .target(name: "CollaborationData"),
                .external(name: "SnapKit"),
            ],
            settings: .tripFitTargetSettings()
        )
    }

    public static func framework(
        name: String,
        path: String,
        resources: ResourceFileElements = [],
        product: Product = .framework,
        dependencies: [TargetDependency]
    ) -> Target {
        .target(
            name: name,
            destinations: .iOS,
            product: product,
            bundleId: "\(TripFitBuild.bundleId).\(name)",
            deploymentTargets: TripFitBuild.deployment,
            sources: [.glob("\(path)/**", excluding: ["\(path)/Resources/**"])],
            resources: resources,
            dependencies: dependencies
        )
    }

    public static func unitTests(
        name: String,
        path: String,
        dependencies: [TargetDependency]
    ) -> Target {
        .target(
            name: name,
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(TripFitBuild.bundleId).\(name)",
            deploymentTargets: TripFitBuild.deployment,
            sources: ["\(path)/**"],
            dependencies: dependencies
        )
    }
}

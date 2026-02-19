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
                "UILaunchScreen": [:],
                "UIApplicationSupportsIndirectInputEvents": true,
            ]),
            sources: sources,
            resources: resources,
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
        dependencies: [TargetDependency]
    ) -> Target {
        .target(
            name: name,
            destinations: .iOS,
            product: .framework,
            bundleId: "\(TripFitBuild.bundleId).\(name)",
            deploymentTargets: TripFitBuild.deployment,
            sources: ["\(path)/**"],
            dependencies: dependencies
        )
    }
}

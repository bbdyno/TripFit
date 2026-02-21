//
//  Settings+TripFit.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import ProjectDescription
import Foundation

public enum TripFitBuild {
    public static let marketingVersion = "1.0.0"
    public static let buildNumber = "2026.02.21.2"
    public static let bundleId = "com.bbdyno.app.tripFit"
    public static let developmentTeam = "M79H9K226Y"
    public static let provisioningProfileSpecifier = "TripFit App Provisioning"
    public static let deployment: DeploymentTargets = .iOS("17.0")
}

public extension Settings {
    static func tripFitBaseSettings() -> Settings {
        .settings(
            base: [
                "MARKETING_VERSION": .string(TripFitBuild.marketingVersion),
                "CURRENT_PROJECT_VERSION": .string(TripFitBuild.buildNumber),
            ],
            defaultSettings: .recommended
        )
    }

    static func tripFitTargetSettings() -> Settings {
        let env = ProcessInfo.processInfo.environment
        var base: SettingsDictionary = [
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
            "TARGETED_DEVICE_FAMILY": "1",
            "ENABLE_PREVIEWS": "NO",
            "DEVELOPMENT_TEAM": .string(env["DEVELOPMENT_TEAM"] ?? TripFitBuild.developmentTeam),
            "CODE_SIGN_STYLE": .string(env["CODE_SIGN_STYLE"] ?? "Manual"),
            "PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]": .string(
                env["PROVISIONING_PROFILE_SPECIFIER"] ?? TripFitBuild.provisioningProfileSpecifier
            ),
        ]

        return .settings(
            base: base,
            configurations: [
                .debug(name: "Debug"),
                .release(name: "Release"),
            ],
            defaultSettings: .recommended
        )
    }
}

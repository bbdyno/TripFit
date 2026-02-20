//
//  Project.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "TripFit",
    settings: .tripFitBaseSettings(),
    targets: [
        TripFitTarget.framework(
            name: "Core",
            path: "Core",
            resources: ["Core/Resources/**"],
            dependencies: [
                .external(name: "SnapKit"),
            ]
        ),
        TripFitTarget.framework(
            name: "Domain",
            path: "Domain",
            dependencies: []
        ),
        TripFitTarget.framework(
            name: "Features",
            path: "Features",
            dependencies: [
                .target(name: "Core"),
                .target(name: "Domain"),
                .external(name: "SnapKit"),
            ]
        ),
        TripFitTarget.app(),
    ]
)

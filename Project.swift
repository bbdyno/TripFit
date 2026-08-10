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
        TripFitTarget.framework(
            name: "CollaborationData",
            path: "CollaborationData",
            dependencies: [
                .target(name: "Domain"),
                .external(name: "FirebaseCore"),
                .external(name: "FirebaseAuth"),
                .external(name: "FirebaseFirestore"),
                .external(name: "FirebaseAppCheck"),
            ]
        ),
        TripFitTarget.unitTests(
            name: "DomainTests",
            path: "Tests/DomainTests",
            dependencies: [.target(name: "Domain")]
        ),
        TripFitTarget.app(),
    ],
    schemes: [
        .scheme(
            name: "TripFit",
            shared: true,
            buildAction: .buildAction(targets: ["TripFit"]),
            testAction: .targets(["DomainTests"]),
            runAction: .runAction(configuration: .debug),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release),
            analyzeAction: .analyzeAction(configuration: .debug)
        ),
    ]
)

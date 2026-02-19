import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "TripFit",
    settings: .tripFitBaseSettings(),
    targets: [
        TripFitTarget.framework(
            name: "Core",
            path: "Core",
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

//
//  Package.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription
import ProjectDescriptionHelpers

let packageSettings = PackageSettings(
    productTypes: [
        "SnapKit": .framework
    ]
)
#endif

let package = Package(
    name: "TripFit",
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.0")
    ]
)

//
//  AppDelegate.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import CoreText
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureAppearance()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    private func configureAppearance() {
        registerCustomFontsIfNeeded()

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = TFColor.Surface.canvas
        navAppearance.titleTextAttributes = [
            .foregroundColor: TFColor.Text.primary,
            .font: TFTypography.headline,
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: TFColor.Text.primary,
            .font: TFTypography.largeTitle,
        ]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = navAppearance
        navBar.scrollEdgeAppearance = navAppearance
        navBar.tintColor = TFColor.Brand.primary

        UISearchBar.appearance().tintColor = TFColor.Brand.primary
    }

    private func registerCustomFontsIfNeeded() {
        let directMatch = Bundle.main.url(forResource: "PlusJakartaSans-Variable", withExtension: "ttf")
        let folderMatch = Bundle.main.url(forResource: "PlusJakartaSans-Variable", withExtension: "ttf", subdirectory: "Fonts")
        let discovered = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent.contains("PlusJakartaSans") }
        let urls = Set([directMatch, folderMatch].compactMap { $0 } + discovered)

        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

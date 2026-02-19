//
//  SceneDelegate.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var environment: AppEnvironment!

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        environment = AppEnvironment.makeDefault()
        environment.seedIfNeeded()

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = RootBuilder.makeRoot(
            environment: environment,
            onOnboardingComplete: { [weak self] in
                self?.transitionToMain()
            }
        )
        window.makeKeyAndVisible()
        self.window = window
    }

    private func transitionToMain() {
        guard let window else { return }
        let tabBar = MainTabBarController(environment: environment)
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve) {
            window.rootViewController = tabBar
        }
    }
}

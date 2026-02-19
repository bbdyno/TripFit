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
        print("[TripFit] SceneDelegate.scene called")
        guard let windowScene = scene as? UIWindowScene else {
            print("[TripFit] Failed to get windowScene")
            return
        }

        print("[TripFit] Creating AppEnvironment...")
        environment = AppEnvironment.makeDefault()
        environment.seedIfNeeded()
        print("[TripFit] AppEnvironment created, onboarding completed: \(environment.onboardingStore.hasCompletedOnboarding)")

        let rootVC = RootBuilder.makeRoot(
            environment: environment,
            onOnboardingComplete: { [weak self] in
                self?.transitionToMain()
            }
        )
        print("[TripFit] rootVC: \(type(of: rootVC))")

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootVC
        window.makeKeyAndVisible()
        self.window = window
        print("[TripFit] Window set and visible, frame: \(window.frame)")
    }

    private func transitionToMain() {
        guard let window else { return }
        let tabBar = MainTabBarController(environment: environment)
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve) {
            window.rootViewController = tabBar
        }
    }
}

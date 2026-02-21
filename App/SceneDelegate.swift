//
//  SceneDelegate.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var environment: AppEnvironment!
    private var languageObserver: NSObjectProtocol?

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
        print("[TripFit] AppEnvironment created, onboarding completed: \(environment.onboardingStore.hasCompletedOnboarding)")

        let rootVC = RootBuilder.makeRoot(
            environment: environment,
            onOnboardingComplete: { [weak self] in
                self?.transitionToMain()
            }
        )
        print("[TripFit] rootVC: \(type(of: rootVC))")

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.rootViewController = rootVC
        window.makeKeyAndVisible()
        self.window = window
        registerLanguageObserver()
        print("[TripFit] Window set and visible, frame: \(window.frame)")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
            self.languageObserver = nil
        }
    }

    private func transitionToMain() {
        guard let window else { return }
        let tabBar = MainTabBarController(environment: environment)
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve) {
            window.rootViewController = tabBar
        }
    }

    private func registerLanguageObserver() {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
            self.languageObserver = nil
        }

        languageObserver = NotificationCenter.default.addObserver(
            forName: TFAppLanguageCenter.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadRootForLanguageChange()
        }
    }

    private func reloadRootForLanguageChange() {
        guard let window else { return }
        let rootVC = RootBuilder.makeRoot(
            environment: environment,
            onOnboardingComplete: { [weak self] in
                self?.transitionToMain()
            }
        )
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = rootVC
        }
    }
}

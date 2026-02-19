import Features
import UIKit

enum RootBuilder {
    static func makeRoot(
        environment: AppEnvironment,
        onOnboardingComplete: @escaping () -> Void
    ) -> UIViewController {
        if environment.onboardingStore.hasCompletedOnboarding {
            return MainTabBarController(environment: environment)
        } else {
            let vc = OnboardingViewController()
            vc.onComplete = {
                environment.onboardingStore.markCompleted()
                onOnboardingComplete()
            }
            return vc
        }
    }
}

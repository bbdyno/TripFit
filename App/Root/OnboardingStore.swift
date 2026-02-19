import Foundation

final class OnboardingStore {
    private static let key = "tripfit.onboarding.completed.v1"

    var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: Self.key)
    }

    func markCompleted() {
        UserDefaults.standard.set(true, forKey: Self.key)
    }
}

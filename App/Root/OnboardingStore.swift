//
//  OnboardingStore.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Foundation

final class OnboardingStore {
    private static let key = "tripfit.onboarding.completed.v2"

    var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: Self.key)
    }

    func markCompleted() {
        UserDefaults.standard.set(true, forKey: Self.key)
    }
}

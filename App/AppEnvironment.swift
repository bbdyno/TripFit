//
//  AppEnvironment.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Domain
import Foundation
import SwiftData

final class AppEnvironment: @unchecked Sendable {
    let container: ModelContainer
    let onboardingStore: OnboardingStore

    private init(container: ModelContainer, onboardingStore: OnboardingStore) {
        self.container = container
        self.onboardingStore = onboardingStore
    }

    @MainActor
    var context: ModelContext { container.mainContext }

    static func makeDefault() -> AppEnvironment {
        let schema = Schema([
            ClothingItem.self,
            Outfit.self,
            Trip.self,
            PackingItem.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            return AppEnvironment(
                container: container,
                onboardingStore: OnboardingStore()
            )
        } catch {
            fatalError("[TripFit] Failed to create ModelContainer: \(error)")
        }
    }

    @MainActor
    func seedIfNeeded() {
        SeedService.seedIfNeeded(context: context)
    }
}

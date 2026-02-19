import Domain
import Foundation
import SwiftData

@MainActor
final class AppEnvironment {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let onboardingStore: OnboardingStore

    private init(container: ModelContainer, onboardingStore: OnboardingStore) {
        self.container = container
        self.onboardingStore = onboardingStore
    }

    static func makeDefault() -> AppEnvironment {
        let schema = Schema([
            ClothingItem.self,
            Outfit.self,
            Trip.self,
            PackingItem.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [config])
        return AppEnvironment(
            container: container,
            onboardingStore: OnboardingStore()
        )
    }

    func seedIfNeeded() {
        SeedService.seedIfNeeded(context: context)
    }
}

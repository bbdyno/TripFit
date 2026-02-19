//
//  SeedService.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Domain
import Foundation
import SwiftData

enum SeedService {
    private static let flagKey = "tripfit.seeded.v1"

    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: flagKey) else { return }

        do {
            let count = try context.fetchCount(FetchDescriptor<ClothingItem>())
            if count > 0 {
                defaults.set(true, forKey: flagKey)
                return
            }

            let tee = ClothingItem(name: "Sky Tee", category: .tops, color: "Sky", season: .summer)
            let jeans = ClothingItem(name: "Lavender Jeans", category: .bottoms, color: "Lavender", season: .fall)
            let shoes = ClothingItem(name: "Pink Sneakers", category: .shoes, color: "Pink", season: .all)

            context.insert(tee)
            context.insert(jeans)
            context.insert(shoes)

            let outfit = Outfit(name: "City Walk", note: "Comfy + cute", items: [tee, jeans, shoes])
            context.insert(outfit)

            let trip = Trip(
                name: "Tokyo Weekend",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                destination: "Tokyo",
                destinationCountryCode: "JP"
            )
            context.insert(trip)

            let p1 = PackingItem(trip: trip, clothingItem: tee, quantity: 1)
            let p2 = PackingItem(trip: trip, customName: "Travel plug adapter", quantity: 1)
            let p3 = PackingItem(trip: trip, customName: "USB charger", quantity: 1, isPacked: true)
            context.insert(p1)
            context.insert(p2)
            context.insert(p3)

            try context.save()
            defaults.set(true, forKey: flagKey)
        } catch {
            assertionFailure("Seed failed: \(error)")
        }
    }
}

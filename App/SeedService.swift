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
    private static let flagKey = "tripfit.seeded.v2"
    private static let sampleImageURLs: [String: String] = [
        "Sky Tee": "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=900&q=80",
        "Lavender Jeans": "https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=900&q=80",
        "Pink Sneakers": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=80",
    ]

    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: flagKey) else { return }

        do {
            try backfillSampleImageURLsIfNeeded(context: context)

            let count = try context.fetchCount(FetchDescriptor<ClothingItem>())
            if count > 0 {
                defaults.set(true, forKey: flagKey)
                return
            }

            let tee = ClothingItem(
                name: "Sky Tee",
                category: .tops,
                color: "Sky",
                season: .summer,
                imageURL: sampleImageURLs["Sky Tee"]
            )
            let jeans = ClothingItem(
                name: "Lavender Jeans",
                category: .bottoms,
                color: "Lavender",
                season: .fall,
                imageURL: sampleImageURLs["Lavender Jeans"]
            )
            let shoes = ClothingItem(
                name: "Pink Sneakers",
                category: .shoes,
                color: "Pink",
                season: .all,
                imageURL: sampleImageURLs["Pink Sneakers"]
            )

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

    private static func backfillSampleImageURLsIfNeeded(context: ModelContext) throws {
        let descriptor = FetchDescriptor<ClothingItem>()
        let items = try context.fetch(descriptor)

        var hasChanges = false
        for item in items where item.imageData == nil && item.imageURL == nil {
            guard let url = sampleImageURLs[item.name] else { continue }
            item.imageURL = url
            item.updatedAt = Date()
            hasChanges = true
        }

        if hasChanges {
            try context.save()
        }
    }
}

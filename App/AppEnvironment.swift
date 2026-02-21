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

    @MainActor
    static func makeDefault() -> AppEnvironment {
        let schema = Schema([
            ClothingItem.self,
            Outfit.self,
            Trip.self,
            PackingItem.self,
        ])
        let container = ModelContainerBootstrap.makeContainer(schema: schema)
        return AppEnvironment(
            container: container,
            onboardingStore: OnboardingStore()
        )
    }
}

@MainActor
private enum ModelContainerBootstrap {
    static func makeContainer(schema: Schema) -> ModelContainer {
        do {
            return try makeCloudContainer(schema: schema)
        } catch {
            print("[TripFit] Cloud container bootstrap failed: \(error)")
        }

        do {
            return try migrateLocalStoreToCloudIfNeeded(schema: schema)
        } catch {
            print("[TripFit] Automatic store migration failed: \(error)")
        }

        do {
            return try makeLocalContainer(schema: schema)
        } catch {
            print("[TripFit] Local fallback bootstrap failed: \(error)")
        }

        do {
            try purgeKnownStoreFiles()
            return try makeCloudContainer(schema: schema)
        } catch {
            fatalError("[TripFit] Failed to create ModelContainer after recovery attempts: \(error)")
        }
    }

    private static func makeCloudContainer(schema: Schema) throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    private static func makeLocalContainer(schema: Schema) throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    private static func migrateLocalStoreToCloudIfNeeded(schema: Schema) throws -> ModelContainer {
        let snapshot = try autoreleasepool {
            let localContainer = try makeLocalContainer(schema: schema)
            return try PersistenceSnapshot.capture(from: localContainer.mainContext)
        }

        try purgeKnownStoreFiles()
        let cloudContainer = try makeCloudContainer(schema: schema)
        try snapshot.restore(into: cloudContainer.mainContext)
        return cloudContainer
    }

    private static func purgeKnownStoreFiles() throws {
        let directory = try applicationSupportDirectory()
        let manager = FileManager.default

        let knownNames = [
            "default.store",
            "default.store-shm",
            "default.store-wal",
            "default.sqlite",
            "default.sqlite-shm",
            "default.sqlite-wal",
            "TripFit.store",
            "TripFit.store-shm",
            "TripFit.store-wal",
            "TripFit.sqlite",
            "TripFit.sqlite-shm",
            "TripFit.sqlite-wal",
        ]

        for name in knownNames {
            let url = directory.appendingPathComponent(name, isDirectory: false)
            if manager.fileExists(atPath: url.path) {
                try manager.removeItem(at: url)
            }
        }

        let contents = try manager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let prefixes = ["default.store", "default.sqlite", "TripFit.store", "TripFit.sqlite"]
        for url in contents where prefixes.contains(where: { url.lastPathComponent.hasPrefix($0) }) {
            try? manager.removeItem(at: url)
        }
    }

    private static func applicationSupportDirectory() throws -> URL {
        let manager = FileManager.default
        let base = try manager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        if !manager.fileExists(atPath: base.path) {
            try manager.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }
}

private struct PersistenceSnapshot {
    struct ClothingDTO {
        let id: UUID
        let name: String
        let categoryRaw: String
        let color: String?
        let seasonRaw: String?
        let note: String?
        let imageData: Data?
        let imageURL: String?
        let createdAt: Date
        let updatedAt: Date
    }

    struct OutfitDTO {
        let id: UUID
        let name: String
        let note: String?
        let itemIDs: [UUID]
        let createdAt: Date
        let updatedAt: Date
    }

    struct TripDTO {
        let id: UUID
        let name: String
        let startDate: Date
        let endDate: Date
        let destination: String?
        let destinationCountryCode: String?
        let note: String?
        let createdAt: Date
        let updatedAt: Date
    }

    struct PackingDTO {
        let id: UUID
        let tripID: UUID?
        let clothingItemID: UUID?
        let customName: String?
        let quantity: Int
        let isPacked: Bool
        let createdAt: Date
        let updatedAt: Date
    }

    let clothingItems: [ClothingDTO]
    let outfits: [OutfitDTO]
    let trips: [TripDTO]
    let packingItems: [PackingDTO]

    static func capture(from context: ModelContext) throws -> PersistenceSnapshot {
        let clothing = try context.fetch(FetchDescriptor<ClothingItem>())
        let outfits = try context.fetch(FetchDescriptor<Outfit>())
        let trips = try context.fetch(FetchDescriptor<Trip>())
        let packing = try context.fetch(FetchDescriptor<PackingItem>())

        return PersistenceSnapshot(
            clothingItems: clothing.map {
                ClothingDTO(
                    id: $0.id,
                    name: $0.name,
                    categoryRaw: $0.categoryRaw,
                    color: $0.color,
                    seasonRaw: $0.seasonRaw,
                    note: $0.note,
                    imageData: $0.imageData,
                    imageURL: $0.imageURL,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            outfits: outfits.map {
                OutfitDTO(
                    id: $0.id,
                    name: $0.name,
                    note: $0.note,
                    itemIDs: $0.items.map(\.id),
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            trips: trips.map {
                TripDTO(
                    id: $0.id,
                    name: $0.name,
                    startDate: $0.startDate,
                    endDate: $0.endDate,
                    destination: $0.destination,
                    destinationCountryCode: $0.destinationCountryCode,
                    note: $0.note,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            packingItems: packing.map {
                PackingDTO(
                    id: $0.id,
                    tripID: $0.trip?.id,
                    clothingItemID: $0.clothingItem?.id,
                    customName: $0.customName,
                    quantity: $0.quantity,
                    isPacked: $0.isPacked,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            }
        )
    }

    func restore(into context: ModelContext) throws {
        var clothingByID: [UUID: ClothingItem] = [:]
        for dto in clothingItems {
            let item = ClothingItem(
                name: dto.name,
                category: ClothingCategory(rawValue: dto.categoryRaw) ?? .tops,
                color: dto.color,
                season: dto.seasonRaw.flatMap(Season.init(rawValue:)),
                note: dto.note,
                imageData: dto.imageData,
                imageURL: dto.imageURL
            )
            item.id = dto.id
            item.createdAt = dto.createdAt
            item.updatedAt = dto.updatedAt
            context.insert(item)
            clothingByID[dto.id] = item
        }

        var tripByID: [UUID: Trip] = [:]
        for dto in trips {
            let trip = Trip(
                name: dto.name,
                startDate: dto.startDate,
                endDate: dto.endDate,
                destination: dto.destination,
                destinationCountryCode: dto.destinationCountryCode,
                note: dto.note
            )
            trip.id = dto.id
            trip.createdAt = dto.createdAt
            trip.updatedAt = dto.updatedAt
            context.insert(trip)
            tripByID[dto.id] = trip
        }

        for dto in packingItems {
            guard let tripID = dto.tripID, let trip = tripByID[tripID] else { continue }
            let packingItem = PackingItem(
                trip: trip,
                clothingItem: dto.clothingItemID.flatMap { clothingByID[$0] },
                customName: dto.customName,
                quantity: dto.quantity,
                isPacked: dto.isPacked
            )
            packingItem.id = dto.id
            packingItem.createdAt = dto.createdAt
            packingItem.updatedAt = dto.updatedAt
            context.insert(packingItem)
        }

        for dto in outfits {
            let outfit = Outfit(
                name: dto.name,
                note: dto.note,
                items: dto.itemIDs.compactMap { clothingByID[$0] }
            )
            outfit.id = dto.id
            outfit.createdAt = dto.createdAt
            outfit.updatedAt = dto.updatedAt
            context.insert(outfit)
        }

        try context.save()
    }
}

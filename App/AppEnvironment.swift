//
//  AppEnvironment.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import CollaborationData
import Core
import Domain
import Foundation
import SwiftData

final class AppEnvironment: @unchecked Sendable {
    let container: ModelContainer
    let onboardingStore: OnboardingStore
    let authService: any AuthService
    let collaborationRepository: any CollaborationRepository
    let pendingInviteStore: PendingInviteStore
    let accountDeletionService: any AccountDeletionService

    private init(
        container: ModelContainer,
        onboardingStore: OnboardingStore,
        authService: any AuthService,
        collaborationRepository: any CollaborationRepository,
        pendingInviteStore: PendingInviteStore,
        accountDeletionService: any AccountDeletionService
    ) {
        self.container = container
        self.onboardingStore = onboardingStore
        self.authService = authService
        self.collaborationRepository = collaborationRepository
        self.pendingInviteStore = pendingInviteStore
        self.accountDeletionService = accountDeletionService
    }

    @MainActor
    var context: ModelContext { container.mainContext }

    @MainActor
    static func makeDefault() -> AppEnvironment {
#if DEBUG
        if ProcessInfo.processInfo.environment["TRIPFIT_SCREENSHOT_MODE"] == "1" {
            return makeScreenshotEnvironment()
        }
#endif

        let schema = Schema([
            ClothingItem.self,
            Outfit.self,
            Trip.self,
            PackingItem.self,
            TripCollaborationLink.self,
        ])
        let container = ModelContainerBootstrap.makeContainer(schema: schema)
        let authService: any AuthService
        let collaborationRepository: any CollaborationRepository
        let accountDeletionService: any AccountDeletionService
        switch FirebaseRuntime.shared.state {
        case .configured:
            authService = FirebaseAuthService()
            collaborationRepository = FirestoreCollaborationRepository()
            accountDeletionService = FirebaseAccountDeletionService(repository: collaborationRepository)
        case let .unavailable(reason):
            authService = DisabledAuthService(reason: reason)
            collaborationRepository = UnavailableCollaborationRepository(reason: reason)
            accountDeletionService = DisabledAccountDeletionService(reason: reason)
        case .notConfigured:
            authService = DisabledAuthService(reason: "Firebase has not been configured.")
            collaborationRepository = UnavailableCollaborationRepository(
                reason: "Firebase has not been configured."
            )
            accountDeletionService = DisabledAccountDeletionService(
                reason: "Firebase has not been configured."
            )
        }
        let environment = AppEnvironment(
            container: container,
            onboardingStore: OnboardingStore(),
            authService: authService,
            collaborationRepository: collaborationRepository,
            pendingInviteStore: PendingInviteStore(),
            accountDeletionService: accountDeletionService
        )
        Task { _ = await authService.restoreSession() }
        return environment
    }

#if DEBUG
    @MainActor
    private static func makeScreenshotEnvironment() -> AppEnvironment {
        let schema = Schema([
            ClothingItem.self,
            Outfit.self,
            Trip.self,
            PackingItem.self,
            TripCollaborationLink.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("[TripFit] Failed to create screenshot container: \(error)")
        }

        let reason = "Screenshot mode uses local demo data."
        let authService = DisabledAuthService(reason: reason)
        let collaborationRepository = UnavailableCollaborationRepository(reason: reason)
        let environment = AppEnvironment(
            container: container,
            onboardingStore: OnboardingStore(),
            authService: authService,
            collaborationRepository: collaborationRepository,
            pendingInviteStore: PendingInviteStore(),
            accountDeletionService: DisabledAccountDeletionService(reason: reason)
        )
        environment.onboardingStore.markCompleted()
        seedScreenshotData(in: container.mainContext)
        return environment
    }

    @MainActor
    private static func seedScreenshotData(in context: ModelContext) {
        let copy = ScreenshotCopy.current
        let clothing = zip(copy.clothingNames, ClothingCategory.allCases).map { name, category in
            ClothingItem(
                name: name,
                category: category,
                color: copy.color,
                season: .summer,
                note: copy.clothingNote
            )
        }
        clothing.forEach(context.insert)

        let primaryOutfit = Outfit(
            name: copy.primaryOutfit,
            note: copy.outfitNote,
            items: Array(clothing.prefix(3))
        )
        let secondaryOutfit = Outfit(
            name: copy.secondaryOutfit,
            note: copy.outfitNote,
            items: Array(clothing.suffix(3))
        )
        context.insert(primaryOutfit)
        context.insert(secondaryOutfit)

        let calendar = Calendar(identifier: .gregorian)
        let startDate = calendar.date(byAdding: .day, value: 18, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .day, value: 22, to: Date()) ?? startDate
        let trip = Trip(
            name: copy.tripName,
            startDate: startDate,
            endDate: endDate,
            destination: copy.destination,
            destinationCountryCode: "JP",
            note: copy.tripNote
        )
        context.insert(trip)

        let packingNames = copy.packingNames
        for (index, packingName) in packingNames.enumerated() {
            let item = PackingItem(
                trip: trip,
                clothingItem: index < clothing.count ? clothing[index] : nil,
                customName: packingName,
                isPacked: index < 3
            )
            context.insert(item)
        }

        do {
            try context.save()
        } catch {
            fatalError("[TripFit] Failed to seed screenshot data: \(error)")
        }
    }

    private struct ScreenshotCopy {
        let clothingNames: [String]
        let color: String
        let clothingNote: String
        let primaryOutfit: String
        let secondaryOutfit: String
        let outfitNote: String
        let tripName: String
        let destination: String
        let tripNote: String
        let packingNames: [String]

        static var current: ScreenshotCopy {
            switch TFAppLanguage.current() {
            case .korean:
                ScreenshotCopy(
                    clothingNames: ["리넨 셔츠", "와이드 팬츠", "트래블 재킷", "화이트 스니커즈", "데일리 토트백"],
                    color: "네이비",
                    clothingNote: "여행에 가볍게 매치하기 좋은 아이템",
                    primaryOutfit: "도쿄 산책 룩",
                    secondaryOutfit: "저녁 약속 룩",
                    outfitNote: "편안하고 사진이 잘 나오는 조합",
                    tripName: "도쿄 여름 여행",
                    destination: "도쿄, 일본",
                    tripNote: "친구들과 함께 준비하는 4박 5일",
                    packingNames: ["리넨 셔츠", "와이드 팬츠", "트래블 재킷", "화이트 스니커즈", "충전기"]
                )
            case .japanese:
                ScreenshotCopy(
                    clothingNames: ["リネンシャツ", "ワイドパンツ", "トラベルジャケット", "白いスニーカー", "デイリートート"],
                    color: "ネイビー",
                    clothingNote: "旅先で着回しやすいアイテム",
                    primaryOutfit: "東京さんぽコーデ",
                    secondaryOutfit: "ディナーコーデ",
                    outfitNote: "快適で写真映えする組み合わせ",
                    tripName: "東京サマートリップ",
                    destination: "東京、日本",
                    tripNote: "友だちと準備する4泊5日の旅",
                    packingNames: ["リネンシャツ", "ワイドパンツ", "ジャケット", "スニーカー", "充電器"]
                )
            case .simplifiedChinese:
                ScreenshotCopy(
                    clothingNames: ["亚麻衬衫", "阔腿裤", "旅行夹克", "白色运动鞋", "日常托特包"],
                    color: "海军蓝",
                    clothingNote: "适合旅行中轻松搭配",
                    primaryOutfit: "东京漫步穿搭",
                    secondaryOutfit: "晚餐约会穿搭",
                    outfitNote: "舒适又上镜的组合",
                    tripName: "东京夏日之旅",
                    destination: "日本东京",
                    tripNote: "和朋友一起准备五天四晚",
                    packingNames: ["亚麻衬衫", "阔腿裤", "旅行夹克", "白色运动鞋", "充电器"]
                )
            case .traditionalChinese:
                ScreenshotCopy(
                    clothingNames: ["亞麻襯衫", "寬褲", "旅行外套", "白色運動鞋", "日常托特包"],
                    color: "海軍藍",
                    clothingNote: "適合旅行中輕鬆搭配",
                    primaryOutfit: "東京散步穿搭",
                    secondaryOutfit: "晚餐約會穿搭",
                    outfitNote: "舒適又上鏡的組合",
                    tripName: "東京夏日旅行",
                    destination: "日本東京",
                    tripNote: "和朋友一起準備五天四夜",
                    packingNames: ["亞麻襯衫", "寬褲", "旅行外套", "白色運動鞋", "充電器"]
                )
            case .english:
                ScreenshotCopy(
                    clothingNames: ["Linen Shirt", "Wide-Leg Pants", "Travel Jacket", "White Sneakers", "Daily Tote"],
                    color: "Navy",
                    clothingNote: "An easy piece to mix and match while traveling",
                    primaryOutfit: "Tokyo Walking Look",
                    secondaryOutfit: "Dinner Plans Look",
                    outfitNote: "Comfortable, coordinated, and photo-ready",
                    tripName: "Tokyo Summer Escape",
                    destination: "Tokyo, Japan",
                    tripNote: "A five-day trip planned together with friends",
                    packingNames: ["Linen Shirt", "Wide-Leg Pants", "Travel Jacket", "White Sneakers", "Charger"]
                )
            }
        }
    }
#endif
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

    struct CollaborationLinkDTO {
        let roomID: String
        let localTripID: UUID
        let revision: Int
        let createdAt: Date
        let updatedAt: Date
    }

    let clothingItems: [ClothingDTO]
    let outfits: [OutfitDTO]
    let trips: [TripDTO]
    let packingItems: [PackingDTO]
    let collaborationLinks: [CollaborationLinkDTO]

    static func capture(from context: ModelContext) throws -> PersistenceSnapshot {
        let clothing = try context.fetch(FetchDescriptor<ClothingItem>())
        let outfits = try context.fetch(FetchDescriptor<Outfit>())
        let trips = try context.fetch(FetchDescriptor<Trip>())
        let packing = try context.fetch(FetchDescriptor<PackingItem>())
        let collaborationLinks = try context.fetch(FetchDescriptor<TripCollaborationLink>())

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
            },
            collaborationLinks: collaborationLinks.map {
                CollaborationLinkDTO(
                    roomID: $0.roomID,
                    localTripID: $0.localTripID,
                    revision: $0.revision,
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

        for dto in collaborationLinks {
            let link = TripCollaborationLink(
                roomID: dto.roomID,
                localTripID: dto.localTripID,
                revision: dto.revision
            )
            link.createdAt = dto.createdAt
            link.updatedAt = dto.updatedAt
            context.insert(link)
        }

        try context.save()
    }
}

//
//  DeveloperSelfTestRunner.swift
//  TripFit
//
//  Created by bbdyno on 2/21/26.
//

import Core
import Domain
import Foundation
import SwiftData
import UserNotifications

@MainActor
final class DeveloperSelfTestRunner {
    enum Status {
        case passed
        case warning
        case failed
    }

    struct CheckResult {
        let title: String
        let status: Status
        let detail: String
    }

    struct Report {
        let startedAt: Date
        let finishedAt: Date
        let checks: [CheckResult]

        var passedCount: Int { checks.filter { $0.status == .passed }.count }
        var warningCount: Int { checks.filter { $0.status == .warning }.count }
        var failedCount: Int { checks.filter { $0.status == .failed }.count }
        var elapsedSeconds: TimeInterval { finishedAt.timeIntervalSince(startedAt) }
        var hasBlockingFailure: Bool { failedCount > 0 }
    }

    private let context: ModelContext
    private let notificationCenter: DeveloperNotificationCenterClient

    init(
        context: ModelContext,
        notificationCenter: DeveloperNotificationCenterClient = LiveDeveloperNotificationCenterClient()
    ) {
        self.context = context
        self.notificationCenter = notificationCenter
    }

    func runAllChecks() async -> Report {
        let startedAt = Date()

        var checks: [CheckResult] = []
        checks.append(runCheck(title: devLocalized("데이터 CRUD/관계 무결성", "Data CRUD/relationship integrity")) {
            try runDataCRUDCheck()
        })
        checks.append(runCheck(title: devLocalized("목적지/시간대 카탈로그", "Destination/time-zone catalog")) {
            try runDestinationCatalogCheck()
        })
        checks.append(runCheck(title: devLocalized("즐겨찾기 저장소", "Favorites storage")) {
            try runFavoritesStoreCheck()
        })
        checks.append(runCheck(title: devLocalized("언어 해석기", "Language resolver")) {
            try runLanguageResolverCheck()
        })
        checks.append(runCheck(title: devLocalized("App Store 링크", "App Store URLs")) {
            try runAppStoreURLCheck()
        })
        checks.append(await runNotificationCheck())

        return Report(
            startedAt: startedAt,
            finishedAt: Date(),
            checks: checks
        )
    }

    private func runCheck(title: String, _ block: () throws -> String) -> CheckResult {
        do {
            return CheckResult(title: title, status: .passed, detail: try block())
        } catch {
            return CheckResult(
                title: title,
                status: .failed,
                detail: error.localizedDescription
            )
        }
    }

    private func runDataCRUDCheck() throws -> String {
        let marker = "DEV_SELF_TEST_\(UUID().uuidString.prefix(8))"
        try cleanupTemporaryData(marker: marker)
        defer { try? cleanupTemporaryData(marker: marker) }

        let now = Date()
        let clothing = ClothingItem(
            name: "\(marker)_Top",
            category: .tops,
            color: "Black",
            season: .spring,
            note: marker
        )
        let trip = Trip(
            name: "\(marker)_Trip",
            startDate: now,
            endDate: now.addingTimeInterval(24 * 60 * 60),
            destination: "Seoul",
            destinationCountryCode: "KR",
            note: marker
        )
        let packing = PackingItem(
            trip: trip,
            clothingItem: clothing,
            customName: "\(marker)_Packing"
        )
        let outfit = Outfit(
            name: "\(marker)_Outfit",
            note: marker,
            items: [clothing]
        )

        context.insert(clothing)
        context.insert(trip)
        context.insert(packing)
        context.insert(outfit)
        try context.save()

        let clothingItems = try matchingClothing(marker: marker)
        let outfits = try matchingOutfits(marker: marker)
        let trips = try matchingTrips(marker: marker)
        let packingItems = try matchingPacking(marker: marker)

        guard clothingItems.count == 1,
              outfits.count == 1,
              trips.count == 1,
              packingItems.count == 1 else {
            throw DeveloperSelfTestError(
                devLocalized(
                    "저장 후 생성 건수 검증 실패",
                    "Failed to verify inserted object counts"
                )
            )
        }

        guard outfits[0].items.contains(where: { $0.id == clothing.id }) else {
            throw DeveloperSelfTestError(
                devLocalized(
                    "코디-옷장 연관관계 검증 실패",
                    "Failed to verify outfit-item relationship"
                )
            )
        }

        guard packingItems[0].trip?.id == trip.id,
              packingItems[0].clothingItem?.id == clothing.id else {
            throw DeveloperSelfTestError(
                devLocalized(
                    "패킹-여행/옷장 연관관계 검증 실패",
                    "Failed to verify packing-trip/item relationship"
                )
            )
        }

        clothing.note = "\(marker)_Updated"
        outfit.note = "\(marker)_Updated"
        trip.note = "\(marker)_Updated"
        packing.isPacked = true
        clothing.updatedAt = Date()
        outfit.updatedAt = Date()
        trip.updatedAt = Date()
        packing.updatedAt = Date()
        try context.save()

        guard trip.packedCount == 1 else {
            throw DeveloperSelfTestError(
                devLocalized(
                    "업데이트 후 패킹 진행률 계산 실패",
                    "Trip packed-count update validation failed"
                )
            )
        }

        return devLocalized(
            "CRUD 및 관계, 업데이트 저장까지 정상",
            "CRUD, relationships, and update persistence succeeded"
        )
    }

    private func runDestinationCatalogCheck() throws -> String {
        guard let info = TFDestinationCatalog.info(forCountryCode: "KR") else {
            throw DeveloperSelfTestError(devLocalized("KR 목적지 조회 실패", "Failed to resolve KR destination"))
        }
        guard info.timeZoneIdentifier == "Asia/Seoul" else {
            throw DeveloperSelfTestError(
                devLocalized("KR 시간대 매핑 불일치", "Unexpected time-zone mapping for KR")
            )
        }
        guard TFDestinationCatalog.info(matchingDestinationText: "Seoul, South Korea") != nil else {
            throw DeveloperSelfTestError(
                devLocalized("목적지 텍스트 검색 실패", "Destination text lookup failed")
            )
        }
        guard TFDestinationCatalog.locationTimeString(for: info.timeZoneIdentifier) != nil else {
            throw DeveloperSelfTestError(
                devLocalized("현지 시각 포맷 실패", "Failed to format location time")
            )
        }
        guard TFDestinationCatalog.gmtOffsetString(for: info.timeZoneIdentifier) != nil else {
            throw DeveloperSelfTestError(
                devLocalized("GMT 오프셋 계산 실패", "Failed to compute GMT offset")
            )
        }
        guard TFDestinationCatalog.localDeltaString(for: info.timeZoneIdentifier) != nil else {
            throw DeveloperSelfTestError(
                devLocalized("로컬 시차 계산 실패", "Failed to compute local delta")
            )
        }
        return devLocalized("조회/검색/시간 계산 정상", "Lookup, search, and time calculations succeeded")
    }

    private func runFavoritesStoreCheck() throws -> String {
        let id = UUID()
        let store = TFFavoritesStore.shared

        store.setFavorite(id, isFavorite: false)
        guard store.isFavorite(id) == false else {
            throw DeveloperSelfTestError(devLocalized("초기화 실패", "Failed to reset favorite flag"))
        }

        _ = store.toggleFavorite(id)
        guard store.isFavorite(id) else {
            throw DeveloperSelfTestError(devLocalized("즐겨찾기 추가 실패", "Failed to add favorite"))
        }

        _ = store.toggleFavorite(id)
        guard store.isFavorite(id) == false else {
            throw DeveloperSelfTestError(devLocalized("즐겨찾기 해제 실패", "Failed to remove favorite"))
        }

        return devLocalized("토글 및 저장 반영 정상", "Toggle and persistence behaviors succeeded")
    }

    private func runLanguageResolverCheck() throws -> String {
        guard TFAppLanguage.resolve(identifier: "ko-KR") == .korean else {
            throw DeveloperSelfTestError(devLocalized("ko-KR 해석 실패", "ko-KR resolution failed"))
        }
        guard TFAppLanguage.resolve(identifier: "en-US") == .english else {
            throw DeveloperSelfTestError(devLocalized("en-US 해석 실패", "en-US resolution failed"))
        }
        guard !TFAppLanguage.korean.displayName(in: .english).isEmpty,
              !TFAppLanguage.english.displayName(in: .korean).isEmpty else {
            throw DeveloperSelfTestError(devLocalized("표시명 생성 실패", "Failed to generate display names"))
        }

        return devLocalized("언어 해석 및 표시명 정상", "Language resolution and labels succeeded")
    }

    private func runAppStoreURLCheck() throws -> String {
        guard let appURL = TFAppStore.appStoreURL,
              appURL.absoluteString.contains(TFAppStore.appID) else {
            throw DeveloperSelfTestError(
                devLocalized("App Store URL 생성 실패", "Failed to generate App Store URL")
            )
        }
        guard let reviewURL = TFAppStore.writeReviewURL,
              reviewURL.absoluteString.contains("write-review") else {
            throw DeveloperSelfTestError(
                devLocalized("리뷰 URL 생성 실패", "Failed to generate write-review URL")
            )
        }
        return devLocalized("스토어 URL 생성 정상", "Store URL generation succeeded")
    }

    private func runNotificationCheck() async -> CheckResult {
        let title = devLocalized("알림 파이프라인", "Notification pipeline")

        do {
            var settings = await notificationCenter.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                settings = await notificationCenter.notificationSettings()
            }

            let status = settings.authorizationStatus
            guard status == .authorized || status == .provisional || status == .ephemeral else {
                return CheckResult(
                    title: title,
                    status: .warning,
                    detail: devLocalized(
                        "권한 상태: \(authorizationStatusLabel(status)). 알림 권한 허용 후 재실행 필요",
                        "Authorization: \(authorizationStatusLabel(status)). Allow notifications and rerun"
                    )
                )
            }

            let identifier = "tripfit.dev.selftest.\(UUID().uuidString)"
            try await notificationCenter.schedule(
                identifier: identifier,
                title: devLocalized("TripFit 테스트 알림", "TripFit Test Notification"),
                body: devLocalized(
                    "개발자 메뉴 전체 기능 점검 알림입니다.",
                    "Triggered from developer menu full feature check."
                ),
                timeInterval: 5
            )

            let pending = await notificationCenter.pendingRequests()
            guard pending.contains(where: { $0.identifier == identifier }) else {
                throw DeveloperSelfTestError(
                    devLocalized("예약된 테스트 알림 확인 실패", "Scheduled test notification was not found")
                )
            }

            await notificationCenter.removePendingRequests(identifiers: [identifier])
            let remaining = await notificationCenter.pendingRequests()
            guard !remaining.contains(where: { $0.identifier == identifier }) else {
                throw DeveloperSelfTestError(
                    devLocalized("테스트 알림 정리 실패", "Failed to clean up test notification")
                )
            }

            return CheckResult(
                title: title,
                status: .passed,
                detail: devLocalized(
                    "권한 \(authorizationStatusLabel(status)) / 예약 및 정리 성공",
                    "Authorization \(authorizationStatusLabel(status)); scheduling and cleanup succeeded"
                )
            )
        } catch {
            return CheckResult(
                title: title,
                status: .failed,
                detail: error.localizedDescription
            )
        }
    }

    private func matchingClothing(marker: String) throws -> [ClothingItem] {
        let items = try context.fetch(FetchDescriptor<ClothingItem>())
        return items.filter {
            $0.name.contains(marker)
                || ($0.note?.contains(marker) ?? false)
        }
    }

    private func matchingOutfits(marker: String) throws -> [Outfit] {
        let items = try context.fetch(FetchDescriptor<Outfit>())
        return items.filter {
            $0.name.contains(marker)
                || ($0.note?.contains(marker) ?? false)
        }
    }

    private func matchingTrips(marker: String) throws -> [Trip] {
        let items = try context.fetch(FetchDescriptor<Trip>())
        return items.filter {
            $0.name.contains(marker)
                || ($0.note?.contains(marker) ?? false)
        }
    }

    private func matchingPacking(marker: String) throws -> [PackingItem] {
        let items = try context.fetch(FetchDescriptor<PackingItem>())
        return items.filter { $0.customName?.contains(marker) ?? false }
    }

    private func cleanupTemporaryData(marker: String) throws {
        let outfits = try matchingOutfits(marker: marker)
        let trips = try matchingTrips(marker: marker)
        let clothingItems = try matchingClothing(marker: marker)
        let matchingPackingItems = try matchingPacking(marker: marker)

        guard !outfits.isEmpty || !trips.isEmpty || !clothingItems.isEmpty || !matchingPackingItems.isEmpty else {
            return
        }

        let tripIDs = Set(trips.map(\.id))
        let orphanPackingItems = matchingPackingItems.filter { packing in
            guard let tripID = packing.trip?.id else { return true }
            return !tripIDs.contains(tripID)
        }

        outfits.forEach { context.delete($0) }
        trips.forEach { context.delete($0) } // Cascades packing items
        orphanPackingItems.forEach { context.delete($0) }
        clothingItems.forEach { context.delete($0) }
        try context.save()
    }

    private func authorizationStatusLabel(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return devLocalized("미결정", "notDetermined")
        case .denied:
            return devLocalized("거부됨", "denied")
        case .authorized:
            return devLocalized("허용됨", "authorized")
        case .provisional:
            return devLocalized("임시 허용", "provisional")
        case .ephemeral:
            return devLocalized("일시 허용", "ephemeral")
        @unknown default:
            return devLocalized("알 수 없음", "unknown")
        }
    }

}

private func devLocalized(_ ko: String, _ en: String) -> String {
    TFAppLanguage.current() == .korean ? ko : en
}

private struct DeveloperSelfTestError: LocalizedError {
    let message: String
    var errorDescription: String? { message }

    init(_ message: String) {
        self.message = message
    }
}

protocol DeveloperNotificationCenterClient {
    func notificationSettings() async -> UNNotificationSettings
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func schedule(
        identifier: String,
        title: String,
        body: String,
        timeInterval: TimeInterval
    ) async throws
    func pendingRequests() async -> [UNNotificationRequest]
    func removePendingRequests(identifiers: [String]) async
}

private final class LiveDeveloperNotificationCenterClient: DeveloperNotificationCenterClient {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: options) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func schedule(
        identifier: String,
        title: String,
        body: String,
        timeInterval: TimeInterval
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, timeInterval),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    func removePendingRequests(identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

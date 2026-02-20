//
//  DateFormatting.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Foundation

public enum TFDateFormatter {
    private static let mediumFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    public static func medium(_ date: Date) -> String {
        mediumFormatter.string(from: date)
    }

    public static func short(_ date: Date) -> String {
        shortFormatter.string(from: date)
    }

    public static func tripRange(start: Date, end: Date) -> String {
        "\(short(start)) - \(short(end))"
    }
}

public final class TFFavoritesStore {
    public static let shared = TFFavoritesStore()

    private let userDefaults: UserDefaults
    private let key = "tripfit.favorite.clothing.ids.v1"

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func isFavorite(_ itemID: UUID) -> Bool {
        storedIDs.contains(itemID.uuidString)
    }

    @discardableResult
    public func toggleFavorite(_ itemID: UUID) -> Bool {
        var ids = storedIDs
        let id = itemID.uuidString
        let newValue: Bool
        if ids.contains(id) {
            ids.remove(id)
            newValue = false
        } else {
            ids.insert(id)
            newValue = true
        }
        store(ids)
        return newValue
    }

    public func setFavorite(_ itemID: UUID, isFavorite: Bool) {
        var ids = storedIDs
        let id = itemID.uuidString
        if isFavorite {
            ids.insert(id)
        } else {
            ids.remove(id)
        }
        store(ids)
    }

    private var storedIDs: Set<String> {
        let array = userDefaults.array(forKey: key) as? [String] ?? []
        return Set(array)
    }

    private func store(_ ids: Set<String>) {
        userDefaults.set(Array(ids), forKey: key)
    }
}

public enum TFAppInfo {
    public static let appStoreID = TFAppStore.appID

    public static var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    public static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
    }

    public static var shortVersionDescription: String {
        CoreStrings.Format.versionBuild("v\(marketingVersion)", buildNumber)
    }

    public static var aboutVersionDescription: String {
        CoreStrings.Format.versionBuild(marketingVersion, buildNumber)
    }
}

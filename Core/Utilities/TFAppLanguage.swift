//
//  TFAppLanguage.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Foundation

public enum TFAppLanguage: String, CaseIterable {
    case korean = "ko"
    case english = "en"
    case japanese = "ja"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    public var localeIdentifier: String {
        switch self {
        case .korean:
            "ko-KR"
        case .english:
            "en-US"
        case .japanese:
            "ja-JP"
        case .simplifiedChinese:
            "zh-Hans"
        case .traditionalChinese:
            "zh-Hant"
        }
    }

    public var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    public var bilingualLabel: String {
        switch self {
        case .korean:
            "한국어 / Korean"
        case .english:
            "영어 / English"
        case .japanese:
            "일본어 / 日本語"
        case .simplifiedChinese:
            "중국어(간체) / 简体中文"
        case .traditionalChinese:
            "중국어(번체) / 繁體中文"
        }
    }

    public var nativeLabel: String {
        switch self {
        case .korean:
            "한국어"
        case .english:
            "English"
        case .japanese:
            "日本語"
        case .simplifiedChinese:
            "简体中文"
        case .traditionalChinese:
            "繁體中文"
        }
    }

    public func displayName(in _: TFAppLanguage) -> String {
        nativeLabel
    }

    public static func current() -> TFAppLanguage {
        if let languageCodes = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let first = languageCodes.first {
            return resolve(identifier: first)
        }

        if let firstPreferred = Locale.preferredLanguages.first {
            return resolve(identifier: firstPreferred)
        }

        return .english
    }

    public static func resolve(identifier: String) -> TFAppLanguage {
        let normalized = identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        if normalized.hasPrefix("ko") { return .korean }
        if normalized.hasPrefix("ja") { return .japanese }
        if normalized.hasPrefix("zh") {
            if normalized.contains("hant")
                || normalized.contains("-tw")
                || normalized.contains("-hk")
                || normalized.contains("-mo") {
                return .traditionalChinese
            }
            return .simplifiedChinese
        }
        return .english
    }
}

public enum TFAppLanguageCenter {
    public static let didChangeNotification = Notification.Name("tripfit.app.language.didChange")

    @discardableResult
    public static func setLanguage(_ language: TFAppLanguage) -> Bool {
        guard TFAppLanguage.current() != language else { return false }

        let defaults = UserDefaults.standard
        defaults.set([language.localeIdentifier], forKey: "AppleLanguages")
        defaults.synchronize()
        NotificationCenter.default.post(name: didChangeNotification, object: language)
        return true
    }
}

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

    public var localeIdentifier: String {
        switch self {
        case .korean:
            "ko-KR"
        case .english:
            "en-US"
        }
    }

    public var bilingualLabel: String {
        switch self {
        case .korean:
            "한국어 / Korean"
        case .english:
            "영어 / English"
        }
    }

    public var nativeLabel: String {
        switch self {
        case .korean:
            "한국어"
        case .english:
            "English"
        }
    }

    public func displayName(in language: TFAppLanguage) -> String {
        switch (language, self) {
        case (.korean, .korean):
            "한국어"
        case (.korean, .english):
            "영어"
        case (.english, .korean):
            "Korean"
        case (.english, .english):
            "English"
        }
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
        identifier.lowercased().hasPrefix("ko") ? .korean : .english
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

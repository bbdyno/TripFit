//
//  TFAppStore.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import StoreKit
import UIKit

public enum TFAppStore {
    public static let appID = "6759218918"

    public static var appStoreURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appID)")
    }

    public static var writeReviewURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")
    }

    @discardableResult
    public static func openWriteReview() -> Bool {
        guard let url = writeReviewURL else { return false }
        UIApplication.shared.open(url)
        return true
    }

    @discardableResult
    public static func openAppStorePage() -> Bool {
        guard let url = appStoreURL else { return false }
        UIApplication.shared.open(url)
        return true
    }

    public static func requestInAppReview() {
        guard #available(iOS 14.0, *) else {
            SKStoreReviewController.requestReview()
            return
        }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            SKStoreReviewController.requestReview()
            return
        }
        SKStoreReviewController.requestReview(in: scene)
    }
}

//
//  TFLegalDocuments.swift
//  TripFit
//
//  Created by bbdyno on 2/20/26.
//

import Foundation
import UIKit

public enum TFLegalDocument {
    case privacyPolicy
    case termsOfService
    case openSourceLicenses
}

public enum TFLegalDocuments {
    private static let pagesRoot = "https://bbdyno.github.io/TripFit"
    private static let repositoryRoot = "https://github.com/bbdyno/TripFit"

    private static var usesKoreanDocument: Bool {
        TFAppLanguage.current() == .korean
    }

    public static func url(for document: TFLegalDocument) -> URL? {
        let path: String
        let root: String
        switch document {
        case .privacyPolicy:
            root = pagesRoot
            path = usesKoreanDocument
                ? "/docs/privacy-policy.ko/"
                : "/docs/privacy-policy.en/"
        case .termsOfService:
            root = pagesRoot
            path = usesKoreanDocument
                ? "/docs/terms-of-service.ko/"
                : "/docs/terms-of-service.en/"
        case .openSourceLicenses:
            root = repositoryRoot
            path = "/blob/main/LICENSE"
        }
        return URL(string: root + path)
    }

    @discardableResult
    public static func open(_ document: TFLegalDocument) -> Bool {
        guard let url = url(for: document) else { return false }
        UIApplication.shared.open(url)
        return true
    }
}

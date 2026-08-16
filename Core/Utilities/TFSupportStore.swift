//
//  TFSupportStore.swift
//  TripFit
//

import Foundation
import StoreKit

public enum TFSupportProductID: String, CaseIterable, Sendable {
    case coffee = "com.bbdyno.app.tripFit.support.small"
    case chicken = "com.bbdyno.app.tripFit.support.large"

    fileprivate var order: Int {
        switch self {
        case .coffee: 0
        case .chicken: 1
        }
    }
}

public struct TFSupportOffering: Identifiable, Sendable {
    public let id: TFSupportProductID
    public let displayPrice: String

    public init(id: TFSupportProductID, displayPrice: String) {
        self.id = id
        self.displayPrice = displayPrice
    }
}

public enum TFSupportPurchaseResult: Sendable {
    case purchased
    case pending
    case cancelled
}

public enum TFSupportStoreError: Error {
    case productUnavailable
    case failedVerification
}

@MainActor
public final class TFSupportStore {
    public static let shared = TFSupportStore()

    private var productsByID: [TFSupportProductID: Product] = [:]

    private init() {}

    public func loadOfferings() async throws -> [TFSupportOffering] {
        let products = try await Product.products(for: TFSupportProductID.allCases.map(\.rawValue))
        productsByID = Dictionary(uniqueKeysWithValues: products.compactMap { product in
            guard let id = TFSupportProductID(rawValue: product.id) else { return nil }
            return (id, product)
        })

        return productsByID
            .map { TFSupportOffering(id: $0.key, displayPrice: $0.value.displayPrice) }
            .sorted { $0.id.order < $1.id.order }
    }

    public func purchase(_ id: TFSupportProductID) async throws -> TFSupportPurchaseResult {
        let product: Product
        if let cached = productsByID[id] {
            product = cached
        } else {
            guard let loaded = try await Product.products(for: [id.rawValue]).first else {
                throw TFSupportStoreError.productUnavailable
            }
            productsByID[id] = loaded
            product = loaded
        }

        switch try await product.purchase() {
        case let .success(verification):
            let transaction = try verified(verification)
            await transaction.finish()
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case let .verified(value):
            return value
        case .unverified:
            throw TFSupportStoreError.failedVerification
        }
    }
}

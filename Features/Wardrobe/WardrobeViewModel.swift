//
//  WardrobeViewModel.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Core
import Domain
import Foundation
import SwiftData

@MainActor
public final class WardrobeViewModel {
    private let context: ModelContext
    private(set) var items: [ClothingItem] = []
    var selectedCategory: ClothingCategory?
    var searchText: String = ""

    var onChange: (() -> Void)?

    public init(context: ModelContext) {
        self.context = context
    }

    func fetchItems() {
        var descriptor = FetchDescriptor<ClothingItem>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 200

        do {
            var results = try context.fetch(descriptor)

            if let category = selectedCategory {
                results = results.filter { $0.category == category }
            }
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                results = results.filter { $0.name.lowercased().contains(query) }
            }

            items = results
            onChange?()
        } catch {
            items = []
            onChange?()
        }
    }

    func deleteItem(_ item: ClothingItem) {
        context.delete(item)
        try? context.save()
        fetchItems()
    }
}

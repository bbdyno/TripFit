//
//  ClothingItem.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Foundation
import SwiftData

@Model
public final class ClothingItem {
    public var id: UUID
    public var name: String
    public var categoryRaw: String
    public var color: String?
    public var seasonRaw: String?
    public var note: String?
    @Attribute(.externalStorage)
    public var imageData: Data?
    public var imageURL: String?
    public var createdAt: Date
    public var updatedAt: Date

    public var category: ClothingCategory {
        get { ClothingCategory(rawValue: categoryRaw) ?? .tops }
        set { categoryRaw = newValue.rawValue }
    }

    public var season: Season? {
        get { seasonRaw.flatMap { Season(rawValue: $0) } }
        set { seasonRaw = newValue?.rawValue }
    }

    public init(
        name: String,
        category: ClothingCategory,
        color: String? = nil,
        season: Season? = nil,
        note: String? = nil,
        imageData: Data? = nil,
        imageURL: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.color = color
        self.seasonRaw = season?.rawValue
        self.note = note
        self.imageData = imageData
        self.imageURL = imageURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

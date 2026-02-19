import Foundation
import SwiftData

@Model
public final class Outfit {
    public var id: UUID
    public var name: String
    public var note: String?
    @Relationship public var items: [ClothingItem]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        name: String,
        note: String? = nil,
        items: [ClothingItem] = []
    ) {
        self.id = UUID()
        self.name = name
        self.note = note
        self.items = items
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

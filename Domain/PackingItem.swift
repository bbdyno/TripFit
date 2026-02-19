import Foundation
import SwiftData

@Model
public final class PackingItem {
    public var id: UUID
    public var trip: Trip?
    @Relationship public var clothingItem: ClothingItem?
    public var customName: String?
    public var quantity: Int
    public var isPacked: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public var displayName: String {
        clothingItem?.name ?? customName ?? "Unknown"
    }

    public init(
        trip: Trip,
        clothingItem: ClothingItem? = nil,
        customName: String? = nil,
        quantity: Int = 1,
        isPacked: Bool = false
    ) {
        self.id = UUID()
        self.trip = trip
        self.clothingItem = clothingItem
        self.customName = customName
        self.quantity = quantity
        self.isPacked = isPacked
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

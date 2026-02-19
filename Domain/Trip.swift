//
//  Trip.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Foundation
import SwiftData

@Model
public final class Trip {
    public var id: UUID
    public var name: String
    public var startDate: Date
    public var endDate: Date
    public var destination: String?
    public var destinationCountryCode: String?
    public var note: String?
    @Relationship(deleteRule: .cascade, inverse: \PackingItem.trip)
    public var packingItems: [PackingItem]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        name: String,
        startDate: Date,
        endDate: Date,
        destination: String? = nil,
        destinationCountryCode: String? = nil,
        note: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.destination = destination
        self.destinationCountryCode = destinationCountryCode
        self.note = note
        self.packingItems = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    public var packedCount: Int {
        packingItems.filter(\.isPacked).count
    }

    public var totalCount: Int {
        packingItems.count
    }

    public var progressText: String {
        "\(packedCount)/\(totalCount)"
    }
}

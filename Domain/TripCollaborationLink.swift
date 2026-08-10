import Foundation
import SwiftData

@Model
public final class TripCollaborationLink {
    public var roomID: String = ""
    public var localTripID: UUID = UUID()
    public var revision: Int = 0
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(roomID: String, localTripID: UUID, revision: Int) {
        self.roomID = roomID
        self.localTripID = localTripID
        self.revision = revision
    }
}

import Foundation

public enum CollaborationRepositoryError: Error, Equatable, Sendable {
    case unavailable(String)
    case unauthenticated
    case notFound
    case forbidden
    case inviteExpired
    case inviteRevoked
    case roomFull
    case activeRoomLimitReached
    case conflict
    case invalidData(String)
}

public protocol CollaborationRepository: Sendable {
    func observeActiveRooms(for userID: String) -> AsyncThrowingStream<[SharedTripRoom], Error>
    func observeRoom(id: String) -> AsyncThrowingStream<SharedTripRoom, Error>
    func createRoom(_ room: SharedTripRoom, owner: SharedTripMember) async throws
    func fetchRoom(id: String) async throws -> SharedTripRoom
    func fetchMembers(roomID: String) async throws -> [SharedTripMember]
    func fetchAvailability(roomID: String) async throws -> [AvailabilitySubmission]
    func fetchPackingItems(roomID: String) async throws -> [SharedPackingItem]
    func fetchLookPlans(roomID: String) async throws -> [SharedLookPlan]
    func submitAvailability(_ submission: AvailabilitySubmission, roomID: String) async throws
    func confirmSchedule(roomID: String, startDay: String, endDay: String, expectedRevision: Int) async throws
    func upsertPackingItem(_ item: SharedPackingItem) async throws
    func upsertLookPlan(_ plan: SharedLookPlan) async throws
    func createInvite(roomID: String, ownerUID: String, expiresAt: Date) async throws -> URL
    func joinInvite(rawToken: String, member: SharedTripMember) async throws -> String
    func leaveRoom(roomID: String, userID: String) async throws
}

@MainActor
public protocol PendingInviteHandling: AnyObject {
    var rawToken: String? { get }
    func clear()
}

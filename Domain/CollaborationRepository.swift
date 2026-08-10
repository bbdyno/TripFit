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
    func submitAvailability(_ submission: AvailabilitySubmission, roomID: String) async throws
    func upsertPackingItem(_ item: SharedPackingItem) async throws
    func upsertLookPlan(_ plan: SharedLookPlan) async throws
    func createInvite(roomID: String, ownerUID: String, expiresAt: Date) async throws -> URL
    func joinInvite(rawToken: String, member: SharedTripMember) async throws -> String
    func leaveRoom(roomID: String, userID: String) async throws
}

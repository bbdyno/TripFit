import Domain
import Foundation

public struct UnavailableCollaborationRepository: CollaborationRepository {
    private let reason: String

    public init(reason: String) {
        self.reason = reason
    }

    public func observeActiveRooms(for userID: String) -> AsyncThrowingStream<[SharedTripRoom], Error> {
        failedStream()
    }

    public func observeRoom(id: String) -> AsyncThrowingStream<SharedTripRoom, Error> {
        failedStream()
    }

    public func createRoom(_ room: SharedTripRoom, owner: SharedTripMember) async throws {
        throw unavailable
    }

    public func fetchRoom(id: String) async throws -> SharedTripRoom { throw unavailable }

    public func submitAvailability(_ submission: AvailabilitySubmission, roomID: String) async throws {
        throw unavailable
    }

    public func upsertPackingItem(_ item: SharedPackingItem) async throws { throw unavailable }
    public func upsertLookPlan(_ plan: SharedLookPlan) async throws { throw unavailable }
    public func createInvite(roomID: String, ownerUID: String, expiresAt: Date) async throws -> URL {
        throw unavailable
    }
    public func joinInvite(rawToken: String, member: SharedTripMember) async throws -> String { throw unavailable }
    public func leaveRoom(roomID: String, userID: String) async throws { throw unavailable }

    private var unavailable: CollaborationRepositoryError { .unavailable(reason) }

    private func failedStream<Element>() -> AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream { continuation in continuation.finish(throwing: unavailable) }
    }
}

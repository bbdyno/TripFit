import Domain
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
public final class FirebaseAccountDeletionService: AccountDeletionService {
    public private(set) var state: AccountDeletionState = .idle

    private let repository: any CollaborationRepository
    private let database: Firestore
    private let auth: Auth

    public init(
        repository: any CollaborationRepository,
        database: Firestore = .firestore(),
        auth: Auth = .auth()
    ) {
        self.repository = repository
        self.database = database
        self.auth = auth
    }

    public func deleteRemoteAccount() async -> AccountDeletionState {
        guard let user = auth.currentUser else {
            state = .completed
            return state
        }
        let userID = user.uid
        state = .working(step: .checkingRooms, completedRooms: 0, totalRooms: 0)

        let rooms: [SharedTripRoom]
        do {
            let snapshot = try await database.collection("rooms")
                .whereField("memberUids", arrayContains: userID)
                .getDocuments()
            rooms = try snapshot.documents.map { document in
                guard let data = document.data() as [String: Any]?,
                      let ownerUID = data["ownerUid"] as? String,
                      let memberUIDs = data["memberUids"] as? [String],
                      let title = data["title"] as? String,
                      let destination = data["destination"] as? String,
                      let timezoneID = data["timezoneID"] as? String,
                      let start = data["candidateStartDay"] as? String,
                      let end = data["candidateEndDay"] as? String,
                      let duration = data["durationDays"] as? Int,
                      let stageRaw = data["stage"] as? String,
                      let stage = TripRoomStage(rawValue: stageRaw),
                      let revision = data["revision"] as? Int else {
                    throw CollaborationRepositoryError.invalidData("Malformed room during account deletion.")
                }
                return SharedTripRoom(
                    id: document.documentID,
                    ownerUID: ownerUID,
                    memberUIDs: memberUIDs,
                    title: title,
                    destination: destination,
                    countryCode: data["countryCode"] as? String,
                    timezoneID: timezoneID,
                    candidateStartDay: start,
                    candidateEndDay: end,
                    durationDays: duration,
                    stage: stage,
                    confirmedStartDay: data["confirmedStartDay"] as? String,
                    confirmedEndDay: data["confirmedEndDay"] as? String,
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                    revision: revision
                )
            }
        } catch {
            state = .failed(step: .checkingRooms, message: error.localizedDescription)
            return state
        }

        let ownedRoomIDs = rooms.filter { $0.ownerUID == userID }.map(\.id)
        guard ownedRoomIDs.isEmpty else {
            state = .blockedOwnedRooms(ownedRoomIDs)
            return state
        }

        let memberRooms = rooms.filter { $0.ownerUID != userID }
        for (index, room) in memberRooms.enumerated() {
            state = .working(step: .cleaningMemberships, completedRooms: index, totalRooms: memberRooms.count)
            do {
                try await repository.leaveRoom(roomID: room.id, userID: userID)
            } catch {
                state = .failed(step: .cleaningMemberships, message: error.localizedDescription)
                return state
            }
        }

        state = .working(
            step: .deletingUserDocument,
            completedRooms: memberRooms.count,
            totalRooms: memberRooms.count
        )
        do {
            try await database.collection("users").document(userID).delete()
        } catch {
            state = .failed(step: .deletingUserDocument, message: error.localizedDescription)
            return state
        }

        state = .working(
            step: .deletingAuthentication,
            completedRooms: memberRooms.count,
            totalRooms: memberRooms.count
        )
        do {
            try await user.delete()
            state = .completed
        } catch {
            let nsError = error as NSError
            if AuthErrorCode(rawValue: nsError.code) == .requiresRecentLogin {
                state = .requiresReauthentication
            } else {
                state = .failed(step: .deletingAuthentication, message: nsError.localizedDescription)
            }
        }
        return state
    }

    public func reset() { state = .idle }
}

@MainActor
public final class DisabledAccountDeletionService: AccountDeletionService {
    public private(set) var state: AccountDeletionState = .idle
    private let reason: String

    public init(reason: String) { self.reason = reason }

    public func deleteRemoteAccount() async -> AccountDeletionState {
        state = .failed(step: .checkingRooms, message: reason)
        return state
    }

    public func reset() { state = .idle }
}

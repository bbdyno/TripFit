import CryptoKit
import Domain
import FirebaseFirestore
import Foundation
import Security

public final class FirestoreCollaborationRepository: CollaborationRepository, @unchecked Sendable {
    public static let activeRoomLimit = 10

    private let database: Firestore
    private let hostingDomain: String

    public init(
        database: Firestore = .firestore(),
        hostingDomain: String = "tripfit-bbdyno.web.app"
    ) {
        self.database = database
        self.hostingDomain = hostingDomain
    }

    public func observeActiveRooms(for userID: String) -> AsyncThrowingStream<[SharedTripRoom], Error> {
        AsyncThrowingStream { continuation in
            let listener = database.collection("rooms")
                .whereField("memberUids", arrayContains: userID)
                .whereField("stage", in: [TripRoomStage.coordinating.rawValue, TripRoomStage.confirmed.rawValue])
                .order(by: "updatedAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    do {
                        let rooms = try (snapshot?.documents ?? []).map(FirestoreMapper.room)
                        continuation.yield(rooms)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            continuation.onTermination = { @Sendable _ in listener.remove() }
        }
    }

    public func observeRoom(id: String) -> AsyncThrowingStream<SharedTripRoom, Error> {
        AsyncThrowingStream { continuation in
            let listener = database.collection("rooms").document(id).addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: error)
                    return
                }
                guard let snapshot, snapshot.exists else {
                    continuation.finish(throwing: CollaborationRepositoryError.notFound)
                    return
                }
                do {
                    continuation.yield(try FirestoreMapper.room(snapshot))
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in listener.remove() }
        }
    }

    public func createRoom(_ room: SharedTripRoom, owner: SharedTripMember) async throws {
        try CollaborationValidator.validate(room: room)
        guard owner.userID == room.ownerUID, owner.role == .owner else {
            throw CollaborationRepositoryError.invalidData("Owner identity does not match the room.")
        }

        let existing = try await database.collection("rooms")
            .whereField("memberUids", arrayContains: owner.userID)
            .whereField("stage", in: [TripRoomStage.coordinating.rawValue, TripRoomStage.confirmed.rawValue])
            .limit(to: Self.activeRoomLimit)
            .getDocuments()
        guard existing.documents.count < Self.activeRoomLimit else {
            throw CollaborationRepositoryError.activeRoomLimitReached
        }

        let roomRef = database.collection("rooms").document(room.id)
        let memberRef = roomRef.collection("members").document(owner.userID)
        let userRef = database.collection("users").document(owner.userID)
        let batch = database.batch()
        batch.setData(FirestoreMapper.roomData(room), forDocument: roomRef)
        batch.setData(FirestoreMapper.memberData(owner), forDocument: memberRef)
        batch.setData([
            "uid": owner.userID,
            "displayName": owner.displayName as Any,
            "updatedAt": FieldValue.serverTimestamp(),
            "schemaVersion": 1,
        ], forDocument: userRef, merge: true)
        try await batch.commit()
    }

    public func fetchRoom(id: String) async throws -> SharedTripRoom {
        let snapshot = try await database.collection("rooms").document(id).getDocument()
        guard snapshot.exists else { throw CollaborationRepositoryError.notFound }
        return try FirestoreMapper.room(snapshot)
    }

    public func submitAvailability(_ submission: AvailabilitySubmission, roomID: String) async throws {
        let room = try await fetchRoom(id: roomID)
        try CollaborationValidator.validate(submission: submission, in: room)
        let ref = database.collection("rooms").document(roomID)
            .collection("availability").document(submission.ownerUID)
        try await ref.setData(FirestoreMapper.availabilityData(submission))
    }

    public func upsertPackingItem(_ item: SharedPackingItem) async throws {
        guard (1...120).contains(item.title.count),
              (1...99).contains(item.quantity),
              item.category.count <= 40 else {
            throw CollaborationRepositoryError.invalidData("Invalid shared packing item.")
        }
        let ref = database.collection("rooms").document(item.roomID)
            .collection("packingItems").document(item.id)
        try await ref.setData(FirestoreMapper.packingData(item))
    }

    public func upsertLookPlan(_ plan: SharedLookPlan) async throws {
        guard (1...80).contains(plan.outfitName.count),
              plan.categories.count <= 12,
              plan.paletteHex.count <= 8,
              plan.styleTags.count <= 12,
              (0...5).contains(plan.formality),
              (plan.note?.count ?? 0) <= 160 else {
            throw CollaborationRepositoryError.invalidData("Invalid shared look plan metadata.")
        }
        let ref = database.collection("rooms").document(plan.roomID)
            .collection("lookPlans").document(plan.id)
        try await ref.setData(FirestoreMapper.lookPlanData(plan))
    }

    public func createInvite(roomID: String, ownerUID: String, expiresAt: Date) async throws -> URL {
        let rawToken = try InviteTokenFactory.makeRawToken()
        let hash = InviteTokenFactory.hash(rawToken)
        let ref = database.collection("invites").document(hash)
        try await ref.setData([
            "roomId": roomID,
            "createdByUid": ownerUID,
            "expiresAt": Timestamp(date: expiresAt),
            "revoked": false,
            "createdAt": FieldValue.serverTimestamp(),
            "schemaVersion": TripInvite.schemaVersion,
        ])
        guard let url = URL(string: "https://\(hostingDomain)/join/\(rawToken)") else {
            throw CollaborationRepositoryError.invalidData("Invalid invite hosting domain.")
        }
        return url
    }

    public func joinInvite(rawToken: String, member: SharedTripMember) async throws -> String {
        let hash = InviteTokenFactory.hash(rawToken)
        let inviteRef = database.collection("invites").document(hash)

        let value = try await database.runTransaction { transaction, errorPointer -> Any? in
            do {
                let invite = try transaction.getDocument(inviteRef)
                guard let inviteData = invite.data(),
                      let roomID = inviteData["roomId"] as? String,
                      let expiresAt = inviteData["expiresAt"] as? Timestamp,
                      let revoked = inviteData["revoked"] as? Bool else {
                    throw CollaborationRepositoryError.notFound
                }
                guard revoked == false else { throw CollaborationRepositoryError.inviteRevoked }
                guard expiresAt.dateValue() > Date() else { throw CollaborationRepositoryError.inviteExpired }

                let roomRef = self.database.collection("rooms").document(roomID)
                let roomSnapshot = try transaction.getDocument(roomRef)
                guard let roomData = roomSnapshot.data(),
                      var memberUIDs = roomData["memberUids"] as? [String],
                      let revision = roomData["revision"] as? Int else {
                    throw CollaborationRepositoryError.notFound
                }
                if memberUIDs.contains(member.userID) { return roomID }
                guard memberUIDs.count < SharedTripRoom.hardMemberLimit else {
                    throw CollaborationRepositoryError.roomFull
                }
                memberUIDs.append(member.userID)
                transaction.updateData([
                    "memberUids": memberUIDs,
                    "memberCount": memberUIDs.count,
                    "updatedAt": FieldValue.serverTimestamp(),
                    "revision": revision + 1,
                ], forDocument: roomRef)
                transaction.setData(
                    FirestoreMapper.memberData(member),
                    forDocument: roomRef.collection("members").document(member.userID)
                )
                return roomID
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let roomID = value as? String else { throw CollaborationRepositoryError.conflict }
        return roomID
    }

    public func leaveRoom(roomID: String, userID: String) async throws {
        let roomRef = database.collection("rooms").document(roomID)
        _ = try await database.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(roomRef)
                guard let data = snapshot.data(),
                      let ownerUID = data["ownerUid"] as? String,
                      var memberUIDs = data["memberUids"] as? [String],
                      let revision = data["revision"] as? Int else {
                    throw CollaborationRepositoryError.notFound
                }
                guard ownerUID != userID else { throw CollaborationRepositoryError.forbidden }
                guard memberUIDs.contains(userID) else { return nil }
                memberUIDs.removeAll(where: { $0 == userID })
                transaction.updateData([
                    "memberUids": memberUIDs,
                    "memberCount": memberUIDs.count,
                    "updatedAt": FieldValue.serverTimestamp(),
                    "revision": revision + 1,
                ], forDocument: roomRef)
                transaction.deleteDocument(roomRef.collection("members").document(userID))
                transaction.deleteDocument(roomRef.collection("availability").document(userID))
                return true
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        let lookPlans = try await roomRef.collection("lookPlans")
            .whereField("ownerUid", isEqualTo: userID).getDocuments()
        if lookPlans.documents.isEmpty == false {
            let batch = database.batch()
            lookPlans.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
        }
    }
}

private enum InviteTokenFactory {
    static func makeRawToken() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw CollaborationRepositoryError.invalidData("Secure invite token generation failed.")
        }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func hash(_ token: String) -> String {
        SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

private enum FirestoreMapper {
    static func roomData(_ room: SharedTripRoom) -> [String: Any] {
        [
            "ownerUid": room.ownerUID,
            "memberUids": room.memberUIDs,
            "memberCount": room.memberCount,
            "title": room.title,
            "destination": room.destination,
            "countryCode": room.countryCode as Any,
            "timezoneID": room.timezoneID,
            "candidateStartDay": room.candidateStartDay,
            "candidateEndDay": room.candidateEndDay,
            "durationDays": room.durationDays,
            "stage": room.stage.rawValue,
            "confirmedStartDay": room.confirmedStartDay as Any,
            "confirmedEndDay": room.confirmedEndDay as Any,
            "updatedAt": FieldValue.serverTimestamp(),
            "revision": room.revision,
            "schemaVersion": SharedTripRoom.schemaVersion,
        ]
    }

    static func room(_ snapshot: DocumentSnapshot) throws -> SharedTripRoom {
        guard let data = snapshot.data(),
              let ownerUID = data["ownerUid"] as? String,
              let memberUIDs = data["memberUids"] as? [String],
              let memberCount = data["memberCount"] as? Int,
              memberCount == memberUIDs.count,
              let title = data["title"] as? String,
              let destination = data["destination"] as? String,
              let timezoneID = data["timezoneID"] as? String,
              let candidateStartDay = data["candidateStartDay"] as? String,
              let candidateEndDay = data["candidateEndDay"] as? String,
              let durationDays = data["durationDays"] as? Int,
              let stageValue = data["stage"] as? String,
              let stage = TripRoomStage(rawValue: stageValue),
              let revision = data["revision"] as? Int else {
            throw CollaborationRepositoryError.invalidData("Malformed room document: \(snapshot.documentID)")
        }
        return SharedTripRoom(
            id: snapshot.documentID,
            ownerUID: ownerUID,
            memberUIDs: memberUIDs,
            title: title,
            destination: destination,
            countryCode: data["countryCode"] as? String,
            timezoneID: timezoneID,
            candidateStartDay: candidateStartDay,
            candidateEndDay: candidateEndDay,
            durationDays: durationDays,
            stage: stage,
            confirmedStartDay: data["confirmedStartDay"] as? String,
            confirmedEndDay: data["confirmedEndDay"] as? String,
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            revision: revision
        )
    }

    static func memberData(_ member: SharedTripMember) -> [String: Any] {
        [
            "uid": member.userID,
            "displayName": member.displayName as Any,
            "role": member.role.rawValue,
            "isRequired": member.isRequired,
            "joinedAt": Timestamp(date: member.joinedAt),
            "updatedAt": FieldValue.serverTimestamp(),
            "schemaVersion": 1,
        ]
    }

    static func availabilityData(_ submission: AvailabilitySubmission) -> [String: Any] {
        let days = submission.days.map { day in
            [
                "day": day.day,
                "status": day.status.rawValue,
                "slots": Dictionary(uniqueKeysWithValues: day.slots.map { ($0.key.rawValue, $0.value.rawValue) }),
                "source": day.source.rawValue,
            ] as [String: Any]
        }
        return [
            "ownerUid": submission.ownerUID,
            "days": days,
            "leaveUnits": submission.leaveUnits,
            "lateJoin": submission.lateJoin,
            "earlyLeave": submission.earlyLeave,
            "note": submission.note as Any,
            "updatedAt": FieldValue.serverTimestamp(),
            "revision": submission.revision,
            "schemaVersion": AvailabilitySubmission.schemaVersion,
        ]
    }

    static func packingData(_ item: SharedPackingItem) -> [String: Any] {
        [
            "roomId": item.roomID,
            "title": item.title,
            "category": item.category,
            "quantity": item.quantity,
            "assigneeUid": item.assigneeUID as Any,
            "isPacked": item.isPacked,
            "createdByUid": item.createdByUID,
            "updatedAt": FieldValue.serverTimestamp(),
            "revision": item.revision,
            "schemaVersion": SharedPackingItem.schemaVersion,
        ]
    }

    static func lookPlanData(_ plan: SharedLookPlan) -> [String: Any] {
        [
            "roomId": plan.roomID,
            "ownerUid": plan.ownerUID,
            "day": plan.day,
            "outfitName": plan.outfitName,
            "categories": plan.categories,
            "paletteHex": plan.paletteHex,
            "styleTags": plan.styleTags,
            "formality": plan.formality,
            "rainReady": plan.rainReady,
            "note": plan.note as Any,
            "updatedAt": FieldValue.serverTimestamp(),
            "revision": plan.revision,
            "schemaVersion": SharedLookPlan.schemaVersion,
        ]
    }
}

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
                        let documents = snapshot?.documents ?? []
                        FirestoreUsageEstimate.record("observe-active-rooms", reads: documents.count)
                        let rooms = try documents.map(FirestoreMapper.room)
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
                    FirestoreUsageEstimate.record("observe-room", reads: 1)
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
        FirestoreUsageEstimate.record("create-room-preflight", reads: existing.documents.count)
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
            "displayName": owner.displayName ?? NSNull(),
            "updatedAt": FieldValue.serverTimestamp(),
            "schemaVersion": 1,
        ], forDocument: userRef, merge: true)
        try await batch.commit()
        FirestoreUsageEstimate.record("create-room", writes: 3)
    }

    public func fetchRoom(id: String) async throws -> SharedTripRoom {
        let snapshot = try await database.collection("rooms").document(id).getDocument()
        FirestoreUsageEstimate.record("fetch-room", reads: 1)
        guard snapshot.exists else { throw CollaborationRepositoryError.notFound }
        return try FirestoreMapper.room(snapshot)
    }

    public func fetchMembers(roomID: String) async throws -> [SharedTripMember] {
        let snapshot = try await database.collection("rooms").document(roomID)
            .collection("members").getDocuments()
        FirestoreUsageEstimate.record("fetch-members", reads: snapshot.documents.count)
        return try snapshot.documents.map(FirestoreMapper.member)
            .sorted { $0.joinedAt < $1.joinedAt }
    }

    public func fetchAvailability(roomID: String) async throws -> [AvailabilitySubmission] {
        let snapshot = try await database.collection("rooms").document(roomID)
            .collection("availability").getDocuments()
        FirestoreUsageEstimate.record("fetch-availability", reads: snapshot.documents.count)
        return try snapshot.documents.map(FirestoreMapper.availability)
    }

    public func fetchPackingItems(roomID: String) async throws -> [SharedPackingItem] {
        let snapshot = try await database.collection("rooms").document(roomID)
            .collection("packingItems").getDocuments()
        FirestoreUsageEstimate.record("fetch-packing", reads: snapshot.documents.count)
        return try snapshot.documents.map { try FirestoreMapper.packing($0, roomID: roomID) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public func fetchLookPlans(roomID: String) async throws -> [SharedLookPlan] {
        let snapshot = try await database.collection("rooms").document(roomID)
            .collection("lookPlans").getDocuments()
        FirestoreUsageEstimate.record("fetch-look-plans", reads: snapshot.documents.count)
        return try snapshot.documents.map { try FirestoreMapper.lookPlan($0, roomID: roomID) }
            .sorted { $0.day < $1.day }
    }

    public func submitAvailability(_ submission: AvailabilitySubmission, roomID: String) async throws {
        let room = try await fetchRoom(id: roomID)
        try CollaborationValidator.validate(submission: submission, in: room)
        let ref = database.collection("rooms").document(roomID)
            .collection("availability").document(submission.ownerUID)
        try await ref.setData(FirestoreMapper.availabilityData(submission))
        FirestoreUsageEstimate.record("submit-availability", writes: 1)
    }

    public func confirmSchedule(
        roomID: String,
        startDay: String,
        endDay: String,
        expectedRevision: Int
    ) async throws {
        let ref = database.collection("rooms").document(roomID)
        _ = try await database.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard let revision = snapshot.data()?["revision"] as? Int,
                      revision == expectedRevision else {
                    throw CollaborationRepositoryError.conflict
                }
                transaction.updateData([
                    "stage": TripRoomStage.confirmed.rawValue,
                    "confirmedStartDay": startDay,
                    "confirmedEndDay": endDay,
                    "updatedAt": FieldValue.serverTimestamp(),
                    "revision": revision + 1,
                ], forDocument: ref)
                return true
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        FirestoreUsageEstimate.record("confirm-schedule", reads: 1, writes: 1)
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
        FirestoreUsageEstimate.record("upsert-packing", writes: 1)
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
        FirestoreUsageEstimate.record("upsert-look-plan", writes: 1)
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
            "revision": 0,
            "schemaVersion": TripInvite.schemaVersion,
        ])
        FirestoreUsageEstimate.record("create-invite", writes: 1)
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
                      let revoked = inviteData["revoked"] as? Bool,
                      let inviteRevision = inviteData["revision"] as? Int else {
                    throw CollaborationRepositoryError.notFound
                }
                guard revoked == false else { throw CollaborationRepositoryError.inviteRevoked }
                guard expiresAt.dateValue() > Date() else { throw CollaborationRepositoryError.inviteExpired }

                let roomRef = self.database.collection("rooms").document(roomID)
                transaction.updateData([
                    "memberUids": FieldValue.arrayUnion([member.userID]),
                    "memberCount": FieldValue.increment(Int64(1)),
                    "updatedAt": FieldValue.serverTimestamp(),
                    "revision": FieldValue.increment(Int64(1)),
                ], forDocument: roomRef)
                transaction.setData(
                    FirestoreMapper.memberData(member, inviteHash: hash),
                    forDocument: roomRef.collection("members").document(member.userID)
                )
                transaction.updateData([
                    "lastJoinUid": member.userID,
                    "lastJoinAt": FieldValue.serverTimestamp(),
                    "revision": inviteRevision + 1,
                ], forDocument: inviteRef)
                return roomID
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let roomID = value as? String else { throw CollaborationRepositoryError.conflict }
        FirestoreUsageEstimate.record("join-invite", reads: 1, writes: 3)
        return roomID
    }

    public func leaveRoom(roomID: String, userID: String) async throws {
        let roomRef = database.collection("rooms").document(roomID)
        let lookPlans = try await roomRef.collection("lookPlans")
            .whereField("ownerUid", isEqualTo: userID).getDocuments()
        let assignedPacking = try await roomRef.collection("packingItems")
            .whereField("assigneeUid", isEqualTo: userID).getDocuments()
        FirestoreUsageEstimate.record(
            "leave-room-preflight",
            reads: lookPlans.documents.count + assignedPacking.documents.count
        )
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
                lookPlans.documents.forEach { transaction.deleteDocument($0.reference) }
                for document in assignedPacking.documents {
                    let itemRevision = document.data()["revision"] as? Int ?? 0
                    transaction.updateData([
                        "assigneeUid": NSNull(),
                        "isPacked": false,
                        "updatedAt": FieldValue.serverTimestamp(),
                        "revision": itemRevision + 1,
                    ], forDocument: document.reference)
                }
                return true
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        FirestoreUsageEstimate.record(
            "leave-room",
            reads: 1,
            writes: 3 + lookPlans.documents.count + assignedPacking.documents.count
        )

    }
}

enum InviteTokenFactory {
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

enum FirestoreMapper {
    static func roomData(_ room: SharedTripRoom) -> [String: Any] {
        [
            "ownerUid": room.ownerUID,
            "memberUids": room.memberUIDs,
            "memberCount": room.memberCount,
            "title": room.title,
            "destination": room.destination,
            "countryCode": room.countryCode ?? NSNull(),
            "timezoneID": room.timezoneID,
            "candidateStartDay": room.candidateStartDay,
            "candidateEndDay": room.candidateEndDay,
            "candidateDayCount": (try? CalendarDayCodec.days(
                from: room.candidateStartDay,
                through: room.candidateEndDay,
                timezoneID: room.timezoneID
            ).count) ?? 0,
            "durationDays": room.durationDays,
            "stage": room.stage.rawValue,
            "confirmedStartDay": room.confirmedStartDay ?? NSNull(),
            "confirmedEndDay": room.confirmedEndDay ?? NSNull(),
            "updatedAt": FieldValue.serverTimestamp(),
            "revision": room.revision,
            "schemaVersion": SharedTripRoom.schemaVersion,
        ]
    }

    static func room(_ snapshot: DocumentSnapshot) throws -> SharedTripRoom {
        guard let data = snapshot.data() else {
            throw CollaborationRepositoryError.invalidData("Malformed room document: \(snapshot.documentID)")
        }
        return try room(documentID: snapshot.documentID, data: data)
    }

    static func room(documentID: String, data: [String: Any]) throws -> SharedTripRoom {
        guard let ownerUID = data["ownerUid"] as? String,
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
            throw CollaborationRepositoryError.invalidData("Malformed room document: \(documentID)")
        }
        return SharedTripRoom(
            id: documentID,
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

    static func memberData(_ member: SharedTripMember, inviteHash: String? = nil) -> [String: Any] {
        var data: [String: Any] = [
            "uid": member.userID,
            "displayName": member.displayName ?? NSNull(),
            "role": member.role.rawValue,
            "isRequired": member.isRequired,
            "joinedAt": Timestamp(date: member.joinedAt),
            "updatedAt": FieldValue.serverTimestamp(),
            "schemaVersion": 1,
        ]
        if let inviteHash { data["inviteHash"] = inviteHash }
        return data
    }

    static func member(_ snapshot: DocumentSnapshot) throws -> SharedTripMember {
        guard let data = snapshot.data(),
              let uid = data["uid"] as? String,
              let roleValue = data["role"] as? String,
              let role = SharedTripMemberRole(rawValue: roleValue),
              let isRequired = data["isRequired"] as? Bool,
              let joinedAt = data["joinedAt"] as? Timestamp else {
            throw CollaborationRepositoryError.invalidData("Malformed member: \(snapshot.documentID)")
        }
        return SharedTripMember(
            userID: uid,
            displayName: data["displayName"] as? String,
            role: role,
            isRequired: isRequired,
            joinedAt: joinedAt.dateValue()
        )
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
            "dayCount": days.count,
            "firstDay": submission.days.map(\.day).min() ?? NSNull(),
            "lastDay": submission.days.map(\.day).max() ?? NSNull(),
            "statusValues": Array(Set(submission.days.map(\.status.rawValue))).sorted(),
            "leaveUnits": submission.leaveUnits,
            "lateJoin": submission.lateJoin,
            "earlyLeave": submission.earlyLeave,
            "note": submission.note ?? NSNull(),
            "updatedAt": FieldValue.serverTimestamp(),
            "revision": submission.revision,
            "schemaVersion": AvailabilitySubmission.schemaVersion,
        ]
    }

    static func availability(_ snapshot: DocumentSnapshot) throws -> AvailabilitySubmission {
        guard let data = snapshot.data(),
              let ownerUID = data["ownerUid"] as? String,
              let rawDays = data["days"] as? [[String: Any]],
              let leaveNumber = data["leaveUnits"] as? NSNumber,
              let lateJoin = data["lateJoin"] as? Bool,
              let earlyLeave = data["earlyLeave"] as? Bool,
              let revision = data["revision"] as? Int else {
            throw CollaborationRepositoryError.invalidData("Malformed availability: \(snapshot.documentID)")
        }
        let days: [AvailabilityDay] = try rawDays.map { day in
            guard let value = day["day"] as? String,
                  let statusValue = day["status"] as? String,
                  let status = AvailabilityStatus(rawValue: statusValue),
                  let sourceValue = day["source"] as? String,
                  let source = AvailabilitySource(rawValue: sourceValue) else {
                throw CollaborationRepositoryError.invalidData("Malformed availability day.")
            }
            let slots: [AvailabilityTimeSlot: AvailabilityStatus] =
                (day["slots"] as? [String: String] ?? [:]).reduce(into: [:]) { result, pair in
                guard let slot = AvailabilityTimeSlot(rawValue: pair.key),
                      let slotStatus = AvailabilityStatus(rawValue: pair.value) else { return }
                result[slot] = slotStatus
            }
            return AvailabilityDay(day: value, status: status, slots: slots, source: source)
        }
        return AvailabilitySubmission(
            ownerUID: ownerUID,
            days: days,
            leaveUnits: leaveNumber.doubleValue,
            lateJoin: lateJoin,
            earlyLeave: earlyLeave,
            note: data["note"] as? String,
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            revision: revision
        )
    }

    static func packingData(_ item: SharedPackingItem) -> [String: Any] {
        [
            "roomId": item.roomID,
            "title": item.title,
            "category": item.category,
            "quantity": item.quantity,
            "assigneeUid": item.assigneeUID ?? NSNull(),
            "isPacked": item.isPacked,
            "createdByUid": item.createdByUID,
            "updatedAt": FieldValue.serverTimestamp(),
            "revision": item.revision,
            "schemaVersion": SharedPackingItem.schemaVersion,
        ]
    }

    static func packing(_ snapshot: DocumentSnapshot, roomID: String) throws -> SharedPackingItem {
        guard let data = snapshot.data(),
              let title = data["title"] as? String,
              let category = data["category"] as? String,
              let quantity = data["quantity"] as? Int,
              let isPacked = data["isPacked"] as? Bool,
              let createdByUID = data["createdByUid"] as? String,
              let revision = data["revision"] as? Int else {
            throw CollaborationRepositoryError.invalidData("Malformed packing item: \(snapshot.documentID)")
        }
        return SharedPackingItem(
            id: snapshot.documentID,
            roomID: roomID,
            title: title,
            category: category,
            quantity: quantity,
            assigneeUID: data["assigneeUid"] as? String,
            isPacked: isPacked,
            createdByUID: createdByUID,
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            revision: revision
        )
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
            "note": plan.note ?? NSNull(),
            "updatedAt": FieldValue.serverTimestamp(),
            "revision": plan.revision,
            "schemaVersion": SharedLookPlan.schemaVersion,
        ]
    }

    static func lookPlan(_ snapshot: DocumentSnapshot, roomID: String) throws -> SharedLookPlan {
        guard let data = snapshot.data(),
              let ownerUID = data["ownerUid"] as? String,
              let day = data["day"] as? String,
              let outfitName = data["outfitName"] as? String,
              let categories = data["categories"] as? [String],
              let paletteHex = data["paletteHex"] as? [String],
              let styleTags = data["styleTags"] as? [String],
              let formality = data["formality"] as? Int,
              let rainReady = data["rainReady"] as? Bool,
              let revision = data["revision"] as? Int else {
            throw CollaborationRepositoryError.invalidData("Malformed look plan: \(snapshot.documentID)")
        }
        return SharedLookPlan(
            id: snapshot.documentID,
            roomID: roomID,
            ownerUID: ownerUID,
            day: day,
            outfitName: outfitName,
            categories: categories,
            paletteHex: paletteHex,
            styleTags: styleTags,
            formality: formality,
            rainReady: rainReady,
            note: data["note"] as? String,
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            revision: revision
        )
    }
}

private enum FirestoreUsageEstimate {
    static func record(_ operation: String, reads: Int = 0, writes: Int = 0) {
        #if DEBUG
        print("[TripFit][FirebaseUsage] \(operation) estimatedReads=\(reads) estimatedWrites=\(writes)")
        #endif
    }
}

@testable import CollaborationData
import Domain
import XCTest

final class FirestoreMapperTests: XCTestCase {
    func testRoomDictionaryMapsCalendarDaysWithoutUTCConversion() throws {
        let room = try FirestoreMapper.room(documentID: "room-1", data: [
            "ownerUid": "owner",
            "memberUids": ["owner", "guest"],
            "memberCount": 2,
            "title": "Seoul Together",
            "destination": "Seoul",
            "countryCode": "KR",
            "timezoneID": "Asia/Seoul",
            "candidateStartDay": "2026-09-01",
            "candidateEndDay": "2026-09-05",
            "durationDays": 3,
            "stage": "confirmed",
            "confirmedStartDay": "2026-09-02",
            "confirmedEndDay": "2026-09-04",
            "revision": 4,
        ])

        XCTAssertEqual(room.id, "room-1")
        XCTAssertEqual(room.memberUIDs, ["owner", "guest"])
        XCTAssertEqual(room.candidateStartDay, "2026-09-01")
        XCTAssertEqual(room.confirmedEndDay, "2026-09-04")
        XCTAssertEqual(room.revision, 4)
    }

    func testRoomDictionaryRejectsMemberCountMismatch() {
        XCTAssertThrowsError(try FirestoreMapper.room(documentID: "room-1", data: [
            "ownerUid": "owner",
            "memberUids": ["owner", "guest"],
            "memberCount": 1,
            "title": "Seoul Together",
            "destination": "Seoul",
            "timezoneID": "Asia/Seoul",
            "candidateStartDay": "2026-09-01",
            "candidateEndDay": "2026-09-05",
            "durationDays": 3,
            "stage": "coordinating",
            "revision": 0,
        ]))
    }

    func testInviteTokenIsAtLeastThirtyTwoBytesAndOnlyHashIsDeterministic() throws {
        let token = try InviteTokenFactory.makeRawToken()
        let padded = token
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .padding(toLength: ((token.count + 3) / 4) * 4, withPad: "=", startingAt: 0)

        XCTAssertGreaterThanOrEqual(Data(base64Encoded: padded)?.count ?? 0, 32)
        XCTAssertFalse(token.contains("="))
        XCTAssertEqual(
            InviteTokenFactory.hash("tripfit-invite"),
            "f42f9a2d6be28dba4fa4c7d0c8bf90563881bb428a8ce0d865e1f21d6b9993ed"
        )
    }

    func testLookPlanPayloadContainsMetadataOnly() {
        let plan = SharedLookPlan(
            id: "owner_2026-09-01",
            roomID: "room-1",
            ownerUID: "owner",
            day: "2026-09-01",
            outfitName: "Rainy city walk",
            categories: ["outerwear"],
            paletteHex: ["#223344"],
            styleTags: ["casual"],
            formality: 1,
            rainReady: true,
            note: "Pack an umbrella"
        )
        let data = FirestoreMapper.lookPlanData(plan)

        XCTAssertNil(data["image"])
        XCTAssertNil(data["imageData"])
        XCTAssertNil(data["clothingItemID"])
        XCTAssertEqual(data["outfitName"] as? String, "Rainy city walk")
        XCTAssertEqual(data["paletteHex"] as? [String], ["#223344"])
    }
}

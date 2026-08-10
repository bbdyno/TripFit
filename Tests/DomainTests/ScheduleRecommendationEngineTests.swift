import Domain
import XCTest

final class ScheduleRecommendationEngineTests: XCTestCase {
    func testReturnsAtMostTopThreeContiguousCandidates() throws {
        let room = makeRoom(end: "2026-09-08", duration: 3)
        let candidates = try ScheduleRecommendationEngine().recommend(
            room: room,
            members: [member("owner")],
            submissions: [submission("owner", room: room, status: .available)]
        )

        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].startDay, "2026-09-01")
        XCTAssertEqual(candidates[0].endDay, "2026-09-03")
    }

    func testUnsubmittedMemberIsNeverCountedAvailable() throws {
        let room = makeRoom()
        let candidate = try XCTUnwrap(ScheduleRecommendationEngine().recommend(
            room: room,
            members: [member("owner"), member("guest")],
            submissions: [submission("owner", room: room, status: .available)]
        ).first)

        XCTAssertEqual(candidate.availableMemberUIDs, ["owner"])
        XCTAssertEqual(candidate.undecidedMemberUIDs, ["guest"])
        XCTAssertTrue(candidate.reasons.contains("unsubmitted-or-undecided:1"))
    }

    func testRequiredUnavailableMemberLowersRequiredCoverage() throws {
        let room = makeRoom()
        let members = [member("owner"), member("required", required: true)]
        let submissions = [
            submission("owner", room: room, status: .available),
            submission("required", room: room, status: .unavailable),
        ]
        let candidate = try XCTUnwrap(ScheduleRecommendationEngine().recommend(
            room: room, members: members, submissions: submissions
        ).first)

        XCTAssertEqual(candidate.score.requiredMemberCoverage, 0)
        XCTAssertEqual(candidate.unavailableMemberUIDs, ["required"])
    }

    func testManualAvailabilityOverridesCalendarSuggestion() {
        let manual = AvailabilityDay(day: "2026-09-02", status: .available, source: .manual)
        let suggestion = AvailabilityDay(
            day: "2026-09-02", status: .unavailable, source: .calendarSuggestion
        )
        let merged = AvailabilityDraftMerger.merging(manualDays: [manual], calendarSuggestions: [suggestion])

        XCTAssertEqual(merged, [manual])
    }

    func testCalendarDayRoundTripUsesRoomTimezone() throws {
        let date = try CalendarDayCodec.date(from: "2026-03-29", timezoneID: "Asia/Seoul")
        XCTAssertEqual(CalendarDayCodec.string(from: date, timezoneID: "Asia/Seoul"), "2026-03-29")
        XCTAssertEqual(CalendarDayCodec.string(from: date, timezoneID: "America/Los_Angeles"), "2026-03-28")
    }

    func testRecommendationIsDeterministic() throws {
        let room = makeRoom(end: "2026-09-06", duration: 2)
        let members = [member("owner"), member("guest")]
        let submissions = members.map { submission($0.userID, room: room, status: .maybe) }
        let engine = ScheduleRecommendationEngine()

        XCTAssertEqual(
            try engine.recommend(room: room, members: members, submissions: submissions),
            try engine.recommend(room: room, members: members, submissions: submissions)
        )
    }

    func testInviteLinkParserAcceptsOnlyExpectedHostingPath() {
        XCTAssertEqual(
            InviteLinkParser.rawToken(
                from: URL(string: "https://tripfit-bbdyno.web.app/join/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ")!
            ),
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ"
        )
        XCTAssertNil(
            InviteLinkParser.rawToken(
                from: URL(string: "https://example.com/join/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ")!
            )
        )
        XCTAssertNil(InviteLinkParser.rawToken(from: URL(string: "https://tripfit-bbdyno.web.app/other/token")!))
    }

    private func makeRoom(end: String = "2026-09-04", duration: Int = 2) -> SharedTripRoom {
        SharedTripRoom(
            id: "room", ownerUID: "owner", memberUIDs: ["owner", "guest"],
            title: "Tokyo", destination: "Tokyo", countryCode: "JP", timezoneID: "Asia/Tokyo",
            candidateStartDay: "2026-09-01", candidateEndDay: end, durationDays: duration
        )
    }

    private func member(_ id: String, required: Bool = false) -> SharedTripMember {
        SharedTripMember(userID: id, displayName: nil, role: id == "owner" ? .owner : .member, isRequired: required)
    }

    private func submission(
        _ userID: String,
        room: SharedTripRoom,
        status: AvailabilityStatus
    ) -> AvailabilitySubmission {
        let days = (try? CalendarDayCodec.days(
            from: room.candidateStartDay,
            through: room.candidateEndDay,
            timezoneID: room.timezoneID
        )) ?? []
        return AvailabilitySubmission(ownerUID: userID, days: days.map { AvailabilityDay(day: $0, status: status) })
    }
}

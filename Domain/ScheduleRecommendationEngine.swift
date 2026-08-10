import Foundation

public struct ScheduleScoringPolicy: Equatable, Sendable {
    public var participationWeight: Double
    public var certaintyWeight: Double
    public var leaveEfficiencyWeight: Double
    public var arrivalFlexibilityWeight: Double
    public var requiredMemberWeight: Double
    public var fairnessWeight: Double

    public static let `default` = ScheduleScoringPolicy(
        participationWeight: 40,
        certaintyWeight: 20,
        leaveEfficiencyWeight: 15,
        arrivalFlexibilityWeight: 10,
        requiredMemberWeight: 10,
        fairnessWeight: 5
    )
}

public struct ScheduleRecommendationEngine: Sendable {
    private let policy: ScheduleScoringPolicy

    public init(policy: ScheduleScoringPolicy = .default) {
        self.policy = policy
    }

    public func recommend(
        room: SharedTripRoom,
        members: [SharedTripMember],
        submissions: [AvailabilitySubmission],
        limit: Int = 3
    ) throws -> [ScheduleCandidate] {
        try CollaborationValidator.validate(room: room)
        let allDays = try CalendarDayCodec.days(
            from: room.candidateStartDay,
            through: room.candidateEndDay,
            timezoneID: room.timezoneID
        )
        guard allDays.count >= room.durationDays else { return [] }
        let submissionByUser = Dictionary(uniqueKeysWithValues: submissions.map { ($0.ownerUID, $0) })

        return (0...(allDays.count - room.durationDays))
            .map { offset in
                score(
                    days: Array(allDays[offset..<(offset + room.durationDays)]),
                    members: members,
                    submissionByUser: submissionByUser
                )
            }
            .sorted {
                if $0.score.total == $1.score.total { return $0.startDay < $1.startDay }
                return $0.score.total > $1.score.total
            }
            .prefix(max(0, limit))
            .map { $0 }
    }

    private func score(
        days: [String],
        members: [SharedTripMember],
        submissionByUser: [String: AvailabilitySubmission]
    ) -> ScheduleCandidate {
        var available: [String] = []
        var maybe: [String] = []
        var unavailable: [String] = []
        var undecided: [String] = []
        var leaveUnits: [Double] = []
        var lateJoinCount = 0
        var earlyLeaveCount = 0

        for member in members {
            guard let submission = submissionByUser[member.userID] else {
                undecided.append(member.userID)
                continue
            }
            let statuses = days.compactMap { submission.day($0)?.status }
            let aggregate: AvailabilityStatus
            if statuses.count != days.count || statuses.contains(.undecided) {
                aggregate = .undecided
            } else if statuses.contains(.unavailable) {
                aggregate = .unavailable
            } else if statuses.contains(.maybe) {
                aggregate = .maybe
            } else {
                aggregate = .available
            }
            switch aggregate {
            case .available: available.append(member.userID)
            case .maybe: maybe.append(member.userID)
            case .unavailable: unavailable.append(member.userID)
            case .undecided: undecided.append(member.userID)
            }
            leaveUnits.append(submission.leaveUnits)
            lateJoinCount += submission.lateJoin ? 1 : 0
            earlyLeaveCount += submission.earlyLeave ? 1 : 0
        }

        let count = max(1, members.count)
        let participationRatio = (Double(available.count) + Double(maybe.count) * 0.5) / Double(count)
        let certaintyRatio = Double(available.count + unavailable.count) / Double(count)
        let maximumLeave = Double(max(1, days.count))
        let totalLeave = leaveUnits.reduce(0, +)
        let leaveRatio = max(0, 1 - totalLeave / (Double(count) * maximumLeave))
        let arrivalRatio = max(0, 1 - Double(lateJoinCount + earlyLeaveCount) / Double(count * 2))
        let required = members.filter(\.isRequired)
        let requiredCovered = required.filter { available.contains($0.userID) || maybe.contains($0.userID) }.count
        let requiredRatio = required.isEmpty ? 1 : Double(requiredCovered) / Double(required.count)
        let spread = (leaveUnits.max() ?? 0) - (leaveUnits.min() ?? 0)
        let fairnessRatio = max(0, 1 - spread / maximumLeave)
        let breakdown = ScheduleScoreBreakdown(
            participation: participationRatio * policy.participationWeight,
            certainty: certaintyRatio * policy.certaintyWeight,
            leaveEfficiency: leaveRatio * policy.leaveEfficiencyWeight,
            arrivalFlexibility: arrivalRatio * policy.arrivalFlexibilityWeight,
            requiredMemberCoverage: requiredRatio * policy.requiredMemberWeight,
            fairness: fairnessRatio * policy.fairnessWeight
        )

        var reasons = ["available:\(available.count)", "maybe:\(maybe.count)"]
        if undecided.isEmpty == false { reasons.append("unsubmitted-or-undecided:\(undecided.count)") }
        if required.isEmpty == false { reasons.append("required-covered:\(requiredCovered)/\(required.count)") }
        let minimumChanges = unavailable.map { "\($0):unavailable-to-maybe" }
            + undecided.map { "\($0):submit-availability" }

        return ScheduleCandidate(
            startDay: days.first ?? "",
            endDay: days.last ?? "",
            score: breakdown,
            availableMemberUIDs: available.sorted(),
            maybeMemberUIDs: maybe.sorted(),
            unavailableMemberUIDs: unavailable.sorted(),
            undecidedMemberUIDs: undecided.sorted(),
            requiredLeaveUnits: totalLeave,
            lateJoinCount: lateJoinCount,
            earlyLeaveCount: earlyLeaveCount,
            reasons: reasons,
            minimumChanges: minimumChanges
        )
    }
}

public enum AvailabilityDraftMerger {
    public static func merging(
        manualDays: [AvailabilityDay],
        calendarSuggestions: [AvailabilityDay]
    ) -> [AvailabilityDay] {
        var byDay = Dictionary(uniqueKeysWithValues: calendarSuggestions.map { ($0.day, $0) })
        for manual in manualDays {
            byDay[manual.day] = manual
        }
        return byDay.values.sorted { $0.day < $1.day }
    }
}

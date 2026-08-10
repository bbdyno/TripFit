import Foundation

public enum TripRoomStage: String, Codable, CaseIterable, Sendable {
    case coordinating
    case confirmed
    case completed
    case archived
}

public enum SharedTripMemberRole: String, Codable, Sendable {
    case owner
    case member
}

public enum AvailabilityStatus: String, Codable, CaseIterable, Sendable {
    case available
    case maybe
    case unavailable
    case undecided
}

public enum AvailabilityTimeSlot: String, Codable, CaseIterable, Sendable {
    case morning
    case afternoon
    case evening
}

public enum AvailabilitySource: String, Codable, Sendable {
    case manual
    case calendarSuggestion
}

public struct SharedTripRoom: Equatable, Codable, Sendable {
    public static let defaultMemberLimit = 8
    public static let hardMemberLimit = 12
    public static let maximumCandidateDays = 90
    public static let maximumDurationDays = 30
    public static let schemaVersion = 1

    public let id: String
    public var ownerUID: String
    public var memberUIDs: [String]
    public var title: String
    public var destination: String
    public var countryCode: String?
    public var timezoneID: String
    public var candidateStartDay: String
    public var candidateEndDay: String
    public var durationDays: Int
    public var stage: TripRoomStage
    public var confirmedStartDay: String?
    public var confirmedEndDay: String?
    public var updatedAt: Date
    public var revision: Int

    public var memberCount: Int { memberUIDs.count }

    public init(
        id: String,
        ownerUID: String,
        memberUIDs: [String],
        title: String,
        destination: String,
        countryCode: String?,
        timezoneID: String,
        candidateStartDay: String,
        candidateEndDay: String,
        durationDays: Int,
        stage: TripRoomStage = .coordinating,
        confirmedStartDay: String? = nil,
        confirmedEndDay: String? = nil,
        updatedAt: Date = Date(),
        revision: Int = 0
    ) {
        self.id = id
        self.ownerUID = ownerUID
        self.memberUIDs = memberUIDs
        self.title = title
        self.destination = destination
        self.countryCode = countryCode
        self.timezoneID = timezoneID
        self.candidateStartDay = candidateStartDay
        self.candidateEndDay = candidateEndDay
        self.durationDays = durationDays
        self.stage = stage
        self.confirmedStartDay = confirmedStartDay
        self.confirmedEndDay = confirmedEndDay
        self.updatedAt = updatedAt
        self.revision = revision
    }
}

public struct SharedTripMember: Equatable, Codable, Sendable {
    public let userID: String
    public var displayName: String?
    public var role: SharedTripMemberRole
    public var isRequired: Bool
    public var joinedAt: Date

    public init(
        userID: String,
        displayName: String?,
        role: SharedTripMemberRole,
        isRequired: Bool = false,
        joinedAt: Date = Date()
    ) {
        self.userID = userID
        self.displayName = displayName
        self.role = role
        self.isRequired = isRequired
        self.joinedAt = joinedAt
    }
}

public struct AvailabilityDay: Equatable, Codable, Sendable {
    public let day: String
    public var status: AvailabilityStatus
    public var slots: [AvailabilityTimeSlot: AvailabilityStatus]
    public var source: AvailabilitySource

    public init(
        day: String,
        status: AvailabilityStatus,
        slots: [AvailabilityTimeSlot: AvailabilityStatus] = [:],
        source: AvailabilitySource = .manual
    ) {
        self.day = day
        self.status = status
        self.slots = slots
        self.source = source
    }
}

public struct AvailabilitySubmission: Equatable, Codable, Sendable {
    public static let schemaVersion = 1

    public let ownerUID: String
    public var days: [AvailabilityDay]
    public var leaveUnits: Double
    public var lateJoin: Bool
    public var earlyLeave: Bool
    public var note: String?
    public var updatedAt: Date
    public var revision: Int

    public init(
        ownerUID: String,
        days: [AvailabilityDay],
        leaveUnits: Double = 0,
        lateJoin: Bool = false,
        earlyLeave: Bool = false,
        note: String? = nil,
        updatedAt: Date = Date(),
        revision: Int = 0
    ) {
        self.ownerUID = ownerUID
        self.days = days
        self.leaveUnits = leaveUnits
        self.lateJoin = lateJoin
        self.earlyLeave = earlyLeave
        self.note = note
        self.updatedAt = updatedAt
        self.revision = revision
    }

    public func day(_ value: String) -> AvailabilityDay? {
        days.first(where: { $0.day == value })
    }
}

public struct ScheduleScoreBreakdown: Equatable, Codable, Sendable {
    public let participation: Double
    public let certainty: Double
    public let leaveEfficiency: Double
    public let arrivalFlexibility: Double
    public let requiredMemberCoverage: Double
    public let fairness: Double

    public var total: Double {
        participation + certainty + leaveEfficiency + arrivalFlexibility + requiredMemberCoverage + fairness
    }
}

public struct ScheduleCandidate: Equatable, Codable, Sendable {
    public let startDay: String
    public let endDay: String
    public let score: ScheduleScoreBreakdown
    public let availableMemberUIDs: [String]
    public let maybeMemberUIDs: [String]
    public let unavailableMemberUIDs: [String]
    public let undecidedMemberUIDs: [String]
    public let requiredLeaveUnits: Double
    public let lateJoinCount: Int
    public let earlyLeaveCount: Int
    public let reasons: [String]
    public let minimumChanges: [String]
}

public struct SharedPackingItem: Equatable, Codable, Sendable {
    public static let schemaVersion = 1

    public let id: String
    public let roomID: String
    public var title: String
    public var category: String
    public var quantity: Int
    public var assigneeUID: String?
    public var isPacked: Bool
    public let createdByUID: String
    public var updatedAt: Date
    public var revision: Int

    public init(
        id: String,
        roomID: String,
        title: String,
        category: String,
        quantity: Int,
        assigneeUID: String? = nil,
        isPacked: Bool = false,
        createdByUID: String,
        updatedAt: Date = Date(),
        revision: Int = 0
    ) {
        self.id = id
        self.roomID = roomID
        self.title = title
        self.category = category
        self.quantity = quantity
        self.assigneeUID = assigneeUID
        self.isPacked = isPacked
        self.createdByUID = createdByUID
        self.updatedAt = updatedAt
        self.revision = revision
    }
}

public struct SharedLookPlan: Equatable, Codable, Sendable {
    public static let schemaVersion = 1

    public let id: String
    public let roomID: String
    public let ownerUID: String
    public var day: String
    public var outfitName: String
    public var categories: [String]
    public var paletteHex: [String]
    public var styleTags: [String]
    public var formality: Int
    public var rainReady: Bool
    public var note: String?
    public var updatedAt: Date
    public var revision: Int

    public init(
        id: String,
        roomID: String,
        ownerUID: String,
        day: String,
        outfitName: String,
        categories: [String],
        paletteHex: [String],
        styleTags: [String],
        formality: Int,
        rainReady: Bool,
        note: String? = nil,
        updatedAt: Date = Date(),
        revision: Int = 0
    ) {
        self.id = id
        self.roomID = roomID
        self.ownerUID = ownerUID
        self.day = day
        self.outfitName = outfitName
        self.categories = categories
        self.paletteHex = paletteHex
        self.styleTags = styleTags
        self.formality = formality
        self.rainReady = rainReady
        self.note = note
        self.updatedAt = updatedAt
        self.revision = revision
    }
}

public struct TripInvite: Equatable, Codable, Sendable {
    public static let schemaVersion = 1

    public let tokenHash: String
    public let roomID: String
    public let createdByUID: String
    public let expiresAt: Date
    public var revoked: Bool
    public let createdAt: Date

    public init(
        tokenHash: String,
        roomID: String,
        createdByUID: String,
        expiresAt: Date,
        revoked: Bool = false,
        createdAt: Date = Date()
    ) {
        self.tokenHash = tokenHash
        self.roomID = roomID
        self.createdByUID = createdByUID
        self.expiresAt = expiresAt
        self.revoked = revoked
        self.createdAt = createdAt
    }
}

public enum CollaborationValidationError: Error, Equatable, Sendable {
    case invalidTitle
    case invalidDestination
    case invalidTimezone
    case invalidDay
    case invalidCandidateRange
    case invalidDuration
    case memberLimitExceeded
    case invalidAvailability
    case invalidNote
}

public enum CollaborationValidator {
    public static func validate(room: SharedTripRoom) throws {
        guard (1...80).contains(room.title.count) else { throw CollaborationValidationError.invalidTitle }
        guard room.destination.count <= 120 else { throw CollaborationValidationError.invalidDestination }
        guard TimeZone(identifier: room.timezoneID) != nil else { throw CollaborationValidationError.invalidTimezone }
        guard (1...SharedTripRoom.maximumDurationDays).contains(room.durationDays) else {
            throw CollaborationValidationError.invalidDuration
        }
        guard (1...SharedTripRoom.hardMemberLimit).contains(room.memberCount) else {
            throw CollaborationValidationError.memberLimitExceeded
        }
        guard room.memberUIDs.first == room.ownerUID, Set(room.memberUIDs).count == room.memberUIDs.count else {
            throw CollaborationValidationError.memberLimitExceeded
        }
        let days = try CalendarDayCodec.days(
            from: room.candidateStartDay,
            through: room.candidateEndDay,
            timezoneID: room.timezoneID
        )
        guard days.count <= SharedTripRoom.maximumCandidateDays, days.count >= room.durationDays else {
            throw CollaborationValidationError.invalidCandidateRange
        }
    }

    public static func validate(submission: AvailabilitySubmission, in room: SharedTripRoom) throws {
        guard submission.days.count <= SharedTripRoom.maximumCandidateDays,
              submission.leaveUnits >= 0,
              submission.leaveUnits <= Double(room.durationDays),
              (submission.leaveUnits * 2).rounded() == submission.leaveUnits * 2 else {
            throw CollaborationValidationError.invalidAvailability
        }
        guard (submission.note?.count ?? 0) <= 160 else { throw CollaborationValidationError.invalidNote }
        let validDays = Set(try CalendarDayCodec.days(
            from: room.candidateStartDay,
            through: room.candidateEndDay,
            timezoneID: room.timezoneID
        ))
        guard Set(submission.days.map(\.day)).count == submission.days.count,
              submission.days.allSatisfy({ validDays.contains($0.day) }) else {
            throw CollaborationValidationError.invalidAvailability
        }
    }
}

import Foundation

public enum CalendarDayCodec {
    public static func date(from day: String, timezoneID: String) throws -> Date {
        guard let timeZone = TimeZone(identifier: timezoneID) else {
            throw CollaborationValidationError.invalidTimezone
        }
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { throw CollaborationValidationError.invalidDay }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
              string(from: date, timezoneID: timezoneID) == day else {
            throw CollaborationValidationError.invalidDay
        }
        return date
    }

    public static func string(from date: Date, timezoneID: String) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezoneID) ?? .gmt
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    public static func days(from start: String, through end: String, timezoneID: String) throws -> [String] {
        let startDate = try date(from: start, timezoneID: timezoneID)
        let endDate = try date(from: end, timezoneID: timezoneID)
        guard startDate <= endDate, let timeZone = TimeZone(identifier: timezoneID) else {
            throw CollaborationValidationError.invalidCandidateRange
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var result: [String] = []
        var cursor = startDate
        while cursor <= endDate, result.count <= SharedTripRoom.maximumCandidateDays {
            result.append(string(from: cursor, timezoneID: timezoneID))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }
}

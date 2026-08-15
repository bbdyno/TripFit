import Domain
import EventKit
import Foundation

enum CalendarAvailabilitySuggestionError: Error {
    case accessDenied
    case invalidDateRange
}

struct CalendarAvailabilitySuggestionService {
    private let store = EKEventStore()

    func suggestions(for room: SharedTripRoom) async throws -> [AvailabilityDay] {
        let granted: Bool
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            granted = true
        case .notDetermined:
            granted = try await store.requestFullAccessToEvents()
        default:
            granted = false
        }
        guard granted else { throw CalendarAvailabilitySuggestionError.accessDenied }

        let dayStrings = try CalendarDayCodec.days(
            from: room.candidateStartDay,
            through: room.candidateEndDay,
            timezoneID: room.timezoneID
        )
        guard let timeZone = TimeZone(identifier: room.timezoneID),
              let first = dayStrings.first,
              let last = dayStrings.last else {
            throw CalendarAvailabilitySuggestionError.invalidDateRange
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = try CalendarDayCodec.date(from: first, timezoneID: room.timezoneID)
        let lastStart = try CalendarDayCodec.date(from: last, timezoneID: room.timezoneID)
        guard let end = calendar.date(byAdding: .day, value: 1, to: lastStart) else {
            throw CalendarAvailabilitySuggestionError.invalidDateRange
        }

        let events = store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: nil))
        return dayStrings.map { day in
            guard let dayStart = try? CalendarDayCodec.date(from: day, timezoneID: room.timezoneID),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                return AvailabilityDay(day: day, status: .undecided, source: .calendarSuggestion)
            }
            let isBusy = events.contains { event in event.endDate > dayStart && event.startDate < dayEnd }
            return AvailabilityDay(
                day: day,
                status: isBusy ? .unavailable : .undecided,
                source: .calendarSuggestion
            )
        }
    }
}

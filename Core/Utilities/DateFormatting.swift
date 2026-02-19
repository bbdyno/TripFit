import Foundation

public enum TFDateFormatter {
    private static let mediumFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    public static func medium(_ date: Date) -> String {
        mediumFormatter.string(from: date)
    }

    public static func short(_ date: Date) -> String {
        shortFormatter.string(from: date)
    }

    public static func tripRange(start: Date, end: Date) -> String {
        "\(short(start)) - \(short(end))"
    }
}

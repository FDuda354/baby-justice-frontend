import Foundation

enum Formatters {
    private static let polishLocale = Locale(identifier: "pl_PL")

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = polishLocale
        formatter.unitsStyle = .full
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = polishLocale
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = polishLocale
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    private static let isoDayParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func formatted(date: Date) -> String {
        if abs(date.timeIntervalSinceNow) < 48 * 3600 {
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        return dateTimeFormatter.string(from: date)
    }

    static func formattedDay(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func formattedDay(_ isoDay: String) -> String {
        guard let date = isoDayParser.date(from: isoDay) else { return isoDay }
        return formattedDay(date)
    }

    static func isoDay(from date: Date) -> String {
        isoDayParser.string(from: date)
    }

    static func signedPoints(_ points: Int) -> String {
        points > 0 ? "+\(points)" : "\(points)"
    }
}

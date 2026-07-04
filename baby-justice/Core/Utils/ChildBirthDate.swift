import Foundation

enum ChildBirthDate {
    private static let isoDayParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func date(from isoDay: String) -> Date? {
        isoDayParser.date(from: isoDay)
    }

    static func ageText(forIso isoDay: String) -> String? {
        guard let birth = date(from: isoDay),
              let years = Calendar.current.dateComponents([.year], from: birth, to: Date()).year,
              years >= 0
        else { return nil }
        return "\(years) \(yearsWord(years))"
    }

    private static func yearsWord(_ years: Int) -> String {
        if years == 1 { return "rok" }
        let lastDigit = years % 10
        let lastTwoDigits = years % 100
        if (2...4).contains(lastDigit) && !(12...14).contains(lastTwoDigits) {
            return "lata"
        }
        return "lat"
    }
}

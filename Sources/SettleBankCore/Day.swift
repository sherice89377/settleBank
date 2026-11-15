import Foundation

/// A calendar day in YYYY-MM-DD notation. Sherice's Coffee Roasters closes its books in New York,
/// and Bravo Bank dates its postings there, so a day starts at midnight New York time.
public struct Day: Hashable, Comparable, CustomStringConvertible {
    /// Days since 1970-01-01.
    public let ordinal: Int
    public let text: String
    /// Midnight at the start of the day, New York time.
    let start: Date

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    public init(_ text: String) throws {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              (1...12).contains(month), day >= 1, day <= Day.daysIn(month: month, year: year),
              let start = Day.calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            throw SettleError.invalidDate(text)
        }
        self.start = start
        self.ordinal = Int(start.timeIntervalSince1970 / 86_400)
        self.text = text
    }

    public var description: String { text }

    /// Whole days from `rhs` to `lhs`.
    public static func - (lhs: Day, rhs: Day) -> Int {
        Int(lhs.start.timeIntervalSince(rhs.start) / 86_400)
    }

    public static func < (lhs: Day, rhs: Day) -> Bool { lhs.start < rhs.start }

    static func isLeap(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    static func daysIn(month: Int, year: Int) -> Int {
        switch month {
        case 2: return isLeap(year) ? 29 : 28
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }
}

/// A calendar day in YYYY-MM-DD notation. Day arithmetic is done on a day count, so the
/// result never depends on the machine's time zone or calendar settings.
public struct Day: Hashable, Comparable, CustomStringConvertible {
    /// Days since 1970-01-01.
    public let ordinal: Int
    public let text: String

    public init(_ text: String) throws {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              (1...12).contains(month), day >= 1, day <= Day.daysIn(month: month, year: year) else {
            throw SettleError.invalidDate(text)
        }
        self.ordinal = Day.daysFromCivil(year, month, day)
        self.text = text
    }

    public var description: String { text }

    /// Whole days from `rhs` to `lhs`.
    public static func - (lhs: Day, rhs: Day) -> Int { lhs.ordinal - rhs.ordinal }

    public static func < (lhs: Day, rhs: Day) -> Bool { lhs.ordinal < rhs.ordinal }

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

    /// Proleptic Gregorian day count (H. Hinnant's days_from_civil).
    static func daysFromCivil(_ year: Int, _ month: Int, _ day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yearOfEra = y - era * 400
        let shiftedMonth = (month + 9) % 12
        let dayOfYear = (153 * shiftedMonth + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146097 + dayOfEra - 719468
    }
}

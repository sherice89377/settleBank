import Foundation

/// Amounts are carried as integer cents end to end, so no total ever depends on
/// floating-point rounding.
public enum Money {
    /// Parses "1234.56", "-12.50" or "+12.00" into cents. Exactly 2 fraction digits are required.
    public static func cents(_ raw: String) throws -> Int {
        let text = raw.trimmingCharacters(in: .whitespaces)
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2, parts[1].count == 2,
              isWholeNumber(parts[0]),
              parts[1].allSatisfy({ $0.isASCII && $0.isNumber }),
              let whole = Int(parts[0]), let fraction = Int(parts[1]) else {
            throw SettleError.invalidAmount(raw)
        }
        // The cents take the sign of the whole part.
        return whole * 100 + (whole < 0 ? -fraction : fraction)
    }

    /// Digits with an optional leading sign, as in "-12" or "+7".
    static func isWholeNumber(_ text: Substring) -> Bool {
        let digits = text.first == "-" || text.first == "+" ? text.dropFirst() : text
        return !digits.isEmpty && digits.allSatisfy { $0.isASCII && $0.isNumber }
    }

    /// Formats cents back into the statement notation, for messages and logs.
    public static func format(_ cents: Int) -> String {
        let sign = cents < 0 ? "-" : ""
        let magnitude = abs(cents)
        let fraction = magnitude % 100
        return "\(sign)\(magnitude / 100).\(fraction < 10 ? "0" : "")\(fraction)"
    }
}

import Foundation

/// Amounts are carried as integer cents end to end, so no total ever depends on
/// floating-point rounding.
public enum Money {
    /// Parses "1234.56", "-0.50" or "+12.00" into cents. Exactly 2 fraction digits are required.
    public static func cents(_ raw: String) throws -> Int {
        var text = Substring(raw.trimmingCharacters(in: .whitespaces))
        var negative = false
        if text.hasPrefix("-") {
            negative = true
            text = text.dropFirst()
        } else if text.hasPrefix("+") {
            text = text.dropFirst()
        }
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].count == 2,
              parts[0].allSatisfy({ $0.isASCII && $0.isNumber }),
              parts[1].allSatisfy({ $0.isASCII && $0.isNumber }),
              let whole = Int(parts[0]), let fraction = Int(parts[1]) else {
            throw SettleError.invalidAmount(raw)
        }
        let value = whole * 100 + fraction
        return negative ? -value : value
    }

    /// Formats cents back into the statement notation, for messages and logs.
    public static func format(_ cents: Int) -> String {
        let sign = cents < 0 ? "-" : ""
        let magnitude = abs(cents)
        let fraction = magnitude % 100
        return "\(sign)\(magnitude / 100).\(fraction < 10 ? "0" : "")\(fraction)"
    }
}

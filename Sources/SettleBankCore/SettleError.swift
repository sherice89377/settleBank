/// Every failure `settleBank` reports. Input problems name the file and the line.
public enum SettleError: Error, Equatable, CustomStringConvertible {
    case unreadable(path: String)
    case invalidAmount(String)
    case invalidDate(String)
    case malformedCSV(line: Int, reason: String)
    case missingColumn(file: String, column: String)
    case invalidRow(file: String, line: Int, reason: String)

    public var description: String {
        switch self {
        case .unreadable(let path):
            return "cannot read \(path)"
        case .invalidAmount(let text):
            return "invalid amount '\(text)' (expected a decimal with exactly two fraction digits)"
        case .invalidDate(let text):
            return "invalid date '\(text)' (expected YYYY-MM-DD)"
        case .malformedCSV(let line, let reason):
            return "malformed CSV at line \(line): \(reason)"
        case .missingColumn(let file, let column):
            return "\(file): missing column '\(column)'"
        case .invalidRow(let file, let line, let reason):
            return "\(file):\(line): \(reason)"
        }
    }
}

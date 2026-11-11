import Foundation

/// 1 data row, keyed by the header's column names.
public struct CSVRecord {
    /// The physical line the record starts on (the header is line 1).
    public let line: Int
    public let fields: [String: String]

    public subscript(_ column: String) -> String { fields[column] ?? "" }
}

public struct CSVTable {
    public let header: [String]
    public let records: [CSVRecord]

    func require(_ columns: [String], file: String) throws {
        for column in columns where !header.contains(column) {
            throw SettleError.missingColumn(file: file, column: column)
        }
    }
}

/// A small RFC 4180 reader: comma separated, double-quoted fields may hold commas,
/// newlines and doubled quotes. CRLF and LF line endings are both accepted.
public enum CSV {
    public static func load(path: String) throws -> CSVTable {
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
            throw SettleError.unreadable(path: path)
        }
        return try parse(text)
    }

    public static func parse(_ text: String) throws -> CSVTable {
        var rows: [(line: Int, values: [String])] = []
        var field = ""
        var row: [String] = []
        var inQuotes = false
        var line = 1
        var rowStart = 1
        let scalars = Array(text.unicodeScalars)
        var index = 0
        while index < scalars.count {
            let c = scalars[index]
            if inQuotes {
                if c == "\"" {
                    if index + 1 < scalars.count && scalars[index + 1] == "\"" {
                        field.unicodeScalars.append("\"")
                        index += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    if c == "\n" { line += 1 }
                    field.unicodeScalars.append(c)
                }
            } else if c == "\"" {
                guard field.isEmpty else {
                    throw SettleError.malformedCSV(line: line, reason: "quote inside an unquoted field")
                }
                inQuotes = true
            } else if c == "," {
                row.append(field)
                field = ""
            } else if c == "\n" {
                row.append(field)
                field = ""
                rows.append((rowStart, row))
                row = []
                line += 1
                rowStart = line
            } else if c != "\r" {
                field.unicodeScalars.append(c)
            }
            index += 1
        }
        if inQuotes {
            throw SettleError.malformedCSV(line: rowStart, reason: "unterminated quoted field")
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append((rowStart, row))
        }
        rows.removeAll { $0.values.count == 1 && $0.values[0].isEmpty }
        guard let first = rows.first else {
            throw SettleError.malformedCSV(line: 1, reason: "no header row")
        }
        let header = first.values.map { $0.trimmingCharacters(in: .whitespaces) }
        var records: [CSVRecord] = []
        for (start, values) in rows.dropFirst() {
            guard values.count == header.count else {
                throw SettleError.malformedCSV(
                    line: start, reason: "expected \(header.count) fields, found \(values.count)")
            }
            var fields: [String: String] = [:]
            for (column, value) in zip(header, values) {
                fields[column] = value
            }
            records.append(CSVRecord(line: start, fields: fields))
        }
        return CSVTable(header: header, records: records)
    }
}

/// Turns the three CSV exports into typed lines. Every row error names its file and line.
public enum Loaders {
    static let bankColumns = ["posted_date", "bank_ref", "description", "amount"]
    static let processorColumns = ["payout_id", "payout_date", "line_type", "reference", "amount", "status"]
    static let ledgerColumns = ["entry_id", "date", "kind", "reference", "amount", "status"]

    public static func bank(_ table: CSVTable, file: String = "bank.csv") throws -> [BankLine] {
        try table.require(bankColumns, file: file)
        var lines: [BankLine] = []
        for record in table.records {
            do {
                lines.append(BankLine(
                    bankRef: record["bank_ref"],
                    posted: try Day(record["posted_date"]),
                    description: record["description"],
                    amountCents: try Money.cents(record["amount"])))
            } catch let error as SettleError {
                throw SettleError.invalidRow(file: file, line: record.line, reason: error.description)
            }
        }
        return lines
    }

    public static func processor(
        _ table: CSVTable, file: String = "processor.csv", warnings: inout [String]
    ) throws -> [ProcessorLine] {
        try table.require(processorColumns, file: file)
        var lines: [ProcessorLine] = []
        for record in table.records {
            guard let type = LineType(rawValue: record["line_type"]) else {
                warnings.append("\(file):\(record.line): skipping line with unknown line_type '\(record["line_type"])'")
                continue
            }
            do {
                lines.append(ProcessorLine(
                    payoutId: record["payout_id"],
                    payoutDate: try Day(record["payout_date"]),
                    type: type,
                    reference: record["reference"],
                    amountCents: try Money.cents(record["amount"]),
                    status: record["status"]))
            } catch let error as SettleError {
                throw SettleError.invalidRow(file: file, line: record.line, reason: error.description)
            }
        }
        return lines
    }

    public static func ledger(_ table: CSVTable, file: String = "ledger.csv") throws -> [LedgerEntry] {
        try table.require(ledgerColumns, file: file)
        var entries: [LedgerEntry] = []
        for record in table.records {
            guard let kind = LedgerEntry.Kind(rawValue: record["kind"]) else {
                throw SettleError.invalidRow(file: file, line: record.line, reason: "unknown kind '\(record["kind"])'")
            }
            do {
                entries.append(LedgerEntry(
                    entryId: record["entry_id"],
                    date: try Day(record["date"]),
                    kind: kind,
                    reference: record["reference"],
                    amountCents: try Money.cents(record["amount"]),
                    status: record["status"]))
            } catch let error as SettleError {
                throw SettleError.invalidRow(file: file, line: record.line, reason: error.description)
            }
        }
        return entries
    }
}

import Foundation

/// What 1 month-end close hands to the next: the exports received so far, as the CSV text that
/// arrived. Each close reads them back, adds its own and reconciles the whole history again.
public struct CloseState: Codable, Equatable {
    /// The 3 exports of 1 close, as received.
    public struct Received: Codable, Equatable {
        public let bank: String
        public let processor: String
        public let ledger: String

        public init(bank: String, processor: String, ledger: String) {
            self.bank = bank
            self.processor = processor
            self.ledger = ledger
        }
    }

    public var closes: [Received]

    public init(closes: [Received] = []) {
        self.closes = closes
    }

    /// The state at `path`, or an empty state when this is the first close.
    public static func load(path: String) throws -> CloseState {
        guard FileManager.default.fileExists(atPath: path) else { return CloseState() }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(CloseState.self, from: data)
    }

    public func save(path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(self).write(to: URL(fileURLWithPath: path), options: .atomic)
    }

    /// Every close's exports, typed. A later bank export often restates rows the bank already sent;
    /// the restated row replaces the earlier one, so each bank_ref appears once, as last sent.
    public func history(warnings: inout [String]) throws -> (bank: [BankLine], processor: [ProcessorLine], ledger: [LedgerEntry]) {
        var bank: [BankLine] = []
        var position: [String: Int] = [:]
        var processor: [ProcessorLine] = []
        var ledger: [LedgerEntry] = []
        for (index, close) in closes.enumerated() {
            let label = "close \(index + 1)"
            var seenHere = Set<String>()
            for line in try Loaders.bank(CSV.parse(close.bank), file: "\(label) bank.csv") {
                if !seenHere.contains(line.bankRef), let earlier = position[line.bankRef] {
                    bank[earlier] = line
                } else {
                    position[line.bankRef] = bank.count
                    bank.append(line)
                }
                seenHere.insert(line.bankRef)
            }
            processor += try Loaders.processor(
                CSV.parse(close.processor), file: "\(label) processor.csv", warnings: &warnings)
            ledger += try Loaders.ledger(CSV.parse(close.ledger), file: "\(label) ledger.csv")
        }
        return (bank, processor, ledger)
    }
}

public struct Reconciliation: Equatable {
    public let payouts: [PayoutResult]
    public let refunds: [RefundResult]
    public let unmatchedBank: [String]
    public let ledgerExceptions: [LedgerException]
}

/// The month-end close: payouts against the bank, then refunds, then the ledger.
public enum Reconciler {
    public static func run(bank: [BankLine], processor: [ProcessorLine], ledger: [LedgerEntry]) -> Reconciliation {
        let matching = PayoutMatcher.match(bank: bank, processor: processor)
        let refunds = RefundStatus.resolve(processor: processor, ledger: ledger, payouts: matching.payouts)
        let exceptions = LedgerCheck.exceptions(ledger: ledger, processor: processor, refunds: refunds)
        return Reconciliation(
            payouts: matching.payouts, refunds: refunds,
            unmatchedBank: matching.unmatchedBank, ledgerExceptions: exceptions)
    }

    /// The same close from CSV text, with the processor loader's warnings.
    public static func run(
        bankCSV: String, processorCSV: String, ledgerCSV: String
    ) throws -> (Reconciliation, [String]) {
        var warnings: [String] = []
        let bank = try Loaders.bank(CSV.parse(bankCSV))
        let processor = try Loaders.processor(CSV.parse(processorCSV), warnings: &warnings)
        let ledger = try Loaders.ledger(CSV.parse(ledgerCSV))
        return (run(bank: bank, processor: processor, ledger: ledger), warnings)
    }
}

/// 1 row of the bank statement export. Credits are positive, debits negative.
public struct BankLine: Equatable {
    public let bankRef: String
    public let posted: Day
    public let description: String
    public let amountCents: Int
}

/// The kinds of line the processor puts in a payout batch.
public enum LineType: String {
    case charge
    case refund
    case fee
}

/// 1 line of the processor's payout export. A payout's net is the sum of its lines.
public struct ProcessorLine: Equatable {
    public let payoutId: String
    public let payoutDate: Day
    public let type: LineType
    public let reference: String
    public let amountCents: Int
    /// The processor's own status for the line at export time.
    public let status: String
}

/// 1 row of the internal ledger. Amounts are positive for sales and for refunds.
public struct LedgerEntry: Equatable {
    public enum Kind: String {
        case sale
        case refund
    }

    public let entryId: String
    public let date: Day
    public let kind: Kind
    /// The processor reference: a charge id for a sale, a refund id for a refund.
    public let reference: String
    public let amountCents: Int
    public let status: String
}

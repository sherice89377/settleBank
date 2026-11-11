import Foundation

/// Writes the close report as JSON (keys sorted, 2-space indentation, a final newline).
public enum ReportWriter {
    struct Document: Encodable {
        let payouts: [Payout]
        let refunds: [Refund]
        let unmatched_bank: [String]
        let ledger_exceptions: [Exception]
    }

    struct Payout: Encodable {
        let payout_id: String
        let net_cents: Int
        let deposited_cents: Int
        let bank_refs: [String]
        let status: String
    }

    struct Refund: Encodable {
        let refund_id: String
        let payout_id: String
        let amount_cents: Int
        let status: String
    }

    struct Exception: Encodable {
        let entry_id: String
        let reason: String
    }

    public static func json(_ result: Reconciliation) throws -> Data {
        let document = Document(
            payouts: result.payouts.map {
                Payout(payout_id: $0.payoutId, net_cents: $0.netCents, deposited_cents: $0.depositedCents,
                       bank_refs: $0.bankRefs, status: $0.status.rawValue)
            },
            refunds: result.refunds.map {
                Refund(refund_id: $0.refundId, payout_id: $0.payoutId, amount_cents: $0.amountCents,
                       status: $0.status.rawValue)
            },
            unmatched_bank: result.unmatchedBank,
            ledger_exceptions: result.ledgerExceptions.map {
                Exception(entry_id: $0.entryId, reason: $0.reason.rawValue)
            })
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var data = try encoder.encode(document)
        data.append(0x0A)
        return data
    }
}

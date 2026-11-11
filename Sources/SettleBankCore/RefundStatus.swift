public enum RefundState: String {
    case settled
    case failed
    case unsettled
}

public struct RefundResult: Equatable {
    public let refundId: String
    /// The payout whose batch carried the refund line.
    public let payoutId: String
    /// The refunded amount, as a positive number of cents.
    public let amountCents: Int
    public let status: RefundState
}

/// Decides, for every refund the processor exported, whether the money really left.
public enum RefundStatus {
    public static func resolve(
        processor: [ProcessorLine], ledger: [LedgerEntry], payouts: [PayoutResult]
    ) -> [RefundResult] {
        var bookedStatus: [String: String] = [:]
        for entry in ledger where entry.kind == .refund {
            bookedStatus[entry.reference] = entry.status
        }
        return processor
            .filter { $0.type == .refund }
            .map { line in
                // The processor and our books agree that the refund went out.
                let agreed = line.status == "succeeded" && bookedStatus[line.reference] == "settled"
                return RefundResult(
                    refundId: line.reference, payoutId: line.payoutId,
                    amountCents: abs(line.amountCents), status: agreed ? .settled : .unsettled)
            }
            .sorted { $0.refundId < $1.refundId }
    }
}

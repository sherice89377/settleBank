public enum ExceptionReason: String {
    case missingInProcessor = "missing_in_processor"
    case amountMismatch = "amount_mismatch"
    case statusMismatch = "status_mismatch"
}

public struct LedgerException: Equatable {
    public let entryId: String
    public let reason: ExceptionReason
}

/// Flags ledger entries the processor export and the reconciled refund statuses do not support.
public enum LedgerCheck {
    public static func exceptions(
        ledger: [LedgerEntry], processor: [ProcessorLine], refunds: [RefundResult]
    ) -> [LedgerException] {
        var charges: [String: ProcessorLine] = [:]
        var refundLines: [String: ProcessorLine] = [:]
        for line in processor {
            switch line.type {
            case .charge: charges[line.reference] = line
            case .refund: refundLines[line.reference] = line
            default: break
            }
        }
        var refundState: [String: RefundState] = [:]
        for refund in refunds {
            refundState[refund.refundId] = refund.status
        }
        var found: [LedgerException] = []
        for entry in ledger {
            let line = entry.kind == .sale ? charges[entry.reference] : refundLines[entry.reference]
            guard let line else {
                found.append(LedgerException(entryId: entry.entryId, reason: .missingInProcessor))
                continue
            }
            if abs(line.amountCents) != entry.amountCents {
                found.append(LedgerException(entryId: entry.entryId, reason: .amountMismatch))
                continue
            }
            if entry.kind == .refund, let state = refundState[entry.reference], state.rawValue != entry.status {
                found.append(LedgerException(entryId: entry.entryId, reason: .statusMismatch))
            }
        }
        return found.sorted { $0.entryId < $1.entryId }
    }
}

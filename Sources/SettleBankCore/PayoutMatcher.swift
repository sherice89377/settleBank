public enum PayoutStatus: String {
    case matched
    case partial
    case missing
}

public struct PayoutResult: Equatable {
    public let payoutId: String
    /// The sum of every line of the payout in the processor export.
    public let netCents: Int
    /// The sum of the bank credits attributed to the payout.
    public let depositedCents: Int
    public let bankRefs: [String]
    public let status: PayoutStatus
}

public struct PayoutMatching: Equatable {
    public let payouts: [PayoutResult]
    /// Processor credits on the statement that belong to no payout of the export.
    public let unmatchedBank: [String]
}

/// Ties processor payouts to the bank credits that carried them.
public enum PayoutMatcher {
    /// Statement descriptions of processor credits start with this word.
    public static let processorPrefix = "TANGOPAY"
    /// How many days after the payout date the bank may post a credit that lost its payout id.
    public static let postingWindowDays = 0...3

    /// The payout id ("PO-" and digits) a statement description names, if any.
    public static func payoutId(in description: String) -> String? {
        let tokens = description.uppercased().split { !($0.isLetter || $0.isNumber || $0 == "-") }
        for token in tokens where token.hasPrefix("PO-") && token.count > 3
            && token.dropFirst(3).allSatisfy({ $0.isASCII && $0.isNumber }) {
            return String(token)
        }
        return nil
    }

    public static func match(bank: [BankLine], processor: [ProcessorLine]) -> PayoutMatching {
        var net: [String: Int] = [:]
        var payoutDate: [String: Day] = [:]
        for line in processor {
            net[line.payoutId, default: 0] += line.amountCents
            payoutDate[line.payoutId] = line.payoutDate
        }
        let credits = bank.filter {
            $0.description.uppercased().hasPrefix(processorPrefix) && $0.amountCents > 0
        }

        // The bank feed sometimes delivers the same credit 2 times: keep 1 credit per payout.
        var byPayout: [String: BankLine] = [:]
        var withoutId: [BankLine] = []
        var unmatched: [String] = []
        for credit in credits {
            guard let id = payoutId(in: credit.description) else {
                withoutId.append(credit)
                continue
            }
            guard net[id] != nil else {
                unmatched.append(credit.bankRef)
                continue
            }
            if byPayout[id] == nil {
                byPayout[id] = credit
            }
        }
        var deposits: [String: [BankLine]] = byPayout.mapValues { [$0] }

        // Credits whose description lost the payout id: match on amount and posting window.
        let ids = net.keys.sorted()
        for credit in withoutId {
            let candidate = ids.first { id in
                net[id] == credit.amountCents && postingWindowDays.contains(credit.posted - payoutDate[id]!)
            }
            if let id = candidate {
                deposits[id, default: []].append(credit)
            } else {
                unmatched.append(credit.bankRef)
            }
        }

        let payouts = ids.map { id -> PayoutResult in
            let lines = deposits[id] ?? []
            let deposited = lines.reduce(0) { $0 + $1.amountCents }
            let status: PayoutStatus = lines.isEmpty ? .missing : (deposited == net[id]! ? .matched : .partial)
            return PayoutResult(
                payoutId: id, netCents: net[id]!, depositedCents: deposited,
                bankRefs: lines.map(\.bankRef).sorted(), status: status)
        }
        return PayoutMatching(payouts: payouts, unmatchedBank: unmatched.sorted())
    }
}

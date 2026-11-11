import XCTest
@testable import SettleBankCore

final class ReconcilerTests: XCTestCase {
    let bank = """
        posted_date,bank_ref,description,amount
        2026-09-03,B-100,TANGOPAY PAYOUT PO-100,95.10
        2026-09-04,B-101,"OFFICE SUPPLY CO, INV 77",-42.00
        """
    let processor = """
        payout_id,payout_date,line_type,reference,amount,status
        PO-100,2026-09-02,charge,ch_1,60.00,succeeded
        PO-100,2026-09-02,charge,ch_2,38.00,succeeded
        PO-100,2026-09-02,fee,fee_100,-2.90,posted
        PO-101,2026-09-30,charge,ch_3,20.00,succeeded
        PO-101,2026-09-30,fee,fee_101,-0.88,posted
        """
    let ledger = """
        entry_id,date,kind,reference,amount,status
        L-1,2026-09-01,sale,ch_1,60.00,booked
        L-2,2026-09-01,sale,ch_2,38.00,booked
        L-3,2026-09-29,sale,ch_3,20.00,booked
        L-4,2026-09-29,sale,ch_9,15.00,booked
        """

    func testSinglePayoutMatches() throws {
        let (result, warnings) = try Reconciler.run(bankCSV: bank, processorCSV: processor, ledgerCSV: ledger)
        XCTAssertEqual(warnings, [])
        XCTAssertEqual(result.payouts[0], PayoutResult(
            payoutId: "PO-100", netCents: 9510, depositedCents: 9510, bankRefs: ["B-100"], status: .matched))
    }

    func testPayoutNotYetDepositedIsMissing() throws {
        let (result, _) = try Reconciler.run(bankCSV: bank, processorCSV: processor, ledgerCSV: ledger)
        XCTAssertEqual(result.payouts[1], PayoutResult(
            payoutId: "PO-101", netCents: 1912, depositedCents: 0, bankRefs: [], status: .missing))
        XCTAssertEqual(result.unmatchedBank, [])
    }

    func testLedgerEntryWithoutProcessorLine() throws {
        let (result, _) = try Reconciler.run(bankCSV: bank, processorCSV: processor, ledgerCSV: ledger)
        XCTAssertEqual(result.ledgerExceptions, [LedgerException(entryId: "L-4", reason: .missingInProcessor)])
    }

    func testPayoutIdParsing() {
        XCTAssertEqual(PayoutMatcher.payoutId(in: "TANGOPAY PAYOUT PO-20481"), "PO-20481")
        XCTAssertEqual(PayoutMatcher.payoutId(in: "tangopay payout po-7/xfer"), "PO-7")
        XCTAssertNil(PayoutMatcher.payoutId(in: "TANGOPAY PAYOUT"))
        XCTAssertNil(PayoutMatcher.payoutId(in: "TANGOPAY PO-"))
    }
}

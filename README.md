# settleBank

`settleBank` is the month-end cash reconciliation tool of Sherice's Coffee Roasters. It reads
three exports and writes one JSON close report:

* `bank.csv`, the Bravo Bank operating account's statement export (`posted_date,bank_ref,description,amount`);
* `processor.csv`, TangoPay's payout export, one row per line of each payout batch
  (`payout_id,payout_date,line_type,reference,amount,status`);
* `ledger.csv`, our books (`entry_id,date,kind,reference,amount,status`).

```
swift build
swift run settleBank reconcile --bank samples/2026-10/bank.csv \
    --processor samples/2026-10/processor.csv --ledger samples/2026-10/ledger.csv \
    --out out/2026-10-close.json
swift test
```

Amounts are decimals with exactly two fraction digits and are carried as integer cents.
Dates are `YYYY-MM-DD`.

## Layout

| Path | What it does |
|---|---|
| `Sources/SettleBankCore/CSV.swift`, `Money.swift`, `Day.swift` | Parsing |
| `Sources/SettleBankCore/Loaders.swift` | The three exports as typed lines |
| `Sources/SettleBankCore/PayoutMatcher.swift` | Payouts against bank credits |
| `Sources/SettleBankCore/RefundStatus.swift` | Whether each refund settled |
| `Sources/SettleBankCore/LedgerCheck.swift` | Ledger entries the evidence does not support |
| `Sources/SettleBankCore/ReportWriter.swift` | The JSON report |
| `Sources/settleBank/main.swift` | The command line |

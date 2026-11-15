# settleBank

`settleBank` is the month-end cash reconciliation tool of Sherice's Coffee Roasters. It reads
3 exports and writes 1 JSON close report:

* `bank.csv`, the Bravo Bank operating account's statement export (`posted_date,bank_ref,description,amount`);
* `processor.csv`, TangoPay's payout export, 1 row per line of each payout batch
  (`payout_id,payout_date,line_type,reference,amount,status`);
* `ledger.csv`, our books (`entry_id,date,kind,reference,amount,status`).

```
swift build
swift run settleBank reconcile --bank samples/2026-10/bank.csv \
    --processor samples/2026-10/processor.csv --ledger samples/2026-10/ledger.csv \
    --out out/2026-10-close.json
swift test
```

Month after month, pass the same `--state` file to every close (it is created on the first run), so
each close sees what the earlier ones received:

```
swift run settleBank reconcile --bank 2026-11/bank.csv --processor 2026-11/processor.csv \
    --ledger 2026-11/ledger.csv --state out/close-state.json --out out/2026-11-close.json
```

Amounts are decimals with exactly 2 fraction digits and are carried as integer cents.
Dates are `YYYY-MM-DD`.

## Layout

| Path | What it does |
|---|---|
| `Sources/SettleBankCore/CSV.swift`, `Money.swift`, `Day.swift` | Parsing |
| `Sources/SettleBankCore/Loaders.swift` | The 3 exports as typed lines |
| `Sources/SettleBankCore/PayoutMatcher.swift` | Payouts against bank credits |
| `Sources/SettleBankCore/RefundStatus.swift` | Whether each refund settled |
| `Sources/SettleBankCore/LedgerCheck.swift` | Ledger entries the evidence does not support |
| `Sources/SettleBankCore/CloseState.swift` | What 1 close hands to the next |
| `Sources/SettleBankCore/ReportWriter.swift` | The JSON report |
| `Sources/settleBank/main.swift` | The command line |

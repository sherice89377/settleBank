import Foundation
import SettleBankCore

let usage = """
    usage: settleBank reconcile --bank <bank.csv> --processor <processor.csv> --ledger <ledger.csv> [--state <state.json>] --out <report.json>
    """

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("settleBank: \(message)\n".utf8))
    exit(1)
}

func warn(_ message: String) {
    FileHandle.standardError.write(Data("settleBank: warning: \(message)\n".utf8))
}

var arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.first == "reconcile" else { fail(usage) }
arguments.removeFirst()

var options: [String: String] = [:]
var position = 0
while position < arguments.count {
    let key = arguments[position]
    guard ["--bank", "--processor", "--ledger", "--state", "--out"].contains(key), position + 1 < arguments.count else {
        fail(usage)
    }
    options[key] = arguments[position + 1]
    position += 2
}
guard let bankPath = options["--bank"], let processorPath = options["--processor"],
      let ledgerPath = options["--ledger"], let outPath = options["--out"] else {
    fail(usage)
}

do {
    var warnings: [String] = []
    let result: Reconciliation
    if let statePath = options["--state"] {
        // A rolling close: this month's exports join everything the earlier closes received.
        var state = try CloseState.load(path: statePath)
        state.closes.append(CloseState.Received(
            bank: try String(contentsOfFile: bankPath, encoding: .utf8),
            processor: try String(contentsOfFile: processorPath, encoding: .utf8),
            ledger: try String(contentsOfFile: ledgerPath, encoding: .utf8)))
        let history = try state.history(warnings: &warnings)
        result = Reconciler.run(bank: history.bank, processor: history.processor, ledger: history.ledger)
        try state.save(path: statePath)
    } else {
        let bank = try Loaders.bank(CSV.load(path: bankPath))
        let processor = try Loaders.processor(CSV.load(path: processorPath), warnings: &warnings)
        let ledger = try Loaders.ledger(CSV.load(path: ledgerPath))
        result = Reconciler.run(bank: bank, processor: processor, ledger: ledger)
    }
    warnings.forEach(warn)
    try ReportWriter.json(result).write(to: URL(fileURLWithPath: outPath))
} catch {
    fail("\(error)")
}

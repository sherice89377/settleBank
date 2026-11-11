import Foundation
import SettleBankCore

let usage = """
    usage: settleBank reconcile --bank <bank.csv> --processor <processor.csv> --ledger <ledger.csv> --out <report.json>
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
    guard ["--bank", "--processor", "--ledger", "--out"].contains(key), position + 1 < arguments.count else {
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
    let bank = try Loaders.bank(CSV.load(path: bankPath))
    let processor = try Loaders.processor(CSV.load(path: processorPath), warnings: &warnings)
    let ledger = try Loaders.ledger(CSV.load(path: ledgerPath))
    warnings.forEach(warn)
    let result = Reconciler.run(bank: bank, processor: processor, ledger: ledger)
    try ReportWriter.json(result).write(to: URL(fileURLWithPath: outPath))
} catch {
    fail("\(error)")
}

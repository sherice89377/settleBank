import XCTest
@testable import SettleBankCore

final class CSVTests: XCTestCase {
    func testQuotedFields() throws {
        let table = try CSV.parse("a,b\r\n\"x, y\",\"say \"\"hi\"\"\"\r\nplain,2\r\n")
        XCTAssertEqual(table.header, ["a", "b"])
        XCTAssertEqual(table.records.count, 2)
        XCTAssertEqual(table.records[0]["a"], "x, y")
        XCTAssertEqual(table.records[0]["b"], "say \"hi\"")
        XCTAssertEqual(table.records[1].line, 3)
    }

    func testRejectsShortRows() {
        XCTAssertThrowsError(try CSV.parse("a,b\n1\n"))
    }

    func testRejectsUnterminatedQuote() {
        XCTAssertThrowsError(try CSV.parse("a\n\"open\n"))
    }
}

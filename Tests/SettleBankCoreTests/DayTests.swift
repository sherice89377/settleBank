import XCTest
@testable import SettleBankCore

final class DayTests: XCTestCase {
    func testDifferences() throws {
        XCTAssertEqual(try Day("2026-11-02") - Day("2026-10-30"), 3)
        XCTAssertEqual(try Day("2028-03-01") - Day("2028-02-28"), 2)
        XCTAssertEqual(try Day("2026-01-01") - Day("2025-12-31"), 1)
        XCTAssertEqual(try Day("1970-01-01").ordinal, 0)
    }

    func testRejectsInvalidDates() {
        for text in ["2026-02-29", "2026-13-01", "2026-1-01", "10/05/2026", ""] {
            XCTAssertThrowsError(try Day(text), text)
        }
    }
}

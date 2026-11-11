import XCTest
@testable import SettleBankCore

final class MoneyTests: XCTestCase {
    func testParsesCents() throws {
        XCTAssertEqual(try Money.cents("1234.56"), 123456)
        XCTAssertEqual(try Money.cents("-0.50"), -50)
        XCTAssertEqual(try Money.cents("+12.00"), 1200)
        XCTAssertEqual(try Money.cents(" 7.05 "), 705)
    }

    func testRejectsLooseAmounts() {
        for text in ["1.5", "12", "1.234", "abc", "", "-", "1,000.00"] {
            XCTAssertThrowsError(try Money.cents(text), text)
        }
    }

    func testFormats() {
        XCTAssertEqual(Money.format(123456), "1234.56")
        XCTAssertEqual(Money.format(-5), "-0.05")
        XCTAssertEqual(Money.format(0), "0.00")
    }
}

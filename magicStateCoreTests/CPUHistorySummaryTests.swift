import XCTest
@testable import MagicStateCore

final class CPUHistorySummaryTests: XCTestCase {
    func testSummaryUsesLatestAverageAndPeakValues() {
        let summary = CPUHistorySummary(values: [0.2, 0.5, 0.3])

        XCTAssertEqual(summary.current, 0.3)
        XCTAssertEqual(summary.average, 1.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(summary.peak, 0.5)
    }

    func testSummaryUsesZeroesWhenHistoryIsEmpty() {
        let summary = CPUHistorySummary(values: [])

        XCTAssertEqual(summary.current, 0)
        XCTAssertEqual(summary.average, 0)
        XCTAssertEqual(summary.peak, 0)
    }
}

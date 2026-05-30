import XCTest
@testable import MagicStateCore

final class MetricFormattingTests: XCTestCase {
    func testPercentFormattingClampsAndRounds() {
        XCTAssertEqual(MetricFormatting.percent(0.184), "18%")
        XCTAssertEqual(MetricFormatting.percent(1.4), "100%")
        XCTAssertEqual(MetricFormatting.percent(-0.2), "0%")
    }

    func testByteFormattingUsesBinaryUnits() {
        XCTAssertEqual(MetricFormatting.bytes(512), "512 B")
        XCTAssertEqual(MetricFormatting.bytes(1_048_576), "1.0 MB")
        XCTAssertEqual(MetricFormatting.bytes(1_073_741_824), "1.0 GB")
    }

    func testSpeedFormattingAddsPerSecondSuffix() {
        XCTAssertEqual(MetricFormatting.speed(bytesPerSecond: 2_097_152), "2.0 MB/s")
    }

    func testUnavailableTextIsStable() {
        XCTAssertEqual(MetricFormatting.unavailable, "--")
        XCTAssertEqual(MetricFormatting.notSupported, "Not supported")
    }
}

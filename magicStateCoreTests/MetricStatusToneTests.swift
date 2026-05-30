import XCTest
@testable import MagicStateCore

final class MetricStatusToneTests: XCTestCase {
    func testUnavailableMetricsAreInactive() {
        let metric = MetricDisplay(title: "CPU", value: "--", availability: .unavailable)

        XCTAssertEqual(MetricStatusTone.tone(for: metric), .inactive)
    }

    func testCPUUsesWarningAndCriticalThresholds() {
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "CPU", value: "79%")), .normal)
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "CPU", value: "80%")), .warning)
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "CPU", value: "90%")), .critical)
    }

    func testMemoryUsesWarningAndCriticalThresholds() {
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "Memory", value: "84%")), .normal)
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "Memory", value: "85%")), .warning)
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "Memory", value: "95%")), .critical)
    }

    func testBatteryUsesLowChargeThresholds() {
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "Battery", value: "26%")), .normal)
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "Battery", value: "25%")), .warning)
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "Battery", value: "15%")), .critical)
    }

    func testSensorsUseThermalStateNames() {
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "Sensors", value: "Nominal")), .normal)
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "Sensors", value: "Fair")), .warning)
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "Sensors", value: "Serious")), .critical)
        XCTAssertEqual(MetricStatusTone.tone(for: MetricDisplay(title: "Sensors", value: "Critical")), .critical)
    }
}

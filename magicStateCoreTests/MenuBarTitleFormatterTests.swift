import XCTest
@testable import MagicStateCore

final class MenuBarTitleFormatterTests: XCTestCase {
    func testTitleUsesCPUAndMemoryValues() {
        let cards = [
            MetricDisplay(title: "CPU", value: "18%", detail: "Active"),
            MetricDisplay(title: "Memory", value: "62%", detail: "5.0 GB / 8.0 GB")
        ]

        XCTAssertEqual(MenuBarTitleFormatter.title(for: cards), "CPU 18%  RAM 62%")
    }

    func testTitleFallsBackWhenMemoryIsMissing() {
        let cards = [
            MetricDisplay(title: "CPU", value: "18%", detail: "Active")
        ]

        XCTAssertEqual(MenuBarTitleFormatter.title(for: cards), "CPU 18%  RAM --")
    }

    func testTitleFallsBackForUnavailableValues() {
        let cards = [
            MetricDisplay(title: "CPU", value: "--", availability: .unavailable),
            MetricDisplay(title: "Memory", value: "Not supported", availability: .notSupported)
        ]

        XCTAssertEqual(MenuBarTitleFormatter.title(for: cards), "CPU --  RAM --")
    }
}

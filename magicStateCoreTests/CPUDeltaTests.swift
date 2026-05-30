import XCTest
@testable import MagicStateCore

final class CPUDeltaTests: XCTestCase {
    func testCPUUsageFromTickDelta() {
        let previous = CPUTicks(user: 100, system: 100, idle: 800, nice: 0)
        let current = CPUTicks(user: 200, system: 150, idle: 850, nice: 0)

        XCTAssertEqual(CPUUsageCalculator.usage(previous: previous, current: current), 0.75, accuracy: 0.001)
    }

    func testCPUUsageReturnsZeroWhenNoTimePassed() {
        let ticks = CPUTicks(user: 1, system: 1, idle: 1, nice: 1)
        XCTAssertEqual(CPUUsageCalculator.usage(previous: ticks, current: ticks), 0)
    }
}

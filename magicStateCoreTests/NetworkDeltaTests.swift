import XCTest
@testable import MagicStateCore

final class NetworkDeltaTests: XCTestCase {
    func testNetworkSpeedFromCounterDelta() {
        let previous = NetworkCounters(receivedBytes: 1_000, sentBytes: 2_000, timestamp: 10)
        let current = NetworkCounters(receivedBytes: 3_000, sentBytes: 2_500, timestamp: 12)

        let speed = NetworkSpeedCalculator.speed(previous: previous, current: current)

        XCTAssertEqual(speed.downloadBytesPerSecond, 1_000)
        XCTAssertEqual(speed.uploadBytesPerSecond, 250)
    }

    func testNetworkSpeedReturnsZeroForInvalidInterval() {
        let previous = NetworkCounters(receivedBytes: 1_000, sentBytes: 1_000, timestamp: 10)
        let current = NetworkCounters(receivedBytes: 2_000, sentBytes: 2_000, timestamp: 10)

        let speed = NetworkSpeedCalculator.speed(previous: previous, current: current)

        XCTAssertEqual(speed.downloadBytesPerSecond, 0)
        XCTAssertEqual(speed.uploadBytesPerSecond, 0)
    }
}

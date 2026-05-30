import XCTest
@testable import MagicStateCore

final class SystemMonitorServiceTests: XCTestCase {
    func testComposedServiceBuildsSnapshotFromReaders() async throws {
        let service = SystemMonitorService(
            cpuReader: MockCPUReader(),
            memoryReader: MockMemoryReader(),
            diskReader: MockDiskReader(),
            networkReader: MockNetworkReader(),
            batteryReader: MockBatteryReader(),
            sensorReader: MockSensorReader()
        )

        let snapshot = try await service.snapshot()

        XCTAssertEqual(snapshot.cpu?.usage, 0.5)
        XCTAssertEqual(snapshot.memory?.usedBytes, 2_000)
        XCTAssertEqual(snapshot.disk?.totalBytes, 8_000)
        XCTAssertEqual(snapshot.network?.downloadBytesPerSecond, 222)
        XCTAssertEqual(snapshot.battery?.level, 0.8)
        XCTAssertEqual(snapshot.sensors?.isSupported, true)
    }

    func testDefaultSensorReaderReportsUnsupported() {
        let sensor = SensorReader().read()

        XCTAssertEqual(sensor?.isSupported, false)
        XCTAssertNil(sensor?.temperatureCelsius)
        XCTAssertNil(sensor?.fanRPM)
    }
}

private struct MockCPUReader: CPUReading {
    func read() -> CPUMetric? { CPUMetric(usage: 0.5) }
}

private struct MockMemoryReader: MemoryReading {
    func read() -> MemoryMetric? { MemoryMetric(usedBytes: 2_000, totalBytes: 4_000) }
}

private struct MockDiskReader: DiskReading {
    func read() -> DiskMetric? { DiskMetric(usedBytes: 3_000, totalBytes: 8_000) }
}

private struct MockNetworkReader: NetworkReading {
    func read() -> NetworkMetric? { NetworkMetric(uploadBytesPerSecond: 111, downloadBytesPerSecond: 222) }
}

private struct MockBatteryReader: BatteryReading {
    func read() -> BatteryMetric? { BatteryMetric(level: 0.8, isCharging: true) }
}

private struct MockSensorReader: SensorReading {
    func read() -> SensorMetric? { SensorMetric(temperatureCelsius: 41, fanRPM: 2_000, isSupported: true) }
}

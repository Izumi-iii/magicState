import XCTest
@testable import MagicStateCore

final class DashboardViewModelTests: XCTestCase {
    func testRefreshMapsSnapshotIntoCards() async {
        let service = MockSystemMonitorService(snapshot: .sample)
        let viewModel = await DashboardViewModel(service: service, autoStart: false)

        await viewModel.refreshOnce()

        let cards = await viewModel.cards
        XCTAssertEqual(cards.map(\.title), ["CPU", "Memory", "Disk", "Network", "Battery", "Sensors"])
        XCTAssertEqual(cards[0].value, "42%")
        XCTAssertEqual(cards[5].value, "Nominal")
        XCTAssertEqual(cards[5].detail, "Public thermal state")
        XCTAssertEqual(cards[5].availability, .value)
    }

    func testRefreshKeepsDashboardUsableWhenServiceFails() async {
        let service = MockSystemMonitorService(error: SystemMonitorError.readerFailed("CPU"))
        let viewModel = await DashboardViewModel(service: service, autoStart: false)

        await viewModel.refreshOnce()

        let cards = await viewModel.cards
        XCTAssertEqual(cards[0].value, "--")
        XCTAssertEqual(cards.count, 6)
    }

    func testCPUHistoryKeepsLatestThirtyMinutesOfSamples() async {
        let service = SequenceSystemMonitorService(
            snapshots: (0..<1_805).map { index in
                SystemSnapshot(
                    cpu: CPUMetric(usage: Double(index) / 2_000),
                    memory: nil,
                    disk: nil,
                    network: nil,
                    battery: nil,
                    sensors: nil
                )
            }
        )
        let viewModel = await DashboardViewModel(service: service, autoStart: false)

        for _ in 0..<1_805 {
            await viewModel.refreshOnce()
        }

        let history = await viewModel.cpuHistory
        XCTAssertEqual(history.count, 1_800)
        XCTAssertEqual(history.first, 5.0 / 2_000)
        XCTAssertEqual(history.last, 1_804.0 / 2_000)
    }

    func testCPUHistoryDoesNotAppendWhenCPUIsMissingOrRefreshFails() async {
        let service = SequenceSystemMonitorService(
            snapshots: [
                SystemSnapshot(cpu: CPUMetric(usage: 0.25), memory: nil, disk: nil, network: nil, battery: nil, sensors: nil),
                SystemSnapshot(cpu: nil, memory: nil, disk: nil, network: nil, battery: nil, sensors: nil),
                SystemSnapshot(cpu: CPUMetric(usage: 0.5), memory: nil, disk: nil, network: nil, battery: nil, sensors: nil)
            ],
            failingIndexes: [2]
        )
        let viewModel = await DashboardViewModel(service: service, autoStart: false)

        await viewModel.refreshOnce()
        await viewModel.refreshOnce()
        await viewModel.refreshOnce()

        let history = await viewModel.cpuHistory
        XCTAssertEqual(history, [0.25])
    }
}

private struct MockSystemMonitorService: SystemMonitoring {
    var snapshot: SystemSnapshot?
    var error: Error?

    func snapshot() async throws -> SystemSnapshot {
        if let error {
            throw error
        }
        return snapshot ?? .empty
    }
}

private final class SequenceSystemMonitorService: SystemMonitoring {
    private var snapshots: [SystemSnapshot]
    private let failingIndexes: Set<Int>
    private var index = 0

    init(snapshots: [SystemSnapshot], failingIndexes: Set<Int> = []) {
        self.snapshots = snapshots
        self.failingIndexes = failingIndexes
    }

    func snapshot() async throws -> SystemSnapshot {
        defer { index += 1 }
        if failingIndexes.contains(index) {
            throw SystemMonitorError.readerFailed("CPU")
        }
        guard index < snapshots.count else {
            return .empty
        }
        return snapshots[index]
    }
}

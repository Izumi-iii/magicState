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
        XCTAssertEqual(cards[5].availability, .notSupported)
    }

    func testRefreshKeepsDashboardUsableWhenServiceFails() async {
        let service = MockSystemMonitorService(error: SystemMonitorError.readerFailed("CPU"))
        let viewModel = await DashboardViewModel(service: service, autoStart: false)

        await viewModel.refreshOnce()

        let cards = await viewModel.cards
        XCTAssertEqual(cards[0].value, "--")
        XCTAssertEqual(cards.count, 6)
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

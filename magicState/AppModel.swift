import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    let dashboardViewModel: DashboardViewModel

    @Published private(set) var menuBarTitle: String

    private let dashboardWindowController: DashboardWindowController
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let viewModel = DashboardViewModel(service: SystemMonitorService())
        self.dashboardViewModel = viewModel
        self.dashboardWindowController = DashboardWindowController(viewModel: viewModel)
        self.menuBarTitle = MenuBarTitleFormatter.title(for: viewModel.cards)

        viewModel.$cards
            .map(MenuBarTitleFormatter.title)
            .removeDuplicates()
            .sink { [weak self] title in
                self?.menuBarTitle = title
            }
            .store(in: &cancellables)
    }

    func openDashboard() {
        dashboardWindowController.showWindow()
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}

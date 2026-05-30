import AppKit
import SwiftUI

@MainActor
final class DashboardWindowController {
    private let viewModel: DashboardViewModel
    private var windowController: NSWindowController?

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    func showWindow() {
        if let window = windowController?.window {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: ContentView(viewModel: viewModel))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "magicState"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 900, height: 620))
        window.center()
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        windowController = controller
        controller.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

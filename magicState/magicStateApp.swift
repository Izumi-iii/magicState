//
//  magicStateApp.swift
//  magicState
//
//  Created by 1-6 on 2026/5/30.
//

import SwiftUI
import AppKit

@main
struct magicStateApp: App {
    @StateObject private var appModel = AppModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra(appModel.menuBarTitle, systemImage: "waveform.path.ecg") {
            MenuBarPanelView(
                viewModel: appModel.dashboardViewModel,
                openDashboard: appModel.openDashboard,
                quit: appModel.quit
            )
        }
        .menuBarExtraStyle(.window)
    }
}

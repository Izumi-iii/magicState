//
//  ContentView.swift
//  magicState
//
//  Created by 1-6 on 2026/5/30.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: DashboardViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 230), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VisualDesign.dashboardSpacing) {
                header
                CPUHistoryCardView(
                    metric: cpuMetric,
                    values: viewModel.cpuHistory,
                    summary: CPUHistorySummary(values: viewModel.cpuHistory)
                )

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(secondaryMetrics.enumerated()), id: \.offset) { _, metric in
                        MetricCardView(metric: metric) {
                            Spacer(minLength: 48)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(VisualDesign.dashboardBackground.ignoresSafeArea())
        .frame(minWidth: 760, minHeight: 520)
    }

    private var cpuMetric: MetricDisplay {
        viewModel.cards.first { $0.title == "CPU" } ?? MetricDisplay(title: "CPU", value: MetricFormatting.unavailable, availability: .unavailable)
    }

    private var secondaryMetrics: [MetricDisplay] {
        viewModel.cards.filter { $0.title != "CPU" }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("magicState")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("Live Mac system dashboard")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView(viewModel: DashboardViewModel(service: SystemMonitorService(), autoStart: false))
}

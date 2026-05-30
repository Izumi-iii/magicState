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
            VStack(alignment: .leading, spacing: 18) {
                header

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(viewModel.cards.enumerated()), id: \.offset) { _, metric in
                        MetricCardView(metric: metric) {
                            if metric.title == "CPU" {
                                HistoryBarChart(values: viewModel.cpuHistory)
                            } else {
                                Spacer(minLength: 48)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(minWidth: 760, minHeight: 520)
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

import SwiftUI

struct MenuBarPanelView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let openDashboard: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            cpuOverview

            VStack(spacing: 10) {
                ForEach(secondaryMetrics, id: \.title) { metric in
                    metricRow(metric)
                }
            }

            Divider()

            HStack(spacing: 10) {
                Button("Open Dashboard", action: openDashboard)
                    .keyboardShortcut("o")
                Spacer()
                Button("Quit", action: quit)
                    .keyboardShortcut("q")
            }
        }
        .padding(16)
        .frame(width: 360)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("magicState")
                .font(.headline)
            Text("Live Mac system dashboard")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var cpuMetric: MetricDisplay {
        viewModel.cards.first { $0.title == "CPU" } ?? MetricDisplay(title: "CPU", value: MetricFormatting.unavailable, availability: .unavailable)
    }

    private var secondaryMetrics: [MetricDisplay] {
        viewModel.cards.filter { $0.title != "CPU" }
    }

    private var cpuOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            metricRow(cpuMetric)

            CPUHistoryChartView(
                values: viewModel.cpuHistory,
                height: 58,
                showsAxisLabels: false
            )

            let summary = CPUHistorySummary(values: viewModel.cpuHistory)
            HStack {
                summaryLabel("Avg", value: summary.average)
                Spacer()
                summaryLabel("Peak", value: summary.peak)
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func summaryLabel(_ title: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(MetricFormatting.percent(value))
                .fontWeight(.semibold)
        }
        .font(.caption2.monospacedDigit())
    }

    private func metricRow(_ metric: MetricDisplay) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle()
                .fill(metric.availability == .value ? Color.green : Color.secondary)
                .frame(width: 7, height: 7)

            Text(metric.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text(metric.value)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if !metric.detail.isEmpty {
                    Text(metric.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

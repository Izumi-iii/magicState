import SwiftUI

struct CPUHistoryCardView: View {
    let metric: MetricDisplay
    let values: [Double]
    let summary: CPUHistorySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(metric.title)
                            .font(.headline)
                        availabilityDot
                    }

                    Text(metric.value)
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("30 min history")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 10) {
                    summaryPill(title: "Current", value: summary.current)
                    summaryPill(title: "Average", value: summary.average)
                    summaryPill(title: "Peak", value: summary.peak)
                }
            }

            CPUHistoryChartView(values: values)
        }
        .padding(18)
        .frame(minHeight: 260, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var availabilityDot: some View {
        Circle()
            .fill(metric.availability == .value ? Color.green : Color.secondary)
            .frame(width: 8, height: 8)
            .accessibilityLabel(metric.availability == .value ? "Available" : "Unavailable")
    }

    private func summaryPill(title: String, value: Double) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(MetricFormatting.percent(value))
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CPUHistoryChartView: View {
    let values: [Double]

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                ZStack {
                    chartGrid(in: proxy.size)
                    thresholdLine(in: proxy.size)
                    chartArea(in: proxy.size)
                    chartLine(in: proxy.size)
                }
            }
            .frame(height: 132)

            HStack {
                Text("30 min ago")
                Spacer()
                Text("80%")
                Spacer()
                Text("now")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityHidden(true)
    }

    private func chartGrid(in size: CGSize) -> some View {
        Path { path in
            for ratio in [0.25, 0.5, 0.75] {
                let y = size.height * ratio
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
    }

    private func thresholdLine(in size: CGSize) -> some View {
        Path { path in
            let y = yPosition(for: 0.8, height: size.height)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        .stroke(Color.orange.opacity(0.75), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
    }

    private func chartArea(in size: CGSize) -> some View {
        areaPath(in: size)
            .fill(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.32), Color.accentColor.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private func chartLine(in size: CGSize) -> some View {
        linePath(in: size)
            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
    }

    private func linePath(in size: CGSize) -> Path {
        let points = chartPoints(in: size)
        return Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }

    private func areaPath(in size: CGSize) -> Path {
        let points = chartPoints(in: size)
        return Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: first.x, y: size.height))
            path.addLine(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            if let last = points.last {
                path.addLine(to: CGPoint(x: last.x, y: size.height))
            }
            path.closeSubpath()
        }
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        guard values.count > 1 else {
            return [CGPoint(x: size.width, y: yPosition(for: values[0], height: size.height))]
        }

        let step = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * step,
                y: yPosition(for: value, height: size.height)
            )
        }
    }

    private func yPosition(for value: Double, height: CGFloat) -> CGFloat {
        let clamped = min(max(value, 0), 1)
        return height - CGFloat(clamped) * height
    }
}

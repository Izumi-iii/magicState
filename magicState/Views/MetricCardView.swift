import SwiftUI

struct MetricCardView<Content: View>: View {
    let metric: MetricDisplay
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(metric.title)
                    .font(.headline)
                Spacer()
                availabilityDot
            }

            Text(metric.value)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if !metric.detail.isEmpty {
                Text(metric.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            content()
        }
        .padding(16)
        .frame(minHeight: 150, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var availabilityDot: some View {
        Circle()
            .fill(metric.availability == .value ? Color.green : Color.secondary)
            .frame(width: 8, height: 8)
            .accessibilityLabel(metric.availability == .value ? "Available" : "Unavailable")
    }
}

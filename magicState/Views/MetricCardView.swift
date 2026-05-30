import SwiftUI

struct MetricCardView<Content: View>: View {
    let metric: MetricDisplay
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    Text(metric.title)
                        .font(.headline)
                } icon: {
                    Image(systemName: VisualDesign.symbolName(for: metric))
                        .foregroundStyle(VisualDesign.statusColor(for: metric))
                }
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
        .padding(VisualDesign.cardPadding)
        .frame(minHeight: 150, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: VisualDesign.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: VisualDesign.cornerRadius, style: .continuous)
                .stroke(VisualDesign.statusColor(for: metric).opacity(0.18), lineWidth: 1)
        }
    }

    private var availabilityDot: some View {
        Circle()
            .fill(VisualDesign.statusColor(for: metric))
            .frame(width: 8, height: 8)
            .shadow(color: VisualDesign.statusColor(for: metric).opacity(0.35), radius: 3)
            .accessibilityLabel(metric.availability == .value ? "Available" : "Unavailable")
    }
}

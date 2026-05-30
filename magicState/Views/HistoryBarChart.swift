import SwiftUI

struct HistoryBarChart: View {
    let values: [Double]

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Capsule()
                    .fill(Color.accentColor.opacity(0.75))
                    .frame(width: 5, height: max(4, CGFloat(min(max(value, 0), 1)) * 44))
            }
        }
        .frame(height: 48, alignment: .bottomLeading)
        .accessibilityHidden(true)
    }
}

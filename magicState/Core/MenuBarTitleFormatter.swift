import Foundation

public enum MenuBarTitleFormatter {
    public static func title(for cards: [MetricDisplay]) -> String {
        let cpu = value(for: "CPU", in: cards)
        let memory = value(for: "Memory", in: cards)
        return "CPU \(cpu)  RAM \(memory)"
    }

    private static func value(for title: String, in cards: [MetricDisplay]) -> String {
        guard let card = cards.first(where: { $0.title == title }),
              card.availability == .value,
              card.value != MetricFormatting.notSupported else {
            return MetricFormatting.unavailable
        }

        return card.value
    }
}

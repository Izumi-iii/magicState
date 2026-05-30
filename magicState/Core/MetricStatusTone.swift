import Foundation

public enum MetricStatusTone: Equatable, Sendable {
    case normal
    case warning
    case critical
    case inactive

    public static func tone(for metric: MetricDisplay) -> MetricStatusTone {
        guard metric.availability == .value else {
            return .inactive
        }

        switch metric.title {
        case "CPU":
            return percentTone(metric.value, warning: 0.8, critical: 0.9)
        case "Memory":
            return percentTone(metric.value, warning: 0.85, critical: 0.95)
        case "Battery":
            guard let value = percentValue(metric.value) else { return .normal }
            if value <= 0.15 { return .critical }
            if value <= 0.25 { return .warning }
            return .normal
        case "Sensors":
            switch metric.value {
            case "Critical", "Serious":
                return .critical
            case "Fair":
                return .warning
            default:
                return .normal
            }
        default:
            return .normal
        }
    }

    private static func percentTone(_ text: String, warning: Double, critical: Double) -> MetricStatusTone {
        guard let value = percentValue(text) else {
            return .normal
        }
        if value >= critical { return .critical }
        if value >= warning { return .warning }
        return .normal
    }

    private static func percentValue(_ text: String) -> Double? {
        let number = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "%", with: "")
        return Double(number).map { $0 / 100 }
    }
}

import SwiftUI

enum VisualDesign {
    static let cornerRadius: CGFloat = 8
    static let cardPadding: CGFloat = 16
    static let dashboardSpacing: CGFloat = 18

    static let cpu = Color(red: 0.08, green: 0.45, blue: 0.95)
    static let memory = Color(red: 0.52, green: 0.36, blue: 0.92)
    static let disk = Color(red: 0.00, green: 0.58, blue: 0.70)
    static let network = Color(red: 0.12, green: 0.62, blue: 0.36)
    static let battery = Color(red: 0.95, green: 0.58, blue: 0.14)
    static let sensors = Color(red: 0.78, green: 0.22, blue: 0.22)

    static let warning = Color.orange
    static let critical = Color.red
    static let inactive = Color.secondary

    static var dashboardBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .controlBackgroundColor).opacity(0.55)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func accentColor(for metric: MetricDisplay) -> Color {
        switch metric.title {
        case "CPU":
            cpu
        case "Memory":
            memory
        case "Disk":
            disk
        case "Network":
            network
        case "Battery":
            battery
        case "Sensors":
            sensors
        default:
            cpu
        }
    }

    static func statusColor(for metric: MetricDisplay) -> Color {
        switch MetricStatusTone.tone(for: metric) {
        case .normal:
            accentColor(for: metric)
        case .warning:
            warning
        case .critical:
            critical
        case .inactive:
            inactive
        }
    }

    static func symbolName(for metric: MetricDisplay) -> String {
        switch metric.title {
        case "CPU":
            "cpu"
        case "Memory":
            "memorychip"
        case "Disk":
            "internaldrive"
        case "Network":
            "arrow.up.arrow.down"
        case "Battery":
            "battery.75"
        case "Sensors":
            "thermometer.medium"
        default:
            "waveform.path.ecg"
        }
    }
}

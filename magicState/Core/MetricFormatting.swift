import Foundation

public enum MetricFormatting {
    public static let unavailable = "--"
    public static let notSupported = "Not supported"

    public static func percent(_ value: Double) -> String {
        let clamped = min(max(value, 0), 1)
        return "\(Int((clamped * 100).rounded()))%"
    }

    public static func bytes(_ value: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var amount = Double(value)
        var unitIndex = 0

        while amount >= 1024, unitIndex < units.count - 1 {
            amount /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(Int(amount)) \(units[unitIndex])"
        }
        return String(format: "%.1f %@", amount, units[unitIndex])
    }

    public static func speed(bytesPerSecond: UInt64) -> String {
        "\(bytes(bytesPerSecond))/s"
    }
}

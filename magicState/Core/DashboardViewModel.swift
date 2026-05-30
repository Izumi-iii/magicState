import Foundation
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public private(set) var cards: [MetricDisplay]
    @Published public private(set) var cpuHistory: [Double]

    private let service: SystemMonitoring
    private var timer: Timer?

    public init(service: SystemMonitoring, autoStart: Bool = true) {
        self.service = service
        self.cards = Self.cards(from: .empty)
        self.cpuHistory = []

        if autoStart {
            start()
        }
    }

    deinit {
        timer?.invalidate()
    }

    public func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshOnce()
            }
        }
        Task { await refreshOnce() }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    public func refreshOnce() async {
        do {
            let snapshot = try await service.snapshot()
            cards = Self.cards(from: snapshot)
            if let usage = snapshot.cpu?.usage {
                cpuHistory.append(usage)
                if cpuHistory.count > 30 {
                    cpuHistory.removeFirst(cpuHistory.count - 30)
                }
            }
        } catch {
            cards = Self.cards(from: .empty)
        }
    }

    private static func cards(from snapshot: SystemSnapshot) -> [MetricDisplay] {
        [
            cpuCard(snapshot.cpu),
            memoryCard(snapshot.memory),
            diskCard(snapshot.disk),
            networkCard(snapshot.network),
            batteryCard(snapshot.battery),
            sensorCard(snapshot.sensors)
        ]
    }

    private static func cpuCard(_ metric: CPUMetric?) -> MetricDisplay {
        guard let metric else {
            return MetricDisplay(title: "CPU", value: MetricFormatting.unavailable, availability: .unavailable)
        }
        return MetricDisplay(title: "CPU", value: MetricFormatting.percent(metric.usage), detail: "Active")
    }

    private static func memoryCard(_ metric: MemoryMetric?) -> MetricDisplay {
        guard let metric, metric.totalBytes > 0 else {
            return MetricDisplay(title: "Memory", value: MetricFormatting.unavailable, availability: .unavailable)
        }
        let ratio = Double(metric.usedBytes) / Double(metric.totalBytes)
        return MetricDisplay(title: "Memory", value: MetricFormatting.percent(ratio), detail: "\(MetricFormatting.bytes(metric.usedBytes)) / \(MetricFormatting.bytes(metric.totalBytes))")
    }

    private static func diskCard(_ metric: DiskMetric?) -> MetricDisplay {
        guard let metric, metric.totalBytes > 0 else {
            return MetricDisplay(title: "Disk", value: MetricFormatting.unavailable, availability: .unavailable)
        }
        let ratio = Double(metric.usedBytes) / Double(metric.totalBytes)
        return MetricDisplay(title: "Disk", value: MetricFormatting.percent(ratio), detail: "\(MetricFormatting.bytes(metric.usedBytes)) used")
    }

    private static func networkCard(_ metric: NetworkMetric?) -> MetricDisplay {
        guard let metric else {
            return MetricDisplay(title: "Network", value: MetricFormatting.unavailable, availability: .unavailable)
        }
        return MetricDisplay(title: "Network", value: "↓ \(MetricFormatting.speed(bytesPerSecond: metric.downloadBytesPerSecond))", detail: "↑ \(MetricFormatting.speed(bytesPerSecond: metric.uploadBytesPerSecond))")
    }

    private static func batteryCard(_ metric: BatteryMetric?) -> MetricDisplay {
        guard let metric, let level = metric.level else {
            return MetricDisplay(title: "Battery", value: MetricFormatting.notSupported, availability: .notSupported)
        }
        return MetricDisplay(title: "Battery", value: MetricFormatting.percent(level), detail: metric.isCharging ? "Charging" : "On battery")
    }

    private static func sensorCard(_ metric: SensorMetric?) -> MetricDisplay {
        guard let metric, metric.isSupported else {
            return MetricDisplay(title: "Sensors", value: MetricFormatting.notSupported, availability: .notSupported)
        }
        let temperature = metric.temperatureCelsius.map { String(format: "%.0f°C", $0) } ?? MetricFormatting.unavailable
        let fan = metric.fanRPM.map { "\($0) RPM" } ?? MetricFormatting.unavailable
        return MetricDisplay(title: "Sensors", value: temperature, detail: fan)
    }
}

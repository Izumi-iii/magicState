import Foundation

public enum SystemMonitorError: Error, Equatable, Sendable {
    case readerFailed(String)
}

public struct CPUMetric: Equatable, Sendable {
    public var usage: Double
    public init(usage: Double) { self.usage = usage }
}

public struct MemoryMetric: Equatable, Sendable {
    public var usedBytes: UInt64
    public var totalBytes: UInt64
    public init(usedBytes: UInt64, totalBytes: UInt64) {
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
    }
}

public struct DiskMetric: Equatable, Sendable {
    public var usedBytes: UInt64
    public var totalBytes: UInt64
    public init(usedBytes: UInt64, totalBytes: UInt64) {
        self.usedBytes = usedBytes
        self.totalBytes = totalBytes
    }
}

public struct NetworkMetric: Equatable, Sendable {
    public var uploadBytesPerSecond: UInt64
    public var downloadBytesPerSecond: UInt64
    public init(uploadBytesPerSecond: UInt64, downloadBytesPerSecond: UInt64) {
        self.uploadBytesPerSecond = uploadBytesPerSecond
        self.downloadBytesPerSecond = downloadBytesPerSecond
    }
}

public struct BatteryMetric: Equatable, Sendable {
    public var level: Double?
    public var isCharging: Bool
    public init(level: Double?, isCharging: Bool) {
        self.level = level
        self.isCharging = isCharging
    }
}

public struct SensorMetric: Equatable, Sendable {
    public var temperatureCelsius: Double?
    public var fanRPM: Int?
    public var isSupported: Bool
    public init(temperatureCelsius: Double?, fanRPM: Int?, isSupported: Bool) {
        self.temperatureCelsius = temperatureCelsius
        self.fanRPM = fanRPM
        self.isSupported = isSupported
    }
}

public struct SystemSnapshot: Equatable, Sendable {
    public var cpu: CPUMetric?
    public var memory: MemoryMetric?
    public var disk: DiskMetric?
    public var network: NetworkMetric?
    public var battery: BatteryMetric?
    public var sensors: SensorMetric?

    public init(cpu: CPUMetric?, memory: MemoryMetric?, disk: DiskMetric?, network: NetworkMetric?, battery: BatteryMetric?, sensors: SensorMetric?) {
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.network = network
        self.battery = battery
        self.sensors = sensors
    }

    public static let empty = SystemSnapshot(cpu: nil, memory: nil, disk: nil, network: nil, battery: nil, sensors: nil)

    public static let sample = SystemSnapshot(
        cpu: CPUMetric(usage: 0.42),
        memory: MemoryMetric(usedBytes: 4_294_967_296, totalBytes: 8_589_934_592),
        disk: DiskMetric(usedBytes: 128_849_018_880, totalBytes: 256_000_000_000),
        network: NetworkMetric(uploadBytesPerSecond: 1_048_576, downloadBytesPerSecond: 2_097_152),
        battery: BatteryMetric(level: 0.76, isCharging: true),
        sensors: SensorMetric(temperatureCelsius: nil, fanRPM: nil, isSupported: false)
    )
}

public protocol SystemMonitoring {
    func snapshot() async throws -> SystemSnapshot
}

public protocol CPUReading { func read() -> CPUMetric? }
public protocol MemoryReading { func read() -> MemoryMetric? }
public protocol DiskReading { func read() -> DiskMetric? }
public protocol NetworkReading { func read() -> NetworkMetric? }
public protocol BatteryReading { func read() -> BatteryMetric? }
public protocol SensorReading { func read() -> SensorMetric? }

extension CPUReader: CPUReading {}
extension NetworkReader: NetworkReading {}

public final class SystemMonitorService: SystemMonitoring {
    private let cpuReader: CPUReading
    private let memoryReader: MemoryReading
    private let diskReader: DiskReading
    private let networkReader: NetworkReading
    private let batteryReader: BatteryReading
    private let sensorReader: SensorReading

    public init(
        cpuReader: CPUReading = CPUReader(),
        memoryReader: MemoryReading = MemoryReader(),
        diskReader: DiskReading = DiskReader(),
        networkReader: NetworkReading = NetworkReader(),
        batteryReader: BatteryReading = BatteryReader(),
        sensorReader: SensorReading = SensorReader()
    ) {
        self.cpuReader = cpuReader
        self.memoryReader = memoryReader
        self.diskReader = diskReader
        self.networkReader = networkReader
        self.batteryReader = batteryReader
        self.sensorReader = sensorReader
    }

    public func snapshot() async throws -> SystemSnapshot {
        SystemSnapshot(
            cpu: cpuReader.read(),
            memory: memoryReader.read(),
            disk: diskReader.read(),
            network: networkReader.read(),
            battery: batteryReader.read(),
            sensors: sensorReader.read()
        )
    }
}

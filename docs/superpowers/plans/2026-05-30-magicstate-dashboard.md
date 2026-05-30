# magicState Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS SwiftUI dashboard window that displays live CPU, memory, disk, network, battery, and optional sensor status.

**Architecture:** Keep UI, refresh state, and macOS API readers separated. Put testable models, formatters, delta calculators, and service protocols in `magicState/Core`; the Xcode app target picks them up through the existing synchronized `magicState` group, and a root `Package.swift` exposes the same core files to `swift test`.

**Tech Stack:** Swift 5, SwiftUI, Foundation, Combine, Mach host APIs, IOKit power sources, `getifaddrs`, XCTest through Swift Package Manager, Xcode macOS app target.

---

## File Structure

- Create `Package.swift`: SwiftPM test harness for `magicState/Core`.
- Create `magicState/Core/MetricModels.swift`: reusable metric status and snapshot types.
- Create `magicState/Core/MetricFormatting.swift`: byte, percent, speed, and unavailable display formatting.
- Create `magicState/Core/SystemMonitorService.swift`: service and reader protocols plus snapshot composition.
- Create `magicState/Core/DashboardViewModel.swift`: timer-driven dashboard state for SwiftUI.
- Create `magicState/Core/Readers/CPUReader.swift`: CPU tick sampling and active usage calculation.
- Create `magicState/Core/Readers/MemoryReader.swift`: VM statistics and physical memory reading.
- Create `magicState/Core/Readers/DiskReader.swift`: system volume capacity reading.
- Create `magicState/Core/Readers/NetworkReader.swift`: interface byte counters and speed delta calculation.
- Create `magicState/Core/Readers/BatteryReader.swift`: IOKit power source reader.
- Create `magicState/Core/Readers/SensorReader.swift`: optional sensor reader returning unavailable by default.
- Create `magicState/Views/MetricCardView.swift`: shared metric card shell.
- Create `magicState/Views/HistoryBarChart.swift`: simple CPU history visualization.
- Modify `magicState/ContentView.swift`: dashboard layout using the view model.
- Create `magicStateCoreTests/MetricFormattingTests.swift`: formatter tests.
- Create `magicStateCoreTests/DashboardViewModelTests.swift`: snapshot and partial failure tests.
- Create `magicStateCoreTests/CPUDeltaTests.swift`: CPU usage delta tests.
- Create `magicStateCoreTests/NetworkDeltaTests.swift`: network speed delta tests.

## Task 1: Add Testable Core Models and Formatters

**Files:**
- Create: `Package.swift`
- Create: `magicState/Core/MetricModels.swift`
- Create: `magicState/Core/MetricFormatting.swift`
- Create: `magicStateCoreTests/MetricFormattingTests.swift`

- [ ] **Step 1: Write formatter tests**

Create `magicStateCoreTests/MetricFormattingTests.swift`:

```swift
import XCTest
@testable import MagicStateCore

final class MetricFormattingTests: XCTestCase {
    func testPercentFormattingClampsAndRounds() {
        XCTAssertEqual(MetricFormatting.percent(0.184), "18%")
        XCTAssertEqual(MetricFormatting.percent(1.4), "100%")
        XCTAssertEqual(MetricFormatting.percent(-0.2), "0%")
    }

    func testByteFormattingUsesBinaryUnits() {
        XCTAssertEqual(MetricFormatting.bytes(512), "512 B")
        XCTAssertEqual(MetricFormatting.bytes(1_048_576), "1.0 MB")
        XCTAssertEqual(MetricFormatting.bytes(1_073_741_824), "1.0 GB")
    }

    func testSpeedFormattingAddsPerSecondSuffix() {
        XCTAssertEqual(MetricFormatting.speed(bytesPerSecond: 2_097_152), "2.0 MB/s")
    }

    func testUnavailableTextIsStable() {
        XCTAssertEqual(MetricFormatting.unavailable, "--")
        XCTAssertEqual(MetricFormatting.notSupported, "Not supported")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test
```

Expected: FAIL because `Package.swift` and `MagicStateCore` do not exist yet.

- [ ] **Step 3: Add SwiftPM harness and minimal formatter implementation**

Create `Package.swift`:

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MagicStateCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "MagicStateCore", targets: ["MagicStateCore"])
    ],
    targets: [
        .target(
            name: "MagicStateCore",
            path: "magicState/Core"
        ),
        .testTarget(
            name: "MagicStateCoreTests",
            dependencies: ["MagicStateCore"],
            path: "magicStateCoreTests"
        )
    ]
)
```

Create `magicState/Core/MetricModels.swift`:

```swift
import Foundation

public enum MetricAvailability: Equatable, Sendable {
    case value
    case unavailable
    case notSupported
    case stale
}

public struct MetricDisplay: Equatable, Sendable {
    public var title: String
    public var value: String
    public var detail: String
    public var availability: MetricAvailability

    public init(title: String, value: String, detail: String = "", availability: MetricAvailability = .value) {
        self.title = title
        self.value = value
        self.detail = detail
        self.availability = availability
    }
}
```

Create `magicState/Core/MetricFormatting.swift`:

```swift
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
```

- [ ] **Step 4: Run formatter tests**

Run:

```bash
swift test --filter MetricFormattingTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Package.swift magicState/Core/MetricModels.swift magicState/Core/MetricFormatting.swift magicStateCoreTests/MetricFormattingTests.swift
git commit -m "Add core metric formatting"
```

## Task 2: Add Snapshot Service Protocols and View Model

**Files:**
- Create: `magicState/Core/SystemMonitorService.swift`
- Create: `magicState/Core/DashboardViewModel.swift`
- Create: `magicStateCoreTests/DashboardViewModelTests.swift`

- [ ] **Step 1: Write view model tests**

Create `magicStateCoreTests/DashboardViewModelTests.swift`:

```swift
import XCTest
@testable import MagicStateCore

final class DashboardViewModelTests: XCTestCase {
    func testRefreshMapsSnapshotIntoCards() async {
        let service = MockSystemMonitorService(snapshot: .sample)
        let viewModel = await DashboardViewModel(service: service, autoStart: false)

        await viewModel.refreshOnce()

        let cards = await viewModel.cards
        XCTAssertEqual(cards.map(\.title), ["CPU", "Memory", "Disk", "Network", "Battery", "Sensors"])
        XCTAssertEqual(cards[0].value, "42%")
        XCTAssertEqual(cards[5].availability, .notSupported)
    }

    func testRefreshKeepsDashboardUsableWhenServiceFails() async {
        let service = MockSystemMonitorService(error: SystemMonitorError.readerFailed("CPU"))
        let viewModel = await DashboardViewModel(service: service, autoStart: false)

        await viewModel.refreshOnce()

        let cards = await viewModel.cards
        XCTAssertEqual(cards[0].value, "--")
        XCTAssertEqual(cards.count, 6)
    }
}

private struct MockSystemMonitorService: SystemMonitoring {
    var snapshot: SystemSnapshot?
    var error: Error?

    func snapshot() async throws -> SystemSnapshot {
        if let error {
            throw error
        }
        return snapshot ?? .empty
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter DashboardViewModelTests
```

Expected: FAIL because `DashboardViewModel`, `SystemSnapshot`, and `SystemMonitoring` do not exist yet.

- [ ] **Step 3: Add service protocols and snapshot model**

Create `magicState/Core/SystemMonitorService.swift`:

```swift
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

public protocol SystemMonitoring: Sendable {
    func snapshot() async throws -> SystemSnapshot
}
```

- [ ] **Step 4: Add dashboard view model**

Create `magicState/Core/DashboardViewModel.swift`:

```swift
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
```

- [ ] **Step 5: Run view model tests**

Run:

```bash
swift test --filter DashboardViewModelTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add magicState/Core/SystemMonitorService.swift magicState/Core/DashboardViewModel.swift magicStateCoreTests/DashboardViewModelTests.swift
git commit -m "Add dashboard snapshot view model"
```

## Task 3: Add CPU and Network Delta Logic

**Files:**
- Create: `magicState/Core/Readers/CPUReader.swift`
- Create: `magicState/Core/Readers/NetworkReader.swift`
- Create: `magicStateCoreTests/CPUDeltaTests.swift`
- Create: `magicStateCoreTests/NetworkDeltaTests.swift`

- [ ] **Step 1: Write CPU delta tests**

Create `magicStateCoreTests/CPUDeltaTests.swift`:

```swift
import XCTest
@testable import MagicStateCore

final class CPUDeltaTests: XCTestCase {
    func testCPUUsageFromTickDelta() {
        let previous = CPUTicks(user: 100, system: 100, idle: 800, nice: 0)
        let current = CPUTicks(user: 200, system: 150, idle: 850, nice: 0)

        XCTAssertEqual(CPUUsageCalculator.usage(previous: previous, current: current), 0.75, accuracy: 0.001)
    }

    func testCPUUsageReturnsZeroWhenNoTimePassed() {
        let ticks = CPUTicks(user: 1, system: 1, idle: 1, nice: 1)
        XCTAssertEqual(CPUUsageCalculator.usage(previous: ticks, current: ticks), 0)
    }
}
```

- [ ] **Step 2: Write network delta tests**

Create `magicStateCoreTests/NetworkDeltaTests.swift`:

```swift
import XCTest
@testable import MagicStateCore

final class NetworkDeltaTests: XCTestCase {
    func testNetworkSpeedFromCounterDelta() {
        let previous = NetworkCounters(receivedBytes: 1_000, sentBytes: 2_000, timestamp: 10)
        let current = NetworkCounters(receivedBytes: 3_000, sentBytes: 2_500, timestamp: 12)

        let speed = NetworkSpeedCalculator.speed(previous: previous, current: current)

        XCTAssertEqual(speed.downloadBytesPerSecond, 1_000)
        XCTAssertEqual(speed.uploadBytesPerSecond, 250)
    }

    func testNetworkSpeedReturnsZeroForInvalidInterval() {
        let previous = NetworkCounters(receivedBytes: 1_000, sentBytes: 1_000, timestamp: 10)
        let current = NetworkCounters(receivedBytes: 2_000, sentBytes: 2_000, timestamp: 10)

        let speed = NetworkSpeedCalculator.speed(previous: previous, current: current)

        XCTAssertEqual(speed.downloadBytesPerSecond, 0)
        XCTAssertEqual(speed.uploadBytesPerSecond, 0)
    }
}
```

- [ ] **Step 3: Run delta tests to verify they fail**

Run:

```bash
swift test --filter DeltaTests
```

Expected: FAIL because the CPU and network calculator types do not exist yet.

- [ ] **Step 4: Add CPU reader and calculator**

Create `magicState/Core/Readers/CPUReader.swift`:

```swift
import Foundation
import Darwin.Mach

public struct CPUTicks: Equatable, Sendable {
    public var user: UInt64
    public var system: UInt64
    public var idle: UInt64
    public var nice: UInt64

    public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }
}

public enum CPUUsageCalculator {
    public static func usage(previous: CPUTicks, current: CPUTicks) -> Double {
        let user = current.user.saturatingSubtract(previous.user)
        let system = current.system.saturatingSubtract(previous.system)
        let idle = current.idle.saturatingSubtract(previous.idle)
        let nice = current.nice.saturatingSubtract(previous.nice)
        let total = user + system + idle + nice

        guard total > 0 else { return 0 }
        return Double(user + system + nice) / Double(total)
    }
}

public final class CPUReader {
    private var previousTicks: CPUTicks?

    public init() {}

    public func read() -> CPUMetric? {
        guard let current = Self.readTicks() else { return nil }
        defer { previousTicks = current }

        guard let previousTicks else {
            return CPUMetric(usage: 0)
        }

        return CPUMetric(usage: CPUUsageCalculator.usage(previous: previousTicks, current: current))
    }

    private static func readTicks() -> CPUTicks? {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        var processorCount: natural_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount, &cpuInfo, &cpuInfoCount)
        guard result == KERN_SUCCESS, let cpuInfo else { return nil }

        defer {
            let size = vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), size)
        }

        var user: UInt64 = 0
        var system: UInt64 = 0
        var idle: UInt64 = 0
        var nice: UInt64 = 0

        for cpuIndex in 0..<Int(processorCount) {
            let offset = cpuIndex * Int(CPU_STATE_MAX)
            user += UInt64(cpuInfo[offset + Int(CPU_STATE_USER)])
            system += UInt64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            idle += UInt64(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            nice += UInt64(cpuInfo[offset + Int(CPU_STATE_NICE)])
        }

        return CPUTicks(user: user, system: system, idle: idle, nice: nice)
    }
}

private extension UInt64 {
    func saturatingSubtract(_ other: UInt64) -> UInt64 {
        self >= other ? self - other : 0
    }
}
```

- [ ] **Step 5: Add network reader and calculator**

Create `magicState/Core/Readers/NetworkReader.swift`:

```swift
import Foundation
import Darwin

public struct NetworkCounters: Equatable, Sendable {
    public var receivedBytes: UInt64
    public var sentBytes: UInt64
    public var timestamp: TimeInterval

    public init(receivedBytes: UInt64, sentBytes: UInt64, timestamp: TimeInterval) {
        self.receivedBytes = receivedBytes
        self.sentBytes = sentBytes
        self.timestamp = timestamp
    }
}

public enum NetworkSpeedCalculator {
    public static func speed(previous: NetworkCounters, current: NetworkCounters) -> NetworkMetric {
        let interval = current.timestamp - previous.timestamp
        guard interval > 0 else {
            return NetworkMetric(uploadBytesPerSecond: 0, downloadBytesPerSecond: 0)
        }

        let receivedDelta = current.receivedBytes >= previous.receivedBytes ? current.receivedBytes - previous.receivedBytes : 0
        let sentDelta = current.sentBytes >= previous.sentBytes ? current.sentBytes - previous.sentBytes : 0

        return NetworkMetric(
            uploadBytesPerSecond: UInt64(Double(sentDelta) / interval),
            downloadBytesPerSecond: UInt64(Double(receivedDelta) / interval)
        )
    }
}

public final class NetworkReader {
    private var previousCounters: NetworkCounters?

    public init() {}

    public func read() -> NetworkMetric? {
        guard let current = Self.readCounters() else { return nil }
        defer { previousCounters = current }

        guard let previousCounters else {
            return NetworkMetric(uploadBytesPerSecond: 0, downloadBytesPerSecond: 0)
        }

        return NetworkSpeedCalculator.speed(previous: previousCounters, current: current)
    }

    private static func readCounters() -> NetworkCounters? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let firstInterface = interfaces else { return nil }
        defer { freeifaddrs(interfaces) }

        var received: UInt64 = 0
        var sent: UInt64 = 0
        var pointer: UnsafeMutablePointer<ifaddrs>? = firstInterface

        while let current = pointer {
            let interface = current.pointee
            let flags = Int32(interface.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK

            if isUp, !isLoopback, interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK),
               let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                received += UInt64(data.pointee.ifi_ibytes)
                sent += UInt64(data.pointee.ifi_obytes)
            }

            pointer = interface.ifa_next
        }

        return NetworkCounters(receivedBytes: received, sentBytes: sent, timestamp: Date().timeIntervalSince1970)
    }
}
```

- [ ] **Step 6: Run delta tests**

Run:

```bash
swift test --filter CPUDeltaTests
swift test --filter NetworkDeltaTests
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add magicState/Core/Readers/CPUReader.swift magicState/Core/Readers/NetworkReader.swift magicStateCoreTests/CPUDeltaTests.swift magicStateCoreTests/NetworkDeltaTests.swift
git commit -m "Add CPU and network sampling logic"
```

## Task 4: Add Remaining Readers and Composed Service

**Files:**
- Create: `magicState/Core/Readers/MemoryReader.swift`
- Create: `magicState/Core/Readers/DiskReader.swift`
- Create: `magicState/Core/Readers/BatteryReader.swift`
- Create: `magicState/Core/Readers/SensorReader.swift`
- Modify: `magicState/Core/SystemMonitorService.swift`

- [ ] **Step 1: Add reader protocols and concrete service**

Modify `magicState/Core/SystemMonitorService.swift` by appending these protocols and service implementation:

```swift
public protocol CPUReading: Sendable { func read() -> CPUMetric? }
public protocol MemoryReading: Sendable { func read() -> MemoryMetric? }
public protocol DiskReading: Sendable { func read() -> DiskMetric? }
public protocol NetworkReading: Sendable { func read() -> NetworkMetric? }
public protocol BatteryReading: Sendable { func read() -> BatteryMetric? }
public protocol SensorReading: Sendable { func read() -> SensorMetric? }

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
```

- [ ] **Step 2: Add memory reader**

Create `magicState/Core/Readers/MemoryReader.swift`:

```swift
import Foundation
import Darwin.Mach

public final class MemoryReader: MemoryReading {
    public init() {}

    public func read() -> MemoryMetric? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = active + inactive + wired + compressed
        let total = ProcessInfo.processInfo.physicalMemory

        return MemoryMetric(usedBytes: min(used, total), totalBytes: total)
    }
}
```

- [ ] **Step 3: Add disk reader**

Create `magicState/Core/Readers/DiskReader.swift`:

```swift
import Foundation

public final class DiskReader: DiskReading {
    public init() {}

    public func read() -> DiskMetric? {
        do {
            let values = try URL(fileURLWithPath: "/").resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])

            guard let total = values.volumeTotalCapacity else { return nil }
            let available = values.volumeAvailableCapacityForImportantUsage ?? Int64(0)
            let totalBytes = UInt64(max(total, 0))
            let availableBytes = UInt64(max(available, 0))
            let usedBytes = totalBytes >= availableBytes ? totalBytes - availableBytes : 0

            return DiskMetric(usedBytes: usedBytes, totalBytes: totalBytes)
        } catch {
            return nil
        }
    }
}
```

- [ ] **Step 4: Add battery reader**

Create `magicState/Core/Readers/BatteryReader.swift`:

```swift
import Foundation
import IOKit.ps

public final class BatteryReader: BatteryReading {
    public init() {}

    public func read() -> BatteryMetric? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return BatteryMetric(level: nil, isCharging: false)
        }

        let current = description[kIOPSCurrentCapacityKey] as? Int
        let max = description[kIOPSMaxCapacityKey] as? Int
        let state = description[kIOPSPowerSourceStateKey] as? String
        let isCharging = state == kIOPSACPowerValue

        guard let current, let max, max > 0 else {
            return BatteryMetric(level: nil, isCharging: isCharging)
        }

        return BatteryMetric(level: Double(current) / Double(max), isCharging: isCharging)
    }
}
```

- [ ] **Step 5: Add sensor reader with graceful unavailable state**

Create `magicState/Core/Readers/SensorReader.swift`:

```swift
import Foundation

public final class SensorReader: SensorReading {
    public init() {}

    public func read() -> SensorMetric? {
        SensorMetric(temperatureCelsius: nil, fanRPM: nil, isSupported: false)
    }
}
```

- [ ] **Step 6: Build tests and app**

Run:

```bash
swift test
xcodebuild -project magicState.xcodeproj -scheme magicState -destination 'platform=macOS' build
```

Expected: both commands PASS.

- [ ] **Step 7: Commit**

```bash
git add magicState/Core/SystemMonitorService.swift magicState/Core/Readers/MemoryReader.swift magicState/Core/Readers/DiskReader.swift magicState/Core/Readers/BatteryReader.swift magicState/Core/Readers/SensorReader.swift
git commit -m "Add system metric readers"
```

## Task 5: Build the SwiftUI Dashboard

**Files:**
- Create: `magicState/Views/MetricCardView.swift`
- Create: `magicState/Views/HistoryBarChart.swift`
- Modify: `magicState/ContentView.swift`
- Modify: `magicState/magicStateApp.swift`

- [ ] **Step 1: Add shared metric card**

Create `magicState/Views/MetricCardView.swift`:

```swift
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
```

- [ ] **Step 2: Add lightweight history chart**

Create `magicState/Views/HistoryBarChart.swift`:

```swift
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
```

- [ ] **Step 3: Replace starter content with dashboard layout**

Modify `magicState/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel(service: SystemMonitorService())

    private let columns = [
        GridItem(.adaptive(minimum: 230), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(viewModel.cards.enumerated()), id: \.offset) { index, metric in
                        MetricCardView(metric: metric) {
                            if metric.title == "CPU" {
                                HistoryBarChart(values: viewModel.cpuHistory)
                            } else {
                                Spacer(minLength: 48)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(minWidth: 760, minHeight: 520)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("magicState")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("Live Mac system dashboard")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 4: Set a practical default window size**

Modify `magicState/magicStateApp.swift`:

```swift
import SwiftUI

@main
struct magicStateApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 620)
    }
}
```

- [ ] **Step 5: Build app**

Run:

```bash
xcodebuild -project magicState.xcodeproj -scheme magicState -destination 'platform=macOS' build
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add magicState/Views/MetricCardView.swift magicState/Views/HistoryBarChart.swift magicState/ContentView.swift magicState/magicStateApp.swift
git commit -m "Build dashboard interface"
```

## Task 6: Final Verification and Learning Notes

**Files:**
- Modify: `docs/superpowers/specs/2026-05-30-magicstate-dashboard-design.md` only if implementation discovers a real spec correction.

- [ ] **Step 1: Run full test suite**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 2: Run app build**

Run:

```bash
xcodebuild -project magicState.xcodeproj -scheme magicState -destination 'platform=macOS' build
```

Expected: PASS.

- [ ] **Step 3: Launch the built app manually**

Run:

```bash
open "$(find ~/Library/Developer/Xcode/DerivedData -path '*/Build/Products/Debug/magicState.app' -print -quit)"
```

Expected: A macOS window opens with six dashboard cards. CPU history should begin filling after the second sample. Sensors may show `Not supported` on the Apple M1 machine.

- [ ] **Step 4: Check repository status**

Run:

```bash
git status --short
```

Expected: clean working tree after the final commit.

## Self-Review

- Spec coverage: The plan covers dashboard UI, real CPU, memory, disk, network, battery data, optional sensors, service/view-model separation, refresh timing, graceful unavailable states, and test coverage for formatters and delta logic.
- Placeholder scan: No task uses placeholder language; each code step includes concrete file content or concrete modifications.
- Type consistency: `SystemSnapshot`, `MetricDisplay`, `DashboardViewModel`, reader protocols, and calculator names are introduced before later tasks use them.

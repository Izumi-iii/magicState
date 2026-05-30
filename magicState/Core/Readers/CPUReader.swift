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

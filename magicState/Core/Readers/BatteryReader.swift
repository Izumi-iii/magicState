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

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

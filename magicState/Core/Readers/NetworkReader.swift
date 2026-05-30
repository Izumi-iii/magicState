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

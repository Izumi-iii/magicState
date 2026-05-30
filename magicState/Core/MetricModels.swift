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

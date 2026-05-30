import Foundation

public struct CPUHistorySummary: Equatable, Sendable {
    public let current: Double
    public let average: Double
    public let peak: Double

    public init(values: [Double]) {
        guard !values.isEmpty else {
            self.current = 0
            self.average = 0
            self.peak = 0
            return
        }

        self.current = values.last ?? 0
        self.average = values.reduce(0, +) / Double(values.count)
        self.peak = values.max() ?? 0
    }
}

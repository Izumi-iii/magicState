import Foundation

public final class SensorReader: SensorReading {
    public init() {}

    public func read() -> SensorMetric? {
        SensorMetric(temperatureCelsius: nil, fanRPM: nil, isSupported: false)
    }
}

import Foundation

public final class SensorReader: SensorReading {
    public init() {}

    public func read() -> SensorMetric? {
        SensorMetric(
            temperatureCelsius: nil,
            fanRPM: nil,
            thermalState: Self.mapThermalState(ProcessInfo.processInfo.thermalState),
            isSupported: true
        )
    }

    public static func mapThermalState(_ state: ProcessInfo.ThermalState) -> ThermalState {
        switch state {
        case .nominal:
            .nominal
        case .fair:
            .fair
        case .serious:
            .serious
        case .critical:
            .critical
        @unknown default:
            .unknown
        }
    }
}

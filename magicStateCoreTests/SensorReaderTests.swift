import Foundation
import XCTest
@testable import MagicStateCore

final class SensorReaderTests: XCTestCase {
    func testMapsFoundationThermalStates() {
        XCTAssertEqual(SensorReader.mapThermalState(.nominal), .nominal)
        XCTAssertEqual(SensorReader.mapThermalState(.fair), .fair)
        XCTAssertEqual(SensorReader.mapThermalState(.serious), .serious)
        XCTAssertEqual(SensorReader.mapThermalState(.critical), .critical)
    }
}

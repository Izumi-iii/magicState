# Public Sensors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display macOS public thermal state in the Sensors card without using private SMC APIs.

**Architecture:** Add a `ThermalState` enum to core models, map `ProcessInfo.ThermalState` in `SensorReader`, and format it in `DashboardViewModel`. Keep Celsius and fan fields available but empty for this public API implementation.

**Tech Stack:** Swift 5, Foundation `ProcessInfo.thermalState`, SwiftUI, XCTest, existing SwiftPM core test harness.

---

## File Structure

- Modify `magicState/Core/SystemMonitorService.swift`: add `ThermalState` and extend `SensorMetric`.
- Modify `magicState/Core/Readers/SensorReader.swift`: map public Foundation thermal state.
- Modify `magicState/Core/DashboardViewModel.swift`: display thermal state in the Sensors card.
- Modify `magicStateCoreTests/SystemMonitorServiceTests.swift`: update default reader expectation.
- Modify `magicStateCoreTests/DashboardViewModelTests.swift`: assert Sensors card displays thermal state.
- Create `magicStateCoreTests/SensorReaderTests.swift`: verify thermal-state mapping.

## Task 1: Model and Mapping

- [ ] **Step 1: Write failing mapping tests**

Create `magicStateCoreTests/SensorReaderTests.swift` with tests asserting `SensorReader.mapThermalState(.nominal) == .nominal`, `.fair == .fair`, `.serious == .serious`, and `.critical == .critical`.

- [ ] **Step 2: Run the mapping test**

Run `swift test --filter SensorReaderTests`.

Expected: FAIL because `ThermalState` and `mapThermalState` do not exist.

- [ ] **Step 3: Add `ThermalState` and mapping implementation**

Add `ThermalState` to `SystemMonitorService.swift`, add `thermalState` to `SensorMetric`, and implement `SensorReader.mapThermalState(_:)`.

- [ ] **Step 4: Run the mapping test again**

Run `swift test --filter SensorReaderTests`.

Expected: PASS.

## Task 2: UI Formatting

- [ ] **Step 1: Write failing ViewModel test**

Update `DashboardViewModelTests` so the sample Sensors card expects value `Nominal` when the snapshot contains `thermalState: .nominal`.

- [ ] **Step 2: Run ViewModel tests**

Run `swift test --filter DashboardViewModelTests`.

Expected: FAIL because `sensorCard` still prefers Celsius temperature or unsupported display.

- [ ] **Step 3: Format thermal state in the Sensors card**

Update `DashboardViewModel.sensorCard(_:)` so public thermal states render as the primary value, with detail `Public thermal state`.

- [ ] **Step 4: Run ViewModel tests again**

Run `swift test --filter DashboardViewModelTests`.

Expected: PASS.

## Task 3: Default Reader and App Verification

- [ ] **Step 1: Update default reader test**

Update `SystemMonitorServiceTests.testDefaultSensorReaderReportsUnsupported` to expect `isSupported == true`, non-nil `thermalState`, and nil Celsius/fan values.

- [ ] **Step 2: Run full tests**

Run `swift test`.

Expected: PASS.

- [ ] **Step 3: Build app**

Run `xcodebuild -project magicState.xcodeproj -scheme magicState -destination 'platform=macOS' build`.

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

Commit the spec, plan, tests, and implementation with message `Show public thermal state`.

## Self-Review

- Spec coverage: The plan covers public thermal state, excludes Celsius body temperature, keeps future Celsius/fan fields, and updates tests.
- Placeholder scan: No placeholders or unfinished instructions.
- Type consistency: `ThermalState`, `thermalState`, `SensorReader.mapThermalState`, and `DashboardViewModel.sensorCard` names are used consistently.

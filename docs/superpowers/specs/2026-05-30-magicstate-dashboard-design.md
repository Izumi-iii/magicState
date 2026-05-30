# magicState Dashboard Design

Date: 2026-05-30
Status: Approved for planning

## Goal

Build the first version of `magicState` as a native macOS SwiftUI dashboard for learning macOS development through real system monitoring.

The app should prioritize real system data over visual completeness. It should still look like a usable desktop utility, but the main learning value is connecting SwiftUI state to macOS system APIs.

## Scope

The first version is an independent dashboard window, not a menu bar app.

Included metrics:

- CPU usage with recent history.
- Memory usage.
- Disk capacity and usage.
- Network upload and download speed.
- Battery level and charging state when available.
- Temperature and fan status as optional experimental sensors.

Temperature and fan data are allowed to be unavailable on Apple Silicon or unsupported machines. The UI must reserve a place for them and show a clear unavailable state when the reader cannot produce data.

Out of scope for this version:

- App Store polish and marketing screenshots.
- Menu bar extras.
- Login item support.
- Privileged helpers.
- User-configurable themes.
- Exact cloning of the original State app.

## Architecture

Use three layers.

### SwiftUI Views

`ContentView` owns the dashboard layout and composes metric cards. Views only read observable state and render it.

Views should not call macOS system APIs directly.

Expected view structure:

- `ContentView`: window-level layout.
- `MetricCardView`: shared card shell.
- Metric-specific content views for CPU, memory, disk, network, battery, and sensors if the layout becomes too dense.

### Dashboard View Model

`DashboardViewModel` owns refresh timing, latest snapshots, CPU history, formatting, and unavailable/error display state.

Responsibilities:

- Start and stop periodic sampling.
- Keep a bounded history for values that need charts.
- Convert raw byte counts, percentages, and speeds into display strings.
- Preserve the rest of the dashboard when one reader fails.

### System Monitoring Services

`SystemMonitorService` coordinates specialized readers:

- `CPUReader`
- `MemoryReader`
- `DiskReader`
- `NetworkReader`
- `BatteryReader`
- `SensorReader`

Each reader should have a narrow protocol so the view model can be tested with mock readers.

## Data Flow

System APIs are read by specialized readers. `SystemMonitorService` combines the reader outputs into a single snapshot. `DashboardViewModel` periodically requests a snapshot, updates published state, and SwiftUI re-renders the dashboard.

Flow:

```text
macOS APIs -> Metric readers -> SystemMonitorService -> DashboardViewModel -> SwiftUI views
```

## Metric Strategy

CPU should use stable macOS host APIs and compare samples over time to compute active usage.

Memory should read VM statistics and physical memory size.

Disk should use file system volume capacity and available capacity for the main system volume.

Network should sample interface byte counters and compute speed from deltas between refreshes.

Battery should use IOKit power source information where available. Desktop Macs without a battery should show an unavailable state.

Temperature and fan readings should be implemented behind `SensorReader` as an optional experiment. Failure is expected and must not be treated as an app-level error.

## Refresh Behavior

Use a periodic refresh interval appropriate for a desktop dashboard. Start with one sample per second for CPU and network, while avoiding unnecessary UI work by updating all visible metrics through one snapshot pipeline.

CPU and network need previous samples to calculate deltas. Other metrics can use current values.

## Error Handling

Stable metrics should show `--` if a read fails. If there is a previous valid value, the UI may keep it briefly while marking the metric stale.

Optional sensors should show `Not supported` or the Chinese equivalent in the UI. Sensor failure must not stop the dashboard refresh loop.

The service layer should return structured unavailable states instead of throwing errors into SwiftUI views.

## Testing

Unit tests should focus on the view model and formatting logic.

Reader protocols should allow mock snapshots for:

- Successful refresh.
- Partial reader failure.
- Sensor unavailable.
- CPU and network delta calculation.

Manual verification should confirm that the app builds and that the dashboard shows live values on the current Apple M1 machine running macOS 15.6.1.

## Learning Outcomes

This version should teach:

- How a SwiftUI macOS app is structured.
- How observable state drives native UI.
- How to separate UI from platform APIs.
- How to call macOS APIs from Swift.
- How periodic sampling and delta-based metrics work.
- How to design graceful degradation for hardware-dependent features.

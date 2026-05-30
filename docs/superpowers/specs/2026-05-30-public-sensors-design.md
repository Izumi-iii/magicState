# Public Sensors Design

Date: 2026-05-30
Status: Approved for implementation

## Goal

Improve the Sensors card using only public macOS APIs.

## Scope

The app will not display body temperature in Celsius because macOS does not expose a public, stable body-temperature API. Instead, it will display `ProcessInfo.processInfo.thermalState`, which reports the system thermal pressure level.

The Sensors card should show:

- `Nominal` for normal thermal pressure.
- `Fair` for mild thermal pressure.
- `Serious` for high thermal pressure.
- `Critical` for critical thermal pressure.
- `Unknown` for future or unmapped states.

The detail text should explain that this is public thermal state, not SMC temperature.

## Architecture

Add a project-owned `ThermalState` enum rather than storing `ProcessInfo.ThermalState` directly in app state. `SensorReader` maps the public Foundation enum to this project enum. `DashboardViewModel` formats the enum into the Sensors card.

Keep `temperatureCelsius` and `fanRPM` fields for future non-public experiments, but leave them empty in the public API path.

## Error Handling

`ProcessInfo.thermalState` is always available on supported macOS versions. The reader should mark sensors as supported when thermal state is available, even if Celsius temperature and fan RPM are unavailable.

Unknown future Foundation cases should map to `ThermalState.unknown`.

## Tests

Add tests for:

- Foundation thermal state mapping.
- Sensors card display for a nominal thermal state.
- Default `SensorReader` returning a supported thermal state.


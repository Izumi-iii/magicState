# magicState macOS Menu Bar Monitor Learning Log

## Session Goal

本次练习的目标是复刻一个类似 State 的 Mac 系统状态工具，用来学习 macOS 开发。最终方向从普通窗口 Dashboard 演进成纯菜单栏工具：启动后不显示 Dock 图标，菜单栏实时显示 `CPU xx%  RAM yy%`，点击后弹出小面板，并可按需打开完整仪表盘。

## Project Context

项目是一个 SwiftUI macOS App：

- Xcode 项目：`magicState.xcodeproj`
- App 源码目录：`magicState/`
- 可测试核心模块：`Package.swift` 暴露 `MagicStateCore`
- 测试目录：`magicStateCoreTests/`

核心架构分成三层：

- Reader 层：读取 CPU、内存、磁盘、网络、电池、公开 thermal state。
- ViewModel 层：`DashboardViewModel` 定时采样并映射成 UI 需要的卡片数据。
- UI 层：`MenuBarExtra` 菜单栏入口、菜单栏小面板、按需打开的 Dashboard 窗口。

## What Changed

### 1. 系统指标读取

相关文件：

- `magicState/Core/SystemMonitorService.swift`
- `magicState/Core/Readers/CPUReader.swift`
- `magicState/Core/Readers/MemoryReader.swift`
- `magicState/Core/Readers/DiskReader.swift`
- `magicState/Core/Readers/NetworkReader.swift`
- `magicState/Core/Readers/BatteryReader.swift`
- `magicState/Core/Readers/SensorReader.swift`

项目把不同系统指标拆成多个 Reader，再由 `SystemMonitorService` 聚合成一个 `SystemSnapshot`。这样 UI 不需要知道 CPU 或网络数据来自哪个底层 API，只依赖统一模型。

关键思想：

```swift
public protocol SystemMonitoring {
    func snapshot() async throws -> SystemSnapshot
}
```

这个协议让 `DashboardViewModel` 可以依赖抽象服务，也方便测试时注入假的 service。

### 2. Sensors 采用公开 API

用户明确要求保持公开 API 做法，所以 Sensors 没有读取私有 SMC 温度或风扇数据，而是使用：

```swift
ProcessInfo.processInfo.thermalState
```

这能显示系统热状态，例如 `Nominal`、`Fair`、`Serious`、`Critical`。它不是具体机身温度，但属于 App Store 友好的公开能力。

相关文件：

- `magicState/Core/Readers/SensorReader.swift`
- `magicStateCoreTests/SensorReaderTests.swift`

### 3. 纯菜单栏模式

相关文件：

- `magicState/magicStateApp.swift`
- `magicState/AppModel.swift`
- `magicState/DashboardWindowController.swift`
- `magicState/Views/MenuBarPanelView.swift`

App 入口从自动打开窗口改成 `MenuBarExtra`：

```swift
@main
struct magicStateApp: App {
    @StateObject private var appModel = AppModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra(appModel.menuBarTitle, systemImage: "waveform.path.ecg") {
            MenuBarPanelView(
                viewModel: appModel.dashboardViewModel,
                openDashboard: appModel.openDashboard,
                quit: appModel.quit
            )
        }
        .menuBarExtraStyle(.window)
    }
}
```

这里学到两个 macOS AppKit / SwiftUI 混合点：

- `MenuBarExtra` 负责菜单栏入口和弹出面板。
- `NSApplication.shared.setActivationPolicy(.accessory)` 让 App 不出现在 Dock。

完整 Dashboard 没有删除，而是用 `DashboardWindowController` 按需创建 `NSWindow`。这避免了 `WindowGroup` 启动时自动弹出主窗口。

### 4. 共享 ViewModel

相关文件：

- `magicState/AppModel.swift`
- `magicState/Core/DashboardViewModel.swift`

菜单栏标题、小面板、Dashboard 复用同一个 `DashboardViewModel`。这个设计避免了多个视图各自采样系统指标，减少重复计时器，也保证显示一致。

```swift
let viewModel = DashboardViewModel(service: SystemMonitorService())
self.dashboardViewModel = viewModel
self.dashboardWindowController = DashboardWindowController(viewModel: viewModel)
```

菜单栏标题通过 Combine 监听 `cards`：

```swift
viewModel.$cards
    .map(MenuBarTitleFormatter.title)
    .removeDuplicates()
    .sink { [weak self] title in
        self?.menuBarTitle = title
    }
    .store(in: &cancellables)
```

### 5. CPU 30 分钟历史图表

相关文件：

- `magicState/Core/DashboardViewModel.swift`
- `magicState/Core/CPUHistorySummary.swift`
- `magicState/Views/HistoryBarChart.swift`
- `magicState/ContentView.swift`
- `magicState/Views/MenuBarPanelView.swift`

CPU 历史从短数组扩展为最多 1800 个采样点。当前刷新节奏是 1 秒一次，所以 1800 点约等于 30 分钟。

```swift
private static let cpuHistoryLimit = 1_800
```

采样策略：

- 只有成功读取 CPU 使用率时才追加历史。
- CPU 缺失或 service 失败时不追加。
- 超出 1800 点时删除最旧数据，只保留最近窗口。

图表用 SwiftUI `Path` 和 `GeometryReader` 实现，没有引入额外依赖。`CPUHistoryChartView` 同时画了：

- 网格线
- 80% 阈值虚线
- 面积渐变
- 趋势折线
- 当前点
- 空状态文本

### 6. 菜单栏图表与视觉优化

相关文件：

- `magicState/Views/MenuBarPanelView.swift`
- `magicState/Views/VisualDesign.swift`
- `magicState/Assets.xcassets/MenuPanelBackground.imageset/`

菜单栏面板加入了 CPU 小图表，并把用户提供的图片作为背景图：

```swift
Image("MenuPanelBackground")
    .resizable()
    .scaledToFill()
    .opacity(0.18)
    .saturation(0.9)
    .blur(radius: 0.6)
```

后续发现 CPU 图表区域的 `.thinMaterial` 会挡住背景图，于是改成透明状态色层：

```swift
.background {
    RoundedRectangle(cornerRadius: VisualDesign.cornerRadius, style: .continuous)
        .fill(VisualDesign.statusColor(for: cpuMetric).opacity(0.045))
}
```

这个调整保留了信息层次，但让背景图能隐约透出来。

## Key Concepts Learned

### SwiftUI App 不一定需要 WindowGroup

普通 macOS SwiftUI App 常见入口是 `WindowGroup`。但纯菜单栏工具更适合用 `MenuBarExtra` 作为主 Scene。窗口可以交给 AppKit 的 `NSWindowController` 按需管理。

### AppKit 仍然很重要

即使主 UI 用 SwiftUI，macOS 专属行为仍经常需要 AppKit：

- 隐藏 Dock 图标：`NSApplication.shared.setActivationPolicy(.accessory)`
- 打开独立窗口：`NSWindow`
- 激活应用：`NSApplication.shared.activate(ignoringOtherApps: true)`
- 退出应用：`NSApplication.shared.terminate(nil)`

### ViewModel 共享比多处采样更稳

菜单栏标题、菜单栏小面板、Dashboard 都要显示同一批数据。共享一个 `DashboardViewModel` 能避免重复采样和状态不一致。

### 图表可以先用 Path 实现

对学习项目来说，CPU 趋势线不需要马上引入图表库。`GeometryReader` 提供尺寸，`Path` 根据归一化后的 `[Double]` 生成点，就能画出可用的折线和面积图。

### 公开 API 的边界要明确

macOS 上读取真实机身温度和风扇转速通常会涉及私有 SMC 接口。这个项目选择公开 API，因此 Sensors 展示的是 thermal state，不是具体温度。这个取舍更适合学习和分发。

## Code Walkthrough

### 数据模型

`SystemSnapshot` 是一次采样的完整结果：

```swift
public struct SystemSnapshot: Equatable, Sendable {
    public var cpu: CPUMetric?
    public var memory: MemoryMetric?
    public var disk: DiskMetric?
    public var network: NetworkMetric?
    public var battery: BatteryMetric?
    public var sensors: SensorMetric?
}
```

使用可选值的原因是每个指标都可能读取失败或不支持，UI 可以基于 `nil` 显示 `--` 或 `Not supported`。

### ViewModel 刷新

`DashboardViewModel` 每秒刷新一次：

```swift
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    Task { @MainActor in
        await self?.refreshOnce()
    }
}
```

它是 `@MainActor` 类型，因此更新 `@Published` 状态时更符合 SwiftUI 的主线程要求。

### 菜单栏标题

`MenuBarTitleFormatter` 专门负责标题格式：

```swift
return "CPU \(cpu)  RAM \(memory)"
```

这个小对象有单元测试，能保证 CPU 或内存缺失时回退到 `--`。

### Dashboard 与菜单栏面板

`ContentView` 是完整仪表盘，使用宽 CPU 卡片加网格指标卡：

- 顶部：CPU 当前值、30 分钟趋势、Current / Average / Peak。
- 下方：Memory、Disk、Network、Battery、Sensors。

`MenuBarPanelView` 是轻量面板：

- 固定宽度 360。
- 顶部显示标题。
- CPU 区域显示小图表。
- 其他指标用紧凑列表。
- 底部提供 `Open Dashboard` 和 `Quit`。

## Problems And Fixes

### 问题：启动后不应显示主窗口

症状：普通 SwiftUI `WindowGroup` 会让 App 启动时自动打开窗口。

修复：改用 `MenuBarExtra` 作为主 Scene，并用 `DashboardWindowController` 管理 Dashboard 窗口。

验证：启动后只在菜单栏出现，不自动弹出主窗口。

### 问题：想显示机身温度，但要保持公开 API

症状：公开 API 无法直接给出具体机身温度和风扇转速。

修复：使用 `ProcessInfo.processInfo.thermalState` 显示系统热状态，并在 UI 中标注为 `Public thermal state`。

验证：`SensorReaderTests` 覆盖 thermal state 映射。

### 问题：CPU 图表背景挡住菜单栏背景图

症状：CPU 图表区域使用 `.thinMaterial`，导致用户图片背景被盖住。

修复：去掉 material 背景，改为 4.5% 透明状态色填充和 22% 透明描边。

验证：`swift test` 通过，Xcode macOS build 成功。

## Validation

本次实现过程中实际使用过的验证命令：

```sh
swift test
```

结果：25 个 SwiftPM 测试通过。

```sh
xcodebuild -project magicState.xcodeproj -scheme magicState -destination 'platform=macOS' build
```

结果：`BUILD SUCCEEDED`。

覆盖到的测试重点：

- CPU delta 计算。
- 网络速度 delta 计算。
- 指标格式化。
- 菜单栏标题 fallback。
- CPU 30 分钟历史上限。
- service 失败时 dashboard 仍可显示。
- Sensors public thermal state 映射。
- 状态颜色 warning / critical / inactive 规则。

## Review Checklist

- 菜单栏标题是否简洁，不会太宽。
- 弹出面板是否能快速看出 CPU、Memory、Disk、Network、Battery、Sensors。
- Dashboard 是否只在点击 `Open Dashboard` 后出现。
- CPU 图表是否在数据不足时有空状态。
- 背景图片是否足够淡，不干扰文字可读性。
- Sensors 文案是否明确表达这是公开 thermal state，而不是具体温度。
- 新功能是否有测试覆盖核心逻辑，而不是只靠手动观察。

## Follow-Up Practice

1. 给菜单栏面板增加浅色 / 深色模式下不同的背景透明度。
2. 给 CPU 图表加悬停 tooltip，显示某个采样点的大致时间和使用率。
3. 给 Memory 也增加 30 分钟历史，但注意菜单栏不要过重。
4. 把 Dashboard 的窗口大小和位置保存到 `UserDefaults`。
5. 增加设置页，让用户选择菜单栏标题显示 CPU、RAM、网络或电池。
6. 继续保持公开 API 路线，研究哪些系统指标可以安全分发，哪些不适合。

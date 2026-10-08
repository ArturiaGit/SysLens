# SysLens 系统架构设计与技术实现 (ARCHITECTURE.md)

## 1. 系统总体架构与分层设计

SysLens 遵循严格的关注点分离与插件化微内核架构，共划分为三层物理架构：

```mermaid
graph TD
    subgraph Presentation ["1. 表现交互层 (WinUI 3 XAML / MVVM - Antigravity 专职)"]
        MainWindow["SysLens.App.MainWindow (Mica Window)"]
        NavHost["NavigationView 插件导航宿主"]
        PEView["ProcessExplorerView (上方进程树 + 下方多标签检查器)"]
        TitleBarWidget["自定义标题栏 (全局搜索 / 权限胶囊)"]
    end

    subgraph Contract ["2. 契约规范层 (SysLens.Sdk - 共同维护, 接口先行)"]
        IToolPlugin["IToolPlugin (插件生命周期契约)"]
        IPluginContext["IPluginContext (宿主服务上下文)"]
        IProcCollector["IProcessCollectorService (采样契约)"]
        IProcControl["IProcessControlService (进程控制契约)"]
        DTOs["不可变数据模型 (ProcessNode, ModuleInfo, HandleInfo, ThreadInfo)"]
    end

    subgraph CoreEngine ["3. 底层系统与核心引擎层 (PI-Desktop 专职)"]
        Loader["PluginLoader (AssemblyLoadContext 隔离加载)"]
        Elevation["ElevationService (Token 提权服务)"]
        Collector["ProcessCollectorService (后台周期性采样引擎)"]
        TreeBuilder["ProcessTreeBuilder (拓扑重构与环路检测)"]
        NativeWrapper["Win32 & NT Native P/Invoke 接口层"]
    end

    MainWindow --> NavHost
    MainWindow --> TitleBarWidget
    NavHost --> IToolPlugin
    PEView --> IProcCollector
    PEView --> IProcControl
    PEView --> DTOs

    Loader --> IToolPlugin
    Elevation --> IPluginContext
    Collector --> IProcCollector
    Collector --> TreeBuilder
    Collector --> NativeWrapper
```

---

## 2. 线程模型与多核异步采样时序

为确保 WinUI 3 界面在千量级进程环境下以 60 FPS 稳定流畅运行，SysLens 严格执行**后台工作线程采样**与**UI 调度队列合并派发**架构：

```mermaid
sequenceDiagram
    autonumber
    actor User as 用户界面 (UI Thread)
    participant VM as ProcessExplorerViewModel
    participant Dispatcher as DispatcherQueue
    participant Worker as Background Collector Thread (Task.Run)
    participant Native as Win32 / NT Native API

    Worker->>Worker: 定时器 Tick 触发 (周期 1000ms)
    Worker->>Native: CreateToolhelp32Snapshot / NtQuerySystemInfo
    Native-->>Worker: 返回原始进程列表与内核/用户态时间
    Worker->>Worker: 计算 CPU 增量: Delta(Kernel+User) / Delta(SysTime) / Cores
    Worker->>Worker: 构建不可变快照 ProcessSnapshot (树重构与孤儿节点收归)
    Worker->>Dispatcher: DispatcherQueue.TryEnqueue(UpdateSnapshotAction)
    Dispatcher->>User: 批量更新 UI 绑定数据源 (ObservableCollection)
    User->>User: 虚拟化网格增量重绘 (绿色新进程 / 红色退出进程淡出)
```

- **UI 线程保护准则**：UI 线程绝不直接执行耗时的 Win32 系统调用或遍历句柄，所有探测操作均在后台线程异步执行。
- **不可变快照派发**：每轮采样输出完整的只读 `ProcessSnapshot`，UI 绑定直接替换数据引用，彻底消除多线程并发读写共享集合的冲突与锁竞争。

---

## 3. 插件隔离加载架构 (`PluginLoader`)

```mermaid
graph LR
    subgraph Host ALC ["Host Default AssemblyLoadContext"]
        HostExe["SysLens.App.exe"]
        SdkDll["SysLens.Sdk.dll"]
        WinUIDll["Microsoft.WindowsAppSDK.dll"]
    end

    subgraph Plugin1 ALC ["PluginLoadContext 1 (ProcessExplorer)"]
        PEPlugin["SysLens.Tools.ProcessExplorer.dll"]
        PEDependency["专用分析工具依赖..."]
    end

    subgraph Plugin2 ALC ["PluginLoadContext 2 (Future Tool)"]
        FuturePlugin["SysLens.Tools.NetworkMonitor.dll"]
    end

    HostExe -->|扫描 Plugins/ 目录| Plugin1 ALC
    HostExe -->|扫描 Plugins/ 目录| Plugin2 ALC
    Plugin1 ALC -.->|共享引用| SdkDll
    Plugin2 ALC -.->|共享引用| SdkDll
```

- **自定义 `PluginLoadContext`**：
  - 继承自 `System.Runtime.Loader.AssemblyLoadContext`，指定 `isCollectible: true`；
  - 优先从宿主加载已加载的共享程序集（`SysLens.Sdk`），外部专属依赖则从插件子目录独立解析；
  - 杜绝不同插件引入不同版本的依赖库（如 Newtonsoft.Json vs System.Text.Json）产生程序集绑定冲突。

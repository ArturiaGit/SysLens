# 接口契约与协议规范 (API_AND_PROTOCOLS.md)

> **接口先行原则 (Interface-First Principle)**：
> 前端界面（`SysLens.App`）与底层系统引擎（`SysLens.Core` & `ProcessExplorer`）以本文档定义的标准化 C# 接口为**唯一交互契约**。
> 未经本文档定义并锁定的私有协议或实现类，严禁跨层调用！

---

## 1. 宿主与插件标准接口契约 (`SysLens.Sdk`)

### 1.1 `IToolPlugin`（工具插件通用生命周期契约）
每个小工具模块（如 Process Explorer、网络监控器）必须导出一个实现此接口的入口类：

```csharp
namespace SysLens.Sdk;

public interface IToolPlugin
{
    /// <summary>全局唯一插件标识符（如 "syslens.tool.process-explorer"）</summary>
    string Id { get; }

    /// <summary>展示名称（如 "Process Explorer"）</summary>
    string DisplayName { get; }

    /// <summary>功能简要说明</summary>
    string Description { get; }

    /// <summary>Segou Fluent 图标字形代码（如 "\uE756"）</summary>
    string IconGlyph { get; }

    /// <summary>插件语义化版本号（如 "0.1.0"）</summary>
    string Version { get; }

    /// <summary>工具分类标签（如 "System", "Network", "Diagnostics"）</summary>
    string Category { get; }

    /// <summary>插件初始化生命周期回调（由宿主在载入时异步调用）</summary>
    Task InitializeAsync(IPluginContext context, CancellationToken cancellationToken = default);

    /// <summary>插件卸载/退出生命周期回调（用于清理非托管资源、取消后台订阅）</summary>
    Task ShutdownAsync();

    /// <summary>创建并返回主界面视图实例（返回 WinUI 3 UIElement 对象）</summary>
    object CreateView();
}
```

### 1.2 `IPluginContext`（宿主向插件注入的服务上下文）
```csharp
namespace SysLens.Sdk;

public interface IPluginContext
{
    /// <summary>应用导航服务</summary>
    INavigationService Navigation { get; }

    /// <summary>Windows 权限与提权服务</summary>
    IElevationService Elevation { get; }

    /// <summary>应用通知与状态栏服务</summary>
    INotificationService Notification { get; }

    /// <summary>插件私有数据持久化存储根目录路径</summary>
    string StoragePath { get; }

    /// <summary>当前应用主题状态（深色/浅色）</summary>
    AppTheme CurrentTheme { get; }

    /// <summary>主题变更事件</summary>
    event EventHandler<AppTheme> ThemeChanged;
}
```

### 1.3 `IElevationService`（特权探测与提权服务）
```csharp
namespace SysLens.Sdk;

public interface IElevationService
{
    /// <summary>指示当前进程是否拥有管理员特权（高完整性级别）</summary>
    bool IsElevated { get; }

    /// <summary>当前进程的 Windows 用户账户名称（如 "DESKTOP-ABC\Admin"）</summary>
    string CurrentUserName { get; }

    /// <summary>尝试通过 UAC 以管理员权限重启当前宿主应用程序</summary>
    /// <param name="extraArgs">附加启动命令行参数</param>
    /// <returns>若用户取消 UAC 或提权失败返回 false</returns>
    bool RestartAsAdmin(string? extraArgs = null);
}
```

---

## 2. Process Explorer 引擎核心服务契约 (`SysLens.Sdk.Process`)

### 2.1 `IProcessCollectorService`（系统进程探查服务）
提供进程列表采样、差量计算与底层资源枚举能力：

```csharp
namespace SysLens.Sdk.Process;

public interface IProcessCollectorService
{
    /// <summary>
    /// 获取当前系统进程的完整快照，包含父子树状层级与性能指标增量
    /// </summary>
    /// <param name="cancellationToken">取消令牌</param>
    /// <returns>包含根进程集合与系统总体性能摘要的不可变快照</returns>
    Task<ProcessSnapshot> CaptureSnapshotAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// 枚举指定进程已加载的动态链接库 (DLL) 模块列表
    /// </summary>
    /// <param name="processId">目标进程 PID</param>
    /// <returns>只读模块列表；若无权限或已退出返回空集合与错误提示</returns>
    Task<ResourceResult<IReadOnlyList<ModuleInfo>>> GetModulesAsync(uint processId);

    /// <summary>
    /// 枚举指定进程已打开的系统内核对象句柄 (Handle) 列表
    /// </summary>
    /// <param name="processId">目标进程 PID</param>
    /// <returns>只读句柄列表</returns>
    Task<ResourceResult<IReadOnlyList<HandleInfo>>> GetHandlesAsync(uint processId);

    /// <summary>
    /// 枚举指定进程所属的活动线程 (Thread) 列表
    /// </summary>
    /// <param name="processId">目标进程 PID</param>
    /// <returns>只读线程列表</returns>
    Task<ResourceResult<IReadOnlyList<ThreadInfo>>> GetThreadsAsync(uint processId);
}
```

### 2.2 `IProcessControlService`（进程生命周期控制服务）
提供对进程的控制管理命令：

```csharp
namespace SysLens.Sdk.Process;

public interface IProcessControlService
{
    /// <summary>终止单个指定进程</summary>
    Task<OperationResult> TerminateProcessAsync(uint processId, uint exitCode = 1);

    /// <summary>递归终止指定进程及其所有子进程树</summary>
    Task<OperationResult> TerminateTreeAsync(uint processId);

    /// <summary>挂起（暂停）目标进程所有活动线程</summary>
    Task<OperationResult> SuspendProcessAsync(uint processId);

    /// <summary>恢复被挂起的目标进程线程执行</summary>
    Task<OperationResult> ResumeProcessAsync(uint processId);
}
```

---

## 3. 错误处理与响应模型规范 (`OperationResult`)

所有底层操作必须通过封装的 Result 类型返回，严禁将未处理的 Win32 `Win32Exception` 抛至 UI 线程：

```csharp
namespace SysLens.Sdk.Common;

public sealed record OperationResult(
    bool Success,
    string? Message = null,
    int ErrorCode = 0
)
{
    public static OperationResult Ok() => new(true);
    public static OperationResult Fail(string message, int errorCode = -1) => new(false, message, errorCode);
}

public sealed record ResourceResult<T>(
    bool Success,
    T? Data = default,
    string? ErrorMessage = null
)
{
    public static ResourceResult<T> Ok(T data) => new(true, data);
    public static ResourceResult<T> Fail(string error) => new(false, default, error);
}
```

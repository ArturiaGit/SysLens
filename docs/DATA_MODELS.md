# 数据模型字典与实体规范 (DATA_MODELS.md)

> **不可变性约束 (Immutability)**：
> 为确保多线程高频采样环境下 UI 渲染线程与后台采样线程的安全解耦，本文档定义的所有核心数据模型均为**不可变记录类型 (C# `record` / `IReadOnlyList`)**。
> 采集器每轮循环生成新的快照对象，严禁在后台线程直接修改正在被 UI 绑定的旧模型实例属性。

---

## 1. 进程树核心模型 (`ProcessNode`)

```csharp
namespace SysLens.Sdk.Process.Models;

public sealed record ProcessNode
{
    /// <summary>进程唯一标识符 (Process ID)</summary>
    public required uint ProcessId { get; init; }

    /// <summary>创建该进程的父进程 PID（若父进程已消亡则保留历史值）</summary>
    public required uint ParentProcessId { get; init; }

    /// <summary>可执行映像文件名（如 "notepad.exe"）</summary>
    public required string ProcessName { get; init; }

    /// <summary>磁盘完整文件路径（如 "C:\Windows\System32\notepad.exe"，无权限时为 null）</summary>
    public string? ExecutablePath { get; init; }

    /// <summary>启动命令行完整参数（包含启动开关与目标文件）</summary>
    public string? CommandLine { get; init; }

    /// <summary>文件厂商信息（如 "Microsoft Corporation"）</summary>
    public string? CompanyName { get; init; }

    /// <summary>文件产品描述（如 "Notepad"）</summary>
    public string? Description { get; init; }

    /// <summary>运行身份所属用户名（如 "NT AUTHORITY\SYSTEM" 或 "DESKTOP-X\User"）</summary>
    public string? UserName { get; init; }

    /// <summary>Windows 完整性级别（Low, Medium, High, System）</summary>
    public ProcessIntegrityLevel IntegrityLevel { get; init; } = ProcessIntegrityLevel.Unknown;

    /// <summary>当前采样周期的性能指标</summary>
    public required ProcessPerformanceMetrics Metrics { get; init; }

    /// <summary>进程生命周期标记（用于 UI 增量着色高亮）</summary>
    public ProcessLifecycleState LifecycleState { get; init; } = ProcessLifecycleState.Normal;

    /// <summary>该进程创建的所有活动子进程集合（用于树形网格递归展开）</summary>
    public IReadOnlyList<ProcessNode> Children { get; init; } = Array.Empty<ProcessNode>();

    /// <summary>指示是否属于 64 位原生进程架构</summary>
    public bool Is64Bit { get; init; } = true;
}

public enum ProcessLifecycleState
{
    Normal,         // 正常运行
    NewSpawned,     // 本周期新创建（UI 呈现淡绿色）
    Terminating,    // 即将消亡（UI 呈现淡红色）
    Suspended       // 已被挂起（UI 呈现灰色标识）
}

public enum ProcessIntegrityLevel
{
    Unknown,
    Untrusted,
    Low,
    Medium,
    High,
    System,
    Protected
}
```

---

## 2. 性能采样指标模型 (`ProcessPerformanceMetrics`)

```csharp
namespace SysLens.Sdk.Process.Models;

public sealed record ProcessPerformanceMetrics
{
    /// <summary>归一化多核 CPU 使用率百分比（0.0% ~ 100.0%）</summary>
    public required double CpuPercent { get; init; }

    /// <summary>专用工作集内存字节数 (Private Working Set，单位：字节)</summary>
    public required ulong WorkingSetBytes { get; init; }

    /// <summary>内存提交大小 (Commit Charge，单位：字节)</summary>
    public required ulong CommitChargeBytes { get; init; }

    /// <summary>当前进程持有的系统句柄总数</summary>
    public required uint HandleCount { get; init; }

    /// <summary>当前进程所属的活动线程总数</summary>
    public required uint ThreadCount { get; init; }

    /// <summary>采样周期内 I/O 读速率（字节/秒）</summary>
    public ulong IoReadBytesPerSec { get; init; }

    /// <summary>采样周期内 I/O 写速率（字节/秒）</summary>
    public ulong IoWriteBytesPerSec { get; init; }
}
```

---

## 3. 全局系统快照模型 (`ProcessSnapshot`)

```csharp
namespace SysLens.Sdk.Process.Models;

public sealed record ProcessSnapshot
{
    /// <summary>快照捕获的 UTC 时间戳</summary>
    public required DateTime TimestampUtc { get; init; }

    /// <summary>顶层根进程节点集合（树结构的顶层列表）</summary>
    public required IReadOnlyList<ProcessNode> RootProcesses { get; init; }

    /// <summary>平铺的进程快速字典映射（PID -> ProcessNode）</summary>
    public required IReadOnlyDictionary<uint, ProcessNode> ProcessLookup { get; init; }

    /// <summary>系统整体 CPU 占用率百分比 (0.0% ~ 100.0%)</summary>
    public required double TotalCpuPercent { get; init; }

    /// <summary>系统已使用物理内存字节数</summary>
    public required ulong TotalMemoryUsedBytes { get; init; }

    /// <summary>系统总物理内存字节数</summary>
    public required ulong TotalMemoryInstalledBytes { get; init; }

    /// <summary>系统当前运行的活动进程总数</summary>
    public int TotalProcessCount => ProcessLookup.Count;
}
```

---

## 4. 下方联动详细信息模型 (Modules, Handles, Threads)

### 4.1 动态链接库模块 (`ModuleInfo`)
```csharp
namespace SysLens.Sdk.Process.Models;

public sealed record ModuleInfo
{
    /// <summary>模块文件名（如 "ntdll.dll"）</summary>
    public required string ModuleName { get; init; }

    /// <summary>模块内存加载基地址（十六进制字符串形式如 "0x7FFBC1200000"）</summary>
    public required string BaseAddressHex { get; init; }

    /// <summary>模块映像在虚拟内存中的大小（单位：字节）</summary>
    public required uint ModuleSizeBytes { get; init; }

    /// <summary>磁盘物理路径（如 "C:\Windows\System32\ntdll.dll"）</summary>
    public required string FilePath { get; init; }

    /// <summary>文件版本信息（如 "10.0.26100.1150"）</summary>
    public string? FileVersion { get; init; }

    /// <summary>文件厂商信息</summary>
    public string? CompanyName { get; init; }

    /// <summary>产品或模块描述说明</summary>
    public string? Description { get; init; }
}
```

### 4.2 系统内核句柄 (`HandleInfo`)
```csharp
namespace SysLens.Sdk.Process.Models;

public sealed record HandleInfo
{
    /// <summary>句柄整型数值（十六进制字符串形式如 "0x000001B4"）</summary>
    public required string HandleValueHex { get; init; }

    /// <summary>内核对象类型名称（如 "File", "Key", "Mutant", "Section", "Event", "Process", "Thread"）</summary>
    public required string ObjectType { get; init; }

    /// <summary>内核对象名称或文件/注册表绝对路径（若无名称或未解析则为 null）</summary>
    public string? ObjectName { get; init; }

    /// <summary>授予该句柄的访问权限掩码（十六进制字符串）</summary>
    public required string GrantedAccessHex { get; init; }
}
```

### 4.3 活动线程 (`ThreadInfo`)
```csharp
namespace SysLens.Sdk.Process.Models;

public sealed record ThreadInfo
{
    /// <summary>线程唯一标识符 (TID)</summary>
    public required uint ThreadId { get; init; }

    /// <summary>线程动态执行优先级 (0 ~ 31)</summary>
    public required int Priority { get; init; }

    /// <summary>基本优先级</summary>
    public required int BasePriority { get; init; }

    /// <summary>线程执行状态（如 "Running", "Waiting", "Ready", "Standby"）</summary>
    public required string State { get; init; }

    /// <summary>线程等待原因（若处于等待状态，如 "UserRequest", "Executive"）</summary>
    public string? WaitReason { get; init; }

    /// <summary>线程上下文切换累计次数</summary>
    public required ulong ContextSwitches { get; init; }

    /// <summary>线程起始函数入口地址（十六进制）</summary>
    public string? StartAddressHex { get; init; }
}
```

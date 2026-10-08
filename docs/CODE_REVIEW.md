# 代码审查与质量门禁规范 (CODE_REVIEW.md)

## 1. 核心审查哲学
在系统级工具箱开发中，低级内存错误、句柄泄漏与 UI 冻结是常见的高危隐患。所有代码合入主干前必须经过严格的人工与自动化代码审查（Code Review）。

---

## 2. P/Invoke 与底层 Native 审查核对表 (P/Invoke Checklist)

1. **句柄生命周期绝对闭合**：
   - 检查每一个 `OpenProcess`、`CreateToolhelp32Snapshot`、`DuplicateHandle` 是否配对使用了 `CloseHandle`。
   - 优先推荐使用 .NET 原生 `Microsoft.Win32.SafeHandles.SafeProcessHandle` 或自定义 `SafeHandleZeroOrMinusOneIsInvalid`，禁止裸用 `IntPtr` 裸指传递。
2. **非托管内存安全释放**：
   - 所有 `Marshal.AllocHGlobal` 或 `Marshal.AllocCoTaskMem` 必须紧邻 `try ... finally` 块，在 `finally` 中严格释放。
3. **命名管道同步挂死防御 (Named Pipe Deadlock Defense)**：
   - 当遍历进程句柄调用 `NtQueryObject(ObjectNameInformation)` 时，若遇到挂起的命名管道句柄，调用线程会被内核永久无响应挂死。
   - **审查红线**：禁止在主采集线程盲目直接调用 `NtQueryObject`，必须在配备超时中断（Watchdog）的独立后台工作线程中探查，或依据句柄类型预先跳过高危管道。
4. **错误码与非托管异常映射**：
   - Win32 API 失败时，必须捕获 `Marshal.GetLastWin32Error()` 并封装为 `OperationResult.Fail()`，严禁将裸 `Win32Exception` 穿透至外部。

---

## 3. 性能与 UI 线程审查核对表 (Performance & UI)

1. **零 UI 同步阻塞**：
   - 严禁在 UI 线程同步调用 `.Result`、`.Wait()` 或直接执行长时计算。
   - 严禁在 UI 事件处理函数中直接发起耗时的 P/Invoke 探查。
2. **GC 堆内存分配防抖 (GC Allocation Control)**：
   - 采集器以 1 秒频次循环执行，审查重点关注每轮循环是否分配大量临时对象。
   - 推荐使用 `ArrayPool<T>` 缓冲区重用或不可变结构体避免高频触发 Gen 2 GC。

---

## 4. 典型反模式黑名单 (Anti-Pattern Catalog)

| 反模式名称 | 表现与危害 | 正确应对方案 |
|---|---|---|
| **泄漏的句柄 (The Leaky Handle)** | 调用 `OpenProcess` 获取句柄后发生异常，导致 `CloseHandle` 被跳过，系统总句柄数飙升 | 包装为 `using var handle = ...` 或在 `finally` 块中调用 `CloseHandle` |
| **冰冻的界面 (The UI Freezer)** | 在 XAML 按钮点击事件中同步等待枚举所有系统句柄 | 采用 `async/await`，后台线程完成后派发给 `DispatcherQueue` |
| **内存雪崩 (The GC Churner)** | 每秒为 500 个进程重复创建全新的复杂视图对象 | 保持数据模型不可变，通过轻量级 DTO 刷新绑定的属性，列表复用 |
| **环形父子死循环 (The Circular Parent)** | 恶意/异常进程将自己设为父进程，树遍历算法递归溢出 Crash | 树重构算法中引入 `HashSet<uint> visited` 环路检测，发现成环强行挂在根部 |
| **静默越权假设 (The Privilege Assumer)** | 假定当前进程一定具备 SeDebugPrivilege，对拒绝访问未捕获直接 Crash | 任何打开进程操作必须优雅处理 `ERROR_ACCESS_DENIED`，标记为受限并提示提权 |

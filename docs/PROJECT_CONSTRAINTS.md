# SysLens 安全与项目约束规范 (PROJECT_CONSTRAINTS.md)

## 1. 系统底层与操作系统安全约束
1. **系统关键进程保护**：
   - 严禁对系统关键进程（如 PID 0 `System Idle Process`, PID 4 `System`, `smss.exe`, `csrss.exe`, `lsass.exe`, `wininit.exe`）执行无保护的强杀、挂起操作。
   - 界面上对关键系统进程必须提供醒目的警示标记，并在尝试结束时弹出二次确认高危警告模态框。
2. **提权最小化与明确提示**：
   - 应用默认以普通用户完整性级别（Medium Integrity Level）启动。
   - 涉及读取特权系统进程详细句柄或修改进程状态时，界面提示用户通过“以管理员权限重启”获得特权，绝不采用暗默隐式提权。
3. **P/Invoke 句柄泄漏防御**：
   - 所有调用 `OpenProcess`、`DuplicateHandle` 或 `CreateToolhelp32Snapshot` 打开的 Windows 原生句柄（IntPtr / SafeHandle），必须通过 `using` 块或 `SafeProcessHandle` 严格释放，严禁在采集循环中造成句柄泄漏。
4. **命名管道与 NtQueryObject 挂死防御 (Deadlock Prevention)**：
   - 在枚举进程句柄调用 `NtQueryObject(ObjectNameInformation)` 时，若句柄为挂起的同步命名管道（Synchronous Named Pipe），线程可能会被永久阻塞挂死。
   - **强制要求**：句柄名称解析必须在具备超时控制的独立工作线程中执行，或跳过已知高危挂死类型的对象。

---

## 2. 工程与性能红线
1. **高刷新率防抖与性能开销**：
   - 进程数据采集周期默认为 1000ms（可调 500ms / 2000ms / 暂停）。
   - 每次采样计算必须在后台线程（`Task.Run` / 专用后台线程）完成，仅将已格式化的不可变数据快照派发到 UI 调度线程（`DispatcherQueue`）。
   - 严禁在 UI 线程同步调用耗时的 P/Invoke 接口导致界面冻结。
2. **内存占用控制**：
   - 采集器禁止在每轮循环中无节制分配大型临时数组，应尽可能重用缓冲区，避免频繁触发 GC Gen2 回收。

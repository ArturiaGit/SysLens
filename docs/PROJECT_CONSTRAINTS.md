# 项目全局约束与系统安全红线 (PROJECT_CONSTRAINTS.md)

## 1. 系统底层与内核对象安全约束

### 1.1 关键系统进程保护与防崩溃红线 (BSOD Prevention)
Windows 操作系统中存在部分直接维系系统内核与会话子系统存活的特权进程：
- **受保护系统进程清单**：
  - PID 0: `System Idle Process`
  - PID 4: `System`
  - `smss.exe` (Session Manager Subsystem)
  - `csrss.exe` (Client/Server Runtime Subsystem)
  - `wininit.exe` (Windows Start-Up Application)
  - `lsass.exe` (Local Security Authority Subsystem Service)
  - `services.exe` (Services and Controller app)
- **强制约束准则**：
  1. 界面上针对上述进程必须标记系统盾牌图标与“系统关键核心”醒目标签。
  2. 即使在管理员特权下，用户尝试右键“终止”上述进程时，必须弹出双重确认模态弹窗（“强制终止此核心进程将导致 Windows 立即蓝屏崩溃重启，是否确定？”），且默认聚焦在“取消”按钮上。

### 1.2 命名管道与内核对象枚举挂死深度防御 (Deadlock Defense)
在 Windows 逆向排障工具中，句柄枚举导致进程永久挂起（Freeze）是最隐蔽的致命 Bug：
- **挂死机理**：
  - 当通过 `DuplicateHandle` 复制目标进程的句柄并调用 `NtQueryObject(ObjectNameInformation)` 时；
  - 若该句柄指向一个处于阻塞等待状态的**同步命名管道（Synchronous Named Pipe）**；
  - 内核驱动会在管道等待对端写入时无期限阻塞当前调用线程，导致调用线程永久挂死，无法响应任何超时与中断！
- **强制工程防御方案**：
  1. **类型预先过滤 (Type Filtering)**：先调用 `NtQueryObject(ObjectTypeInformation)` 获取对象类型，若类型为 `File`，通过 `GetFileType` 判断；若为 `FILE_TYPE_PIPE`，**坚决跳过**名称查询，直接标记为 `\Device\NamedPipe (Protected)`。
  2. **独立看门狗线程隔离 (Watchdog Worker)**：若必须探查，必须在专用的单次短寿命辅助工作线程中执行，并设定 50ms 超时阈值。一旦超时未返回，立即判定为挂死句柄并强行剥离放弃，绝不阻塞主收集线程！

### 1.3 P/Invoke 原生句柄泄漏防范 (Handle Leak Prevention)
- 每秒 1 次的采集循环若每次泄漏 1 个句柄，运行 1 小时即累积泄漏 3600 个句柄，导致操作系统句柄表耗尽。
- **强制约束准则**：
  - 严禁裸写 `IntPtr handle = OpenProcess(...)` 而未在 `finally` 块中关闭。
  - 所有 Win32 句柄必须封装为派生自 `SafeHandle` 的强类型托管包装类（如 `SafeProcessHandle`）。

---

## 2. 权限与 UAC 交互约束
1. **最小特权原则**：应用禁止默认强制要求以管理员权限启动，确保在企业域控及普通受限账户下可正常完成基础诊断。
2. **提权透明化**：任何涉及提权的操作必须经由用户显式点击，严禁静默进行后台权限提升尝试。
3. **命令行脱敏防注入**：解析目标进程命令行参数时，严禁将其直接拼接入 `Process.Start` 或外部 Shell，防止恶意构造的进程命令行导致本地命令注入风险。

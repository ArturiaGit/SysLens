# 部署、分发与提权运行指南 (DEPLOYMENT_GUIDE.md)

## 1. 目标分发形态：绿色便携版 (Portable Distribution)

SysLens 定位为随时随地可运行的高性能系统工具，优先提供免安装绿色压缩包形态：
- **自包含发布 (Self-Contained)**：目标机器无需预先安装 .NET 8 Runtime 或 Windows App SDK 安装包，所有必要运行时依赖打包于单目录内。
- **发布命令**：
  ```powershell
  dotnet publish src/SysLens.App/SysLens.App.csproj `
      -c Release `
      -r win-x64 `
      --self-contained true `
      -p:PublishSingleFile=false `
      -p:WindowsPackageType=None `
      -o dist/SysLens-win-x64
  ```

---

## 2. 应用程序清单与权限策略 (`app.manifest`)

### 2.1 基础权限策略：`asInvoker`
应用默认以当前启动用户的权限级别运行，**不直接**在 Manifest 中声明 `requireAdministrator`：
```xml
<security>
  <requestedPrivileges xmlns="urn:schemas-microsoft-com:asm.v3">
    <requestedExecutionLevel level="asInvoker" uiAccess="false" />
  </requestedPrivileges>
</security>
```
- **Rationale（设计考量）**：若默认强制管理员权限，在普通受限环境或企业安全受控电脑中将直接无法启动。通过 `asInvoker`，用户可以先正常打开应用进行常规观测，仅当需要探查受保护内核句柄时，由用户在界面上一键主动提权。

### 2.2 高 DPI 缩放感知
```xml
<application xmlns="urn:schemas-microsoft-com:asm.v3">
  <windowsSettings>
    <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
  </windowsSettings>
</application>
```

---

## 3. 平滑 UAC 一键提权工作流 (Elevation Workflow)

当用户点击标题栏上的“以管理员权限重启”按钮时：
1. **构建进程启动信息**：
   ```csharp
   var startInfo = new ProcessStartInfo
   {
       FileName = Environment.ProcessPath,
       UseShellExecute = true,
       Verb = "runas" // 触发 Windows UAC 提权凭据对话框
   };
   ```
2. **安全退出当前实例**：
   - 新实例启动成功后，当前旧实例安全调用插件的 `ShutdownAsync()` 释放句柄资源，随后优雅退出当前进程。
3. **单实例互斥锁配合**：
   - 互斥锁 (`Mutex`) 命名包含当前 Session ID，在提权平滑交接期间允许短时释放锁，避免新进程因互斥锁冲突而提前退出。

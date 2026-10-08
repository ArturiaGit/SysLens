# 技术选型决策与依赖版本矩阵 (TECH_STACK.md)

## 1. 核心技术栈与架构决策

| 层次/模块 | 选定技术方案 | 版本/目标框架 | 选型决策推导与优势 |
|---|---|---|---|
| **目标运行时** | .NET 8.0 SDK | `net8.0-windows10.0.19041.0` | 长期支持版 (LTS)，具备极致的 JIT 编译优化、硬件向量指令加速与极低非托管交互开销 |
| **编程语言** | C# 12 | 语言版本 `latest` | 借助不可变 `record`、主构造函数、`ref readonly` 及强类型集合表达式提升性能与安全性 |
| **UI 表现层** | Windows App SDK (WinUI 3) | `1.5.x` / `1.6.x` | 微软最新原生桌面 UI 框架，原生支持 Win11 Mica/Acrylic 特效与暗黑主题，无浏览器内核内存包袱 |
| **MVVM 框架** | CommunityToolkit.Mvvm | `8.2.2+` | 基于 Roslyn Source Generator 编译期生成属性与命令代码，0 反射开销，运行性能与内存表现极佳 |
| **依赖注入** | Microsoft.Extensions.DependencyInjection | `8.0.0+` | 行业标准轻量级 DI 容器，服务生命周期可控，支持插件宿主上下文解耦注入 |
| **Win32 P/Invoke** | Native P/Invoke 显式安全封装 | Win32 / NT Native API | 使用 `SafeHandle` 保证资源绝对释放，杜绝第三方重量级封装库带来的冗余运行时体积 |
| **自动化测试** | xUnit + FluentAssertions | `2.8.x` / `6.12.x` | 标准现代测试套件，断言表现力强，支持异步测试与隔离测试夹具 |

---

## 2. 桌面部署模式选型：Unpackaged（非打包模式）

### 决策推导
在 WinUI 3 应用中，存在 **Packaged (MSIX 容器打包)** 与 **Unpackaged (非打包原生模式)** 两种形态：
- **Packaged 模式劣势**：受 UWP / AppContainer 虚拟化注册表与文件系统重定向限制，进程提权（`runas`）与探查某些受限系统目录可能触发虚拟化混淆，且部署依赖签名证书，便携性差。
- **Unpackaged 模式优势**：普通 Windows PE 桌面可执行文件，天然适配系统级工具（Process Explorer 等），能够无缝以管理员身份调用 `ShellExecuteEx`，且支持单目录解压即用。

**最终决策**：SysLens 宿主程序采用 **Unpackaged 模式**：
```xml
<WindowsPackageType>None</WindowsPackageType>
<WindowsAppSDKSelfContained>true</WindowsAppSDKSelfContained>
```

---

## 3. 插件隔离技术选型：AssemblyLoadContext

### 决策推导
在 .NET 8 中，已废弃 .NET Framework 时代的 `AppDomain`。SysLens 宿主使用自定义派生自 `System.Runtime.Loader.AssemblyLoadContext` 的插件加载器：
1. **依赖隔离**：各工具小工具可自带不同版本的第三方 DLL，不会与宿主程序发生命名空间或依赖冲突；
2. **生命周期回收**：支持 `isCollectible = true`，当用户在设置中禁用或卸载小工具时，能够彻底卸载并释放相关程序集内存。

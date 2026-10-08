# 工程化工具链与构建规范 (ENGINEERING_TOOLCHAIN.md)

## 1. 开发与运行环境前置要求

| 工具/依赖 | 最低版本要求 | 检查命令 | 验证标准 |
|---|---|---|---|
| **.NET SDK** | `8.0.400+` (支持 .NET 8 / 10) | `dotnet --version` | 必须输出 `8.0.x` 或以上 |
| **PowerShell** | `7.0+` (pwsh) | `pwsh --version` | 治理脚本与交接 CLI 运行宿主 |
| **Git** | `2.40+` | `git --version` | 必须支持 Conventional Commits 与分支流转 |
| **操作系统** | Windows 10 1809+ / Windows 11 | `[System.Environment]::OSVersion` | 必须为 64 位 Windows NT 系统 |

---

## 2. 统一 MSBuild 属性契约 (`Directory.Build.props`)

在仓库根目录维护统一的 MSBuild 配置，对所有 C# 工程强加代码质量约束：

```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net8.0-windows10.0.19041.0</TargetFramework>
    <TargetPlatformMinVersion>10.0.17763.0</TargetPlatformMinVersion>
    <LangVersion>latest</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <Deterministic>true</Deterministic>
  </PropertyGroup>
</Project>
```

- **`Nullable=enable`**：全量开启可空引用类型检查，彻底防御 `NullReferenceException`。
- **`TreatWarningsAsErrors=true`**：警告视为错误，保持代码库 0 警告高纯净度。

---

## 3. 标准化日常工程构建与测试命令

### 3.1 解决方案完整编译
```powershell
dotnet build SysLens.sln -c Release
```

### 3.2 运行自动化单元测试
```powershell
dotnet test SysLens.sln --logger "console;verbosity=normal"
```

### 3.3 运行工程治理门禁自检
```powershell
pwsh scripts/governance/check.ps1
```

### 3.4 双 Agent 机械交接状态核验
```powershell
pwsh scripts/governance/handoff.ps1 status -Task <TASK-ID>
```

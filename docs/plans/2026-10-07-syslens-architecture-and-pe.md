# [RFC] SysLens 工具箱平台与首款工具 Process Explorer 整体规划设计

- 提案日期：2026-10-07
- 提案人：Antigravity
- 状态：Approved
- 关联功能：G01~G05, R01~R10

## 1. 背景与问题描述
Windows 平台缺乏现代 Fluent 风格的开源、模块化系统排障工具箱。传统 Sysinternals Process Explorer 界面老旧且难以灵活扩展第三方功能插件。本项目旨在打造现代桌面级工具箱平台并首发 Process Explorer 进程分析工具。

## 2. 方案对比与架构选型
- **UI 框架**：对比 WPF、Tauri 与 WinUI 3，最终选择微软官方最新 Windows App SDK (WinUI 3)，原生支持 Win11 Mica 材质与高刷新率虚拟化网格。
- **插件体系**：采用 .NET 8 `AssemblyLoadContext` 独立加载器，确保各工具程序集相互隔离，支持按需热加载与内存回收。
- **前后端协作**：对标 `mysql-mcp` 设立 Antigravity (UI/交付) 与 PI-Desktop (Native核心/测试) 的全栈分工与物理路径绝对隔离。

## 3. 核心契约与数据模型
- 核心规范定义见 `docs/API_AND_PROTOCOLS.md` 与 `docs/DATA_MODELS.md`。

## 4. 阶段演进路线
- 详见 `docs/ROADMAP.md`。

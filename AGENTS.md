# SysLens AI Agent 开发与协作规范 (AGENTS.md)

## 1. 入口与前置必读
在开启任何任务前，所有 Agent（包括 Antigravity 与 PI-Desktop）必须首先阅读：
- [需求基线](docs/REQUIREMENTS.md)
- [系统架构](docs/ARCHITECTURE.md)
- [安全约束](docs/PROJECT_CONSTRAINTS.md)
- [Git 工作流](docs/GIT_WORKFLOW.md)
- [双 Agent 协作规范](docs/COLLABORATION_WORKFLOW.md)
- [全栈分工与物理路径隔离](docs/FULLSTACK_DIVISION_SPECIFICATION.md)
- [验收标准](docs/ACCEPTANCE.md)
- [变更管理台账](docs/changes/README.md) 下的所有未发版变更文档

严禁未阅读变更台账即直接开发。必须区分**事实**、**用户确认**、**建议**与**待验证事项**。

---

## 2. 角色分工与物理路径绝对隔离
本项目严格推行 **全栈分工与物理路径隔离**：

### 2.1 Antigravity（前端界面、规划与交付专职）
- **管辖范围**：
  - `docs/`：全套规范文档维护
  - `governance/`：功能/任务登记与交接链记录
  - `docs/changes/`：变更碎片与发版 Release Notes 汇总维护
  - `src/SysLens.App/`：WinUI 3 XAML 视图、样式、UI 交互逻辑
  - Git 操作：分支创建、Conventional Commits 提交、PR 发起、CI 检查
- **禁忌与红线**：
  - ❌ 严禁侵入底层 Native 进程收集引擎（`src/SysLens.Core/`、`src/Tools/.../Native/` 与 `Services/`）
  - ❌ 严禁自行修补后端核心数据结构与底层收集器代码

### 2.2 PI-Desktop（底层系统与核心引擎专职）
- **管辖范围**：
  - `src/SysLens.Core/`：插件隔离加载器（AssemblyLoadContext）、特权与提权服务
  - `src/Tools/SysLens.Tools.ProcessExplorer/Native/`：Win32 P/Invoke 与 NT Native API 封装
  - `src/Tools/SysLens.Tools.ProcessExplorer/Services/`：进程/句柄/模块采集器、差量计算与树状重构算法
  - `tests/`：单元测试编写、构建运行与性能验证
- **禁忌与红线**：
  - ❌ 严禁侵入前端与界面资产（`src/SysLens.App/` 下的 XAML 视图与页面代码）
  - ❌ 严禁直接修改治理规范（`docs/`）与台账（`governance/`）
  - ❌ 严禁执行本仓库的 `commit`、`push` 或 `PR` 操作

### 2.3 用户 (User)
- 负责在两端人工复制交接 Prompt，作为中立仲裁方与阶段推进确认方。

---

## 3. 任务模式与状态机流转
任务按模式分为三类，流转状态机严格受控：
1. **系统/引擎任务 (`mode: code`)**：
   `planning (Antigravity)` → `implementation (PI-Desktop)` → `documentation_delivery (Antigravity)`
   （测试或审查不通过走 `rework (PI-Desktop)`）
2. **界面前端任务 (`mode: frontend`)**：
   `planning (Antigravity)` → `implementation (Antigravity)` → `documentation_delivery (Antigravity)`
3. **文档与治理任务 (`mode: docs`)**：
   `planning (Antigravity)` → `documentation_delivery (Antigravity)`

每次阶段流转必须调用 `scripts/governance/handoff.ps1` 生成机器可核验的交接记录（`governance/handoffs/<TASK-ID>.json`），并带有 SHA256 文件指纹。

---

## 4. 强制工作流准则
1. **分支先行**：禁止直接在 `main` 分支修改或提交。所有任务必须从最新 `main` 切出短期功能分支（如 `feat/xxx`, `chore/xxx`, `fix/xxx`）。
2. **接口先行**：前后端以 `SysLens.Sdk` 标准接口为唯一交互纽带，未经文档锁定的私有协议严禁开发。
3. **变更碎片闭环**：任务交付必须在 `docs/changes/` 下创建独立的变更记录文件，包含面向用户的发版说明与面向 Agent 的架构决策与避坑指南。
4. **真实门禁验证**：禁止 `--no-verify`，执行 `pwsh scripts/governance/check.ps1` 校验台账一致性，执行 `dotnet test` 运行单元测试。

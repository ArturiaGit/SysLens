# [TASK-GOV-001] 工程治理基线、规范矩阵与双 Agent 协作架构

- 变更日期：2026-10-07
- 关联任务：TASK-GOV-001
- 责任执行方：Antigravity
- 关联需求：R01, G01
- 关联分支：`chore/governance-baseline`

---

## 📢 发版说明 (Release Notes)

### 变更分类与追溯条目
- **🚀 Added**:
  - 建立全套工程治理体系规范，包括 `AGENTS.md`、`docs/REQUIREMENTS.md`、`docs/ARCHITECTURE.md`、`docs/PROJECT_CONSTRAINTS.md`、`docs/COLLABORATION_WORKFLOW.md`、`docs/FULLSTACK_DIVISION_SPECIFICATION.md`、`docs/GIT_WORKFLOW.md`、`docs/ACCEPTANCE.md`、`docs/TESTING_STRATEGY.md`、`docs/VERSIONING.md`。
  - 建立结构化功能与任务台账 `governance/features.json` 与 `governance/tasks.json`。
  - 引入双 Agent (Antigravity × PI-Desktop) 状态机流转与物理路径强隔离机制。
  - 建立机械防伪交接脚本 `scripts/governance/handoff.ps1` 与治理门禁校验脚本 `scripts/governance/check.ps1`。
  - 建立双重视角变更台账机制 `docs/changes/README.md`。

### 发版亮点摘要 (Highlights)
项目全面引入对标 `mysql-mcp` 的高标准双 Agent 工程治理规范与自动化门禁，为后续 SysLens 插件 SDK 与 Process Explorer 核心工具奠定坚实的契约基础。

---

## 🛠️ Agent 工程上下文与架构演进 (面向后续 Agent)

### 1. 架构与设计决策 (Why & Design)
- **为什么需要双 Agent 物理路径隔离？**
  桌面系统级工具涉及 WinUI 3 现代界面（XAML）与 Win32/NT Native 底层（P/Invoke、内存/CPU采样、句柄遍历）。通过确立 Antigravity 专职前端界面与治理交付、PI-Desktop 专职底层系统与核心引擎，并在两端设立物理路径边界与 `SysLens.Sdk` 契约中介，可彻底杜绝界面层与底层引擎的非预期耦合。
- **为什么引入 Change Fragments？**
  后续多轮迭代中，新 Agent 会话容易发生“上下文失忆”。通过在 `docs/changes/` 下维护碎片并在任务启动时强制通读，可保持高密度的架构决策对齐并防范重复踩坑。

### 2. 实际改动文件与逻辑清单 (What)
- `AGENTS.md`: Agent 行为准则与红线；
- `docs/*`: 7 份核心规范 + 变更总索引；
- `governance/*`: 双 Agent 策略配置、功能与任务台账；
- `scripts/governance/*`: 门禁脚本与交接 CLI。

### 3. ⚠️ 对后续 Agent 的避坑指南与警示红线 (Caveats & Rules)
- **绝对红线**：
  - Antigravity 严禁修改 `src/SysLens.Core/` 与 `Native/` 底层源码；
  - PI-Desktop 严禁修改 `src/SysLens.App/` 界面资产与 `docs/` 规范；
  - 任何代码开工前必须先在 `SysLens.Sdk` 中锁定公开接口；
  - 严禁 `--no-verify`，任何提交必须通过 `check.ps1` 校验。

### 4. 验证证据 (Verification)
- 运行 `pwsh scripts/governance/check.ps1`，4 项门禁全绿通过。
- 运行 `pwsh scripts/governance/handoff.ps1` 完成机械防伪交接链闭环。

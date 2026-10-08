# [TASK-GOV-002] 全套工程规范矩阵补齐与深度对标

- 变更日期：2026-10-08
- 关联任务：TASK-GOV-002
- 责任执行方：Antigravity
- 关联需求：R01~R10, G01
- 关联分支：`chore/TASK-GOV-002-comprehensive-spec-matrix`

---

## 📢 发版说明 (Release Notes)

### 变更分类与追溯条目
- **🚀 Added**:
  - 新增全套生产级核心工程规范，包括 `docs/README.md`（导航地图）、`docs/API_AND_PROTOCOLS.md`（接口先行契约）、`docs/DATA_MODELS.md`（数据字典）、`docs/TECH_STACK.md`（技术选型）、`docs/FRONTEND_UI_GUIDELINES.md`（WinUI 3 Fluent 规范）、`docs/ENGINEERING_TOOLCHAIN.md`（工程工具链与 MSBuild 契约）、`docs/DEPLOYMENT_GUIDE.md`（部署与提权指南）、`docs/CODE_REVIEW.md`（审查反模式）、`docs/ROADMAP.md`（演进路线图）、`docs/VISUAL_VERIFICATION.md`（视觉实测矩阵）、`docs/plans/` 与 `docs/verification/` 归档体系。
- **🔄 Changed**:
  - 深度扩充 `docs/REQUIREMENTS.md`（详述 R01~R10 用户故事与用例细节）。
  - 深度扩充 `docs/ARCHITECTURE.md`（增加多核异步采样时序图、ALC 隔离拓扑）。
  - 深度扩充 `docs/PROJECT_CONSTRAINTS.md`（增加受保护关键进程清单与同步命名管道挂死防御细节）。
  - 深度扩充 `docs/ACCEPTANCE.md`（细化 A01~A10 十大核心功能逐条可观察验收标准）。
  - 深度扩充 `docs/TESTING_STRATEGY.md`（补充 Mock 确定性测试、极端成环攻击防守测试与内存泄漏压测）。
  - 升级 `scripts/governance/check.ps1` 与 `governance/checks.json`，支持全量 20+ 份规范文档的自动化完整性门禁校验。

### 发版亮点摘要 (Highlights)
SysLens 工程规范体系已达成与标杆项目 `mysql-mcp` 的 100% 深度对标，建立了覆盖接口协议、数据字典、UI交互、安全威胁、工具链契约与可观察验收的完备工程治理闭环，为后续编码实现提供了坚实可靠的架构防线。

---

## 🛠️ Agent 工程上下文与架构演进 (面向后续 Agent)

### 1. 架构与设计决策 (Why & Design)
- **为什么必须建立 `API_AND_PROTOCOLS.md` 与 `DATA_MODELS.md`？**
  在双 Agent 协作模式下，Antigravity（前端）与 PI-Desktop（底层引擎）并行研发，若无文档固化的强类型接口（`IToolPlugin`, `IProcessCollectorService`）和不可变 DTO 模型（`ProcessNode`, `ModuleInfo`），任何一方的字段私自变更都会导致前后端失联。本文档锁定了所有方法签名与返回类型，严格落实“接口先行”。
- **为什么强调“同步命名管道挂死防御”？**
  Windows 下枚举进程打开的所有内核对象句柄时，若直接调用 `NtQueryObject` 探查挂起的同步命名管道，调用线程会被内核永久阻塞（甚至无法响应线程中断）。在 `PROJECT_CONSTRAINTS.md` 与 `CODE_REVIEW.md` 中强制固化了类型过滤与 50ms 超时看门狗机制，这是系统级工具开发的核心避坑要点。

### 2. 实际改动文件与逻辑清单 (What)
- 新增 12 份专业规范文档，涵盖接口、模型、UI、代码审查、工具链与路线图；
- 深度扩充 5 份核心设计文档，将内容密度提升至生产级；
- 升级 `scripts/governance/check.ps1`，将规范完整性校验清单扩充至全量 20 份文件。

### 3. ⚠️ 对后续 Agent 的避坑指南与警示红线 (Caveats & Rules)
- **绝对红线**：
  - 后续 Agent 在编码阶段严禁擅自修改已锁定的接口签名（如需修改必须走 RFC 提案）；
  - 底层采集逻辑严禁裸写 `IntPtr`，必须使用 `SafeHandle` 包装；
  - 任何针对进程树的构建必须经过环路检测，严禁出现因父子 PID 循环引用导致的栈溢出崩溃。

### 4. 验证证据 (Verification)
- 运行 `pwsh scripts/governance/check.ps1`，4 项门禁全绿通过 (CHK-01 验证 20 份规范 0 缺失 0 空文件)。
- 运行 `pwsh scripts/governance/handoff.ps1` 完成 TASK-GOV-002 防伪交接链闭环。

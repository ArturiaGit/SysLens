# 双 Agent 人工转交与机械交接规范 (COLLABORATION_WORKFLOW.md)

## 1. 规范概述
本项目严格采用双 Agent 人工中转与状态机驱动的机械交接机制（对标 `mysql-mcp`）。
- **Antigravity**：负责规划 (Planning)、文档规范 (Docs)、界面视图 (UI XAML)、变更记录与交付 (Documentation Delivery & Git)。
- **PI-Desktop**：负责底层系统与核心引擎 (Core)、Win32 P/Invoke 接口、数据收集器与算法、单元测试执行与构建。
- **用户 (User)**：作为中立协调人，在两端复制交接 Prompt 并核实交接证据。

---

## 2. 状态机流转

```text
任务启动
   │
   ▼
[Planning / Antigravity] ──(检查需求基线、更新台账、冻结接口)
   │
   ├─► mode: docs/frontend ─► [Implementation / Antigravity] ─► [Documentation_Delivery / Antigravity] ─► 交付完成
   │
   └─► mode: code ─────────► [Implementation / PI-Desktop]  ─► [Documentation_Delivery / Antigravity] ─► 交付完成
                                      │ (若测试或CI失败)                ▲
                                      ▼                                 │
                                  [Rework / PI-Desktop] ────────────────┘
```

---

## 3. 机械交接命令行契约
所有交接必须通过 PowerShell 脚本 `scripts/governance/handoff.ps1` 进行记录并校验，严禁人工伪造：

### 3.1 开启阶段 (Begin)
```powershell
pwsh scripts/governance/handoff.ps1 begin -Task TASK-xxx -Role <antigravity|pi-desktop> -Phase <planning|implementation|documentation_delivery|rework>
```

### 3.2 结束阶段 (Finish)
```powershell
pwsh scripts/governance/handoff.ps1 finish -Task TASK-xxx -Role <antigravity|pi-desktop> -Summary "完成内容简要描述"
```

### 3.3 接收方显式接受 (Accept)
```powershell
pwsh scripts/governance/handoff.ps1 accept -Task TASK-xxx -Role <antigravity|pi-desktop> -HandoffEvent <EVENT_ID> -Digest <SHA256>
```

---

## 4. 机械防伪记录结构
交接记录统一持久化于 `governance/handoffs/<TASK-ID>.json`，每次记录均绑定：
- `event_id`：递增唯一事件编号
- `timestamp`：UTC 时间戳
- `task_id`：任务编号
- `role`：操作角色
- `phase`：所处阶段
- `previous_digest`：前序事件状态摘要（SHA256）
- `file_snapshots`：当前改动文件的哈希指纹，防止跨阶段代码漂移

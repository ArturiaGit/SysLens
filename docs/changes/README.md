# 变更管理台账总索引 (docs/changes/README.md)

> **定位与机制**：
> 本目录沉淀每次任务交付的变更碎片（Change Fragments）。
> 具备双重视角：
> 1. **对 Agent**：作为任务启动前的强制必读上下文，记录架构决策、环境特异性与避坑警示；
> 2. **对发版 (Release)**：标准变更条目直接提取并聚合成正式的 CHANGELOG 与 Release Notes。

---

## 1. 单篇变更文档标准结构模板
命名格式：`YYYY-MM-DD-TASK-<ID>-<slug>.md`

```markdown
# [TASK-ID] 变更标题

- 变更日期：YYYY-MM-DD
- 关联任务：TASK-xxx
- 责任执行方：Antigravity / PI-Desktop
- 关联需求：Rxx, Gxx

---

## 📢 发版说明 (Release Notes)
### 变更分类
- **🚀 Added**: 新增功能条目
- **🔄 Changed**: 调整与优化条目
- **🐛 Fixed**: 修复缺陷条目
- **⚠️ Breaking Changes**: 破坏性改动说明

### 亮点摘要 (Highlights)
1-2 句通俗说明。

---

## 🛠️ Agent 工程上下文与架构演进 (面向后续 Agent)
### 1. 架构与设计决策 (Why & Design)
背后的方案选型与技术推导。

### 2. 实际改动文件与逻辑清单 (What)
文件清单与核心逻辑。

### 3. ⚠️ 对后续 Agent 的避坑指南与警示红线 (Caveats & Rules)
环境陷阱、隐蔽 Bug 与绝对不可侵犯的规则。

### 4. 验证证据 (Verification)
执行的门禁命令与实测结果。
```

---

## 2. 活动未发版变更列表 (Unreleased)
| 变更文档 | 关联任务 | 责任方 | 核心亮点 |
|---|---|---|---|
| [TASK-GOV-001 规范基线与双 Agent 协作架构](./2026-10-07-TASK-GOV-001-governance-baseline-and-collaboration.md) | TASK-GOV-001 | Antigravity | 建立全套工程规范、双 Agent 协作契约与变更台账 |

---

## 3. 历史版本归档索引 (Released Archives)
> 尚无正式已发布版本。

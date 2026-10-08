# 规划提案与设计归档目录 (docs/plans/README.md)

> **定位与生命周期**：
> 本目录用于归档重大的技术设计提案 (RFC)、架构重构计划及阶段规划文档。
> 任何涉及多模块改动、破坏性变更或底层驱动级调整的方案必须先在此撰写提案，经用户审阅批准后再进入开发阶段。

---

## 1. 提案文件命名与结构模板
命名格式：`YYYY-MM-DD-<slug>.md`

```markdown
# [RFC] 方案标题

- 提案日期：YYYY-MM-DD
- 提案人：Antigravity / PI-Desktop
- 状态：Draft / Approved / Implemented / Rejected
- 关联功能：Gxx, Rxx

## 1. 背景与问题描述
## 2. 备选方案对比与推导
## 3. 详细设计与代码契约
## 4. 迁移与风险影响
## 5. 验收与验证计划
```

---

## 2. 归档提案列表
| 提案文档 | 关联功能 | 状态 | 核心概述 |
|---|---|---|---|
| [2026-10-07-syslens-architecture-and-pe.md](./2026-10-07-syslens-architecture-and-pe.md) | G01~G05 | Approved | SysLens 工具箱平台与首款工具 Process Explorer 整体规划设计 |

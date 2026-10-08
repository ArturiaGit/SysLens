# 可核验验证证据与测试记录索引 (docs/verification/README.md)

> **定位与机制**：
> 本目录用于归档每次任务执行的真实机器证据（包含终端输出日志、自动化门禁测试结果、CI 运行报告与实机排障记录）。
> 任何功能声明“已通过”必须在此具备真实可核查的物理证据。

---

## 1. 验证报告模板
命名格式：`YYYY-MM-DD-TASK-<ID>-verification.md`

```markdown
# [TASK-ID] 验证报告

- 验证日期：YYYY-MM-DD
- 执行环境：Windows 11 Build xxxxx, .NET SDK x.x.xxx
- 责任执行方：Antigravity / PI-Desktop

## 1. 自动化门禁测试结果
(粘贴 pwsh scripts/governance/check.ps1 输出)

## 2. 单元测试与覆盖率证据
(粘贴 dotnet test 运行输出)

## 3. 实机交互与视觉验证证据
(描述手工验收步骤并嵌入截图证据)
```

---

## 2. 验证记录归档列表
| 记录文档 | 关联任务 | 结论 | 核心证据摘要 |
|---|---|---|---|
| [2026-10-07-TASK-GOV-001-verification.md](./2026-10-07-TASK-GOV-001-verification.md) | TASK-GOV-001 | PASSED | 治理基线 4 项门禁全绿，交接链 SHA256 签名通过 |
| [2026-10-08-TASK-GOV-002-verification.md](./2026-10-08-TASK-GOV-002-verification.md) | TASK-GOV-002 | PASSED | 全套 20 份规范文档完整性检验通过 |

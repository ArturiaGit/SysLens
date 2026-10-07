# Git 工作流规范 (GIT_WORKFLOW.md)

## 1. 分支管理策略
1. **主干受控**：`main` 为稳定主干，禁止任何人直接在 `main` 上开发或提交代码。
2. **任务功能分支**：
   - 每次任务开工前，由 Antigravity 确保本地主干处于最新状态，并切出对应类型的短期任务分支：
     - `feat/<task-id>-<slug>`：新功能开发
     - `fix/<task-id>-<slug>`：缺陷修复
     - `docs/<task-id>-<slug>`：纯文档任务
     - `chore/<task-id>-<slug>`：工程脚手架与治理配置变更
   - 示例：`chore/TASK-GOV-001-governance-baseline`

---

## 2. 提交信息规范 (Conventional Commits)
提交信息必须遵循标准格式：
```text
<type>(<scope>): <简明描述>
```

- **Type 类型**：
  - `feat`: 新增特性或功能
  - `fix`: 修复缺陷
  - `docs`: 文档或规范更新
  - `test`: 单元测试相关
  - `refactor`: 重构（既非修复缺陷也非新增特性）
  - `chore`: 构建工具、治理脚本、基础配置变动
- **Scope 范围**：
  - `gov`: 工程治理与规范
  - `sdk`: 插件契约与模型
  - `shell`: 宿主程序与主界面
  - `pe`: Process Explorer 模块
  - `core`: 插件加载与特权核心

---

## 3. 提交与推送前检查
在每次执行 `git commit` 前，Antigravity 必须完成：
1. 检查 `git status` 与 `git diff`，确保仅暂存当次任务授权的文件；
2. 严禁暂存私人凭据、本地日志文件、临时目录或破坏性配置；
3. 执行 `pwsh scripts/governance/check.ps1` 确保治理门禁全绿通过。

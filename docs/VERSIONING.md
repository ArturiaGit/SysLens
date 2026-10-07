# 版本命名与发布规范 (VERSIONING.md)

## 1. 语义化版本规则 (Semantic Versioning)
本项目严格遵守 [SemVer 2.0.0](https://semver.org/)：
`vMAJOR.MINOR.PATCH[-PRERELEASE]`

- **MAJOR (主版本号)**：发生不兼容的重大契约变更或破坏性架构调整（如 `IToolPlugin` 接口废弃、架构重构）。
- **MINOR (次版本号)**：向后兼容地引入新小工具模块或平台功能增强（如加入 Process Explorer 工具、加入网络监控模块）。
- **PATCH (修订号)**：向后兼容的缺陷修复、性能调优或治理门禁脚本更新。
- **PRERELEASE (先行版标记)**：如 `v0.1.0-alpha`（治理基线与骨架搭建阶段）。

---

## 2. 发布与 Release 流程
1. 在发布新版本时，由 Antigravity 扫描 `docs/changes/` 下所有活动未发版文件；
2. 提取每个文件中的【📢 发版说明】板块；
3. 聚合成正式的 `CHANGELOG.md` 及 GitHub Release Notes；
4. 将该批次文件移动至 `docs/changes/archive/vX.Y.Z/` 归档。

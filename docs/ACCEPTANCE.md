# 可观察验收标准规范 (ACCEPTANCE.md)

## 1. 验收准则设计原则
所有功能和任务必须具备**可观察、可量化、可验证**的验收标准。不得仅凭代码编写完成即声称通过。

---

## 2. 核心功能集可观察验收准则

### A01 [治理体系与协作门禁] (对应 G01 / TASK-GOV-001)
1. 运行 `pwsh scripts/governance/check.ps1`，终端输出无任何错误，台账、规范与变更索引一致性校验为 PASSED。
2. 调用 `handoff.ps1` 执行 `begin` 与 `finish`，`governance/handoffs/` 下能生成包含有效 SHA256 指纹的记录。
3. `docs/changes/README.md` 正确登记本次任务变更文件链接。

### A02 [插件 SDK 规范] (对应 G02 / TASK-SDK-001)
1. `SysLens.Sdk` 类库成功编译，公开接口 `IToolPlugin`、`IPluginContext` 与 `IProcessCollector` 完备无缺陷。
2. 单元测试 `SysLens.Sdk.Tests` 覆盖率 100%，正确校验元数据属性不可为空。

### A03 [WinUI 3 宿主外壳与动态加载] (对应 G03 / TASK-SHELL-001 & TASK-CORE-001)
1. 宿主程序 `SysLens.App` 启动，主窗口自适应渲染 Windows 11 Fluent 亚克力/云母材质与系统主题。
2. 放入插件 DLL 后，`NavigationView` 菜单栏能动态呈现新插件项与图标，点击能顺畅切换进入。
3. 标题栏正确呈现权限徽标；点击“以管理员权限重启”能正确触发 UAC 提权并唤起新进程。

### A04 [Process Explorer 进程采集与树状算法] (对应 G04 / TASK-PE-001)
1. 采集器能在多核系统上平滑输出增量 CPU% 与各指标，CPU 占用率总和与系统实际负载保持合理区间。
2. 树状算法正确挂载所有子进程（如父 PID 存在时成为子节点，孤儿进程优雅挂在顶级）。
3. 单元测试覆盖树重构算法、边界 PID（0, 4）以及循环父子关系防御。

### A05 [Process Explorer 双面板交互] (对应 G05 / TASK-PE-002)
1. 进程树上方面板毫秒级刷新，支持即输即搜过滤。
2. 右键支持挂起、恢复、结束进程并即时生效。
3. 选中进程后，下方标签页能正确加载并展示模块 DLL、句柄 Handle 和线程 Thread 列表。

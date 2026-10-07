# 全栈分工与物理路径绝对隔离规范 (FULLSTACK_DIVISION_SPECIFICATION.md)

## 1. 物理路径归属矩阵

| 目录/文件路径 | 归属执行方 | 权限说明 |
|---|---|---|
| `docs/**` | Antigravity | 需求、架构、设计、规范与流程文档 |
| `governance/**` | Antigravity | 功能/任务台账、双 Agent 交接记录链 |
| `docs/changes/**` | Antigravity | 变更碎片、发版说明、避坑警示维护 |
| `AGENTS.md` | Antigravity | 统一 Agent 规范入口 |
| `src/SysLens.App/**` | Antigravity | 宿主 WinUI 3 界面、XAML 布局、UI 交互逻辑 |
| `src/SysLens.Sdk/**` | 共同维护 (接口先行) | 插件标准接口与共享模型契约 |
| `src/SysLens.Core/**` | PI-Desktop | 插件动态隔离加载器、Windows 权限管理服务 |
| `src/Tools/**/Native/**` | PI-Desktop | Win32 P/Invoke 与 NT Native API 封装 |
| `src/Tools/**/Services/**` | PI-Desktop | 进程/句柄/模块采集与后台计算服务 |
| `tests/**` | PI-Desktop | 引擎逻辑与算法自动化单元测试套件 |
| `scripts/governance/**` | Antigravity | 治理门禁与交接工具脚本 |

---

## 2. 隔离与交互原则
1. **禁止越权修改**：
   - Antigravity 绝对禁止修改 `src/SysLens.Core/`、`Native/` 与 `Services/` 底层代码。
   - PI-Desktop 绝对禁止修改 `src/SysLens.App/` 界面代码、`docs/` 规范及执行 Git 提交。
2. **唯一中介（接口先行）**：
   - 界面层与核心引擎层的通信只能依赖 `src/SysLens.Sdk/` 声明的接口与不可变数据模型（DTO / Records），严禁跨层直接引用实现类。
3. **门禁阻断**：
   - 门禁脚本 `check.ps1` 将在提交前核查修改文件是否超出当次任务的角色许可路径白名单。

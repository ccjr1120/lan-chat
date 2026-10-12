# AGENTS.md

局域网互传（lan_chat）：Flutter App（Android/iOS 优先，macOS 可用）+ 主机内置网页端。
本文件只负责引导，具体流程统一维护在 [AGENTS_WORKFLOW.md](AGENTS_WORKFLOW.md)，不要在此重复。

## 任务路由

| 任务场景 | 必须执行的工作流 |
| --- | --- |
| 新增或变更项目级结构、技术栈、跨模块依赖 | `AGENTS_WORKFLOW.md` →「1. 实施计划确认」+「2. 架构文档维护」 |
| 新增或变更模块（server / client / storage / discovery / core / app_ui / web_ui） | 「1. 实施计划确认」+「2. 架构文档维护」 |
| 新增或变更前端页面（App 首页/聊天页、网页聊天页） | 「1」+「2」，并更新对应 `pages/<page>/Design.md` |
| 修改 WebSocket / HTTP 协议 | 「3. 协议变更」 |
| 修改平台权限或原生工程配置 | 「4. 平台配置」 |
| 任意代码变更后的验证 | 「5. 验证」 |

## 关键入口

- 架构文档唯一来源：[project_architecture/Design.md](project_architecture/Design.md)
- 实施任何项目、模块或页面变更前，先阅读相关层级的 `Design.md`，并在同一次实施中同步更新受影响的文档。
- 使用说明：[README.md](README.md)

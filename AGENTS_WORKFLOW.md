# AGENTS_WORKFLOW.md

本项目的具体工作流。`AGENTS.md` 只负责把任务路由到这里的对应章节。

## 1. 实施计划确认

适用于：新项目功能、新增/变更模块、新增/变更页面。

1. 阅读 `project_architecture/Design.md` 及受影响模块/页面的 `Design.md`。
2. 输出实施计划：目录结构、模块拆分、技术选型（依赖需锁定具体版本）、影响范围（模块、页面、协议、平台配置、文档）。
3. 等待用户明确确认后再实施；确认范围外的改动需重新确认。

## 2. 架构文档维护（project_architecture/）

`project_architecture/` 是技术架构文档的唯一来源，不得另建 `project-architecture/` 或其他并行文档体系。

层级固定为：

- `project_architecture/Design.md`：项目边界、技术栈、整体结构、模块地图、跨模块依赖、关键架构决策，并索引所有模块文档。
- `project_architecture/modules/<module>/Design.md`：模块职责、内部结构、公开接口、数据流、依赖关系、实现位置、变更影响。
- `project_architecture/modules/<frontend-module>/pages/<page>/Design.md`：仅前端模块（`app_ui`、`web_ui`），按独立页面记录路由、页面结构、交互状态、数据来源、接口依赖、实现入口；模块文档必须索引全部页面文档。

规则：

1. 实施前阅读相关层级文档；实施中同步更新所有受影响的项目级、模块级、页面级文档（同一次变更内完成）。
2. 共享组件、弹窗等非独立页面记录在所属前端模块的 `Design.md`；形成独立业务页面时才建页面文档。
3. 新增模块或页面时，同时在上一级文档的索引中登记。
4. 视觉规范以 `lib/ui/theme.dart` 与 `assets/web/index.html` 的 CSS 变量为准，不在架构文档中重复维护。

## 3. 协议变更

WebSocket 事件与 HTTP 接口同时被 App（Dart）与网页端（`assets/web/index.html`）使用。

1. 修改 `lib/core/protocol/ws_event.dart`（事件定义）或 `lib/server/lan_server.dart`（接口实现）。
2. 同步修改 `lib/client/` 与 `assets/web/index.html` 中的对应处理。
3. 不兼容变更需提升 `LanChatConstants.protocolVersion`。
4. 更新 `project_architecture/Design.md` 的「通信协议」章节以及 server / client / web_ui 模块文档。

## 4. 平台配置

1. Android：`android/app/src/main/AndroidManifest.xml`、`res/xml/network_security_config.xml`。
2. iOS：`ios/Runner/Info.plist`（`NSLocalNetworkUsageDescription`、`NSBonjourServices` 必须包含 `_lanchat._tcp`、`NSAllowsLocalNetworking`）。
3. macOS：`macos/Runner/DebugProfile.entitlements` 与 `Release.entitlements` 同步修改。
4. mDNS 服务类型变更时，`LanChatConstants.serviceType` 与两端 `NSBonjourServices` 必须同步。
5. 更新 README「平台权限配置」章节。

## 5. 验证

- 除非用户明确授权，只运行类型检查：`flutter analyze`。
- 不编写或运行测试，不运行构建、打包、端到端测试等其他验证命令。
- 网页端（纯 HTML/JS）无类型检查工具，修改后需人工核对与协议的一致性。

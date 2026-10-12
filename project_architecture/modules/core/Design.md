# core 模块

## 职责

跨模块共享的纯 Dart 定义：数据模型、WS 协议事件、会话抽象与常量。不包含网络或平台调用。

## 内部结构

| 文件 | 说明 |
| --- | --- |
| `lib/core/constants.dart` | `LanChatConstants`：服务类型 `_lanchat._tcp`、首选端口 8686、协议版本、超时、历史条数 |
| `lib/core/models/peer.dart` | `Peer`、`PeerPlatform(host/app/web)` |
| `lib/core/models/chat_message.dart` | `ChatMessage`、`MessageKind(text/file)`、`FileMeta` |
| `lib/core/models/access_mode.dart` | `AccessMode(open/approval)` |
| `lib/core/protocol/ws_event.dart` | `WsEventType` 常量、`WsEvent` 编解码 |
| `lib/core/session/chat_session.dart` | `ChatSession` 抽象（ChangeNotifier）、`SessionStatus`、`OutgoingTransfer`、`LocalFileSource` |

## 公开接口

`ChatSession` 是 UI 唯一依赖的会话接口：`self`、`title`、`isHost`、`status`、`statusMessage`、`messages`、`peers`、`outgoing`、`downloads`、`sendText`、`sendFile`、`localPathFor`、`ensureLocal`、`close`。dispose 之后不会再通知监听者。

## 依赖关系

- 仅依赖 Flutter foundation。
- 被所有业务模块依赖。

## 变更影响

- 模型 JSON 字段变更会影响 storage（历史兼容）、server、client 与 web_ui。
- `ChatSession` 接口变更需要同步 `HostSession`、`ClientSession` 和 app_ui。

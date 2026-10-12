# server 模块

## 职责

主机模式：运行内置 HTTP + WebSocket 服务，托管网页端，执行访问控制，统一分配和广播消息，保存聊天记录与文件，并通过 mDNS 广播本机。

## 内部结构

| 文件 | 说明 |
| --- | --- |
| `lib/server/lan_server.dart` | `LanServer`：shelf 路由、WS 连接管理、访问控制、消息发布 |
| `lib/server/host_session.dart` | `HostSession`：实现 `ChatSession`，组合 `LanServer` + `LanBroadcaster` + 地址获取，供 UI 使用 |
| `lib/server/client_connection.dart` | `ClientConnection`（单连接状态：handshaking/pending/joined）、`JoinRequest` |
| `lib/server/http_utils.dart` | JSON 响应、token 读取、multipart boundary / Content-Disposition 解析、Range 解析 |
| `lib/server/network_addresses.dart` | 本机局域网 IPv4 地址（Wi-Fi 优先，补充网卡枚举以支持热点） |

## 公开接口

- `HostSession.start(AppStorage)`：启动服务和广播，失败时抛出异常。
- `HostSession.addresses / urls / primaryUrl / refreshAddresses()`：访问地址。
- `HostSession.accessMode / setAccessMode()`：切换访问模式，同时持久化到设置。
- `HostSession.pendingRequests / approve(deviceId) / reject(deviceId)`：处理加入请求。
- `HostSession.clearHistory()`：清空记录和文件，并广播空 `history`。
- `ChatSession` 的全部接口（发送文字、文件，查询本地文件路径，结束会话）。

HTTP / WS 协议见 [项目文档 · 通信协议](../../Design.md#通信协议)。

## 数据流

1. 客户端连接 `/ws`，`LanServer` 创建 `ClientConnection(handshaking)`，并启动 10 秒 hello 超时。
2. 收到 `hello` 后，如果是 `open` 模式或该设备已被同意，就 `_join`：下发 token、`welcome`、`history`，并广播 `peers`。否则进入 `pending`，登记 `JoinRequest`，然后通知 UI 弹窗。
3. 主机同意后执行 `_join`；拒绝则发送 `rejected` 并关闭。等待中的设备断开时撤销对应请求，弹窗自动关闭。
4. 文字消息走 WS，文件走 `POST /api/upload`（流式写入 `.part`，完成后改名）。两者都经 `_publish`：内存列表 → `history.jsonl` → 广播 `message`。
5. 主机自己发文件时，`postFile` 把选中文件流复制进文件存储，再发布。

## 依赖关系

- 依赖：`core`（模型、协议、会话抽象）、`storage`（HistoryStore、FileStore、SettingsStore）、`discovery`（LanBroadcaster）。
- 依赖资源：`assets/web/index.html`（web_ui 模块）。
- 被依赖：`app_ui`。

## 变更影响

- 修改事件或接口时，需同步 `client` 模块与 `web_ui`（见 AGENTS_WORKFLOW「协议变更」）。
- 修改端口或服务类型时，需同步 `LanChatConstants`、iOS/macOS `NSBonjourServices` 与 README。
- 修改访问控制时，需同步首页/聊天页的弹窗逻辑（app_ui）和网页端的等待/拒绝状态（web_ui）。

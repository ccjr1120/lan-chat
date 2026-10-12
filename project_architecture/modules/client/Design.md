# client 模块

## 职责

App 客户端模式：连接主机 WebSocket 加入会话（含等待确认和被拒绝状态），断线自动重连；通过 dio 带进度地上传、下载文件。

## 内部结构

| 文件 | 说明 |
| --- | --- |
| `lib/client/client_session.dart` | `ClientSession`：实现 `ChatSession`，管理 WS 连接、状态机、消息去重、下载去重 |
| `lib/client/transfer_client.dart` | `TransferClient`：`/api/info` 校验、`/api/upload`、`/api/files/<id>` 下载，dio 异常转为可读文案 |

## 公开接口

- `ClientSession(storage, host, port, hostName?)`，`connect()`、`retryNow()`、`dismissTransfer()`。
- `address`、`webUrl`。
- `ChatSession` 全部接口。`ensureLocal(file)` 会在文件不在本地时下载到 `files/<id>/<name>`，同一文件的并发请求会合并。

## 状态机

```
connecting ──welcome──> connected
    │  └──pending──> pending ──welcome──> connected
    │                  └──rejected──> rejected（终止，不重连）
    └──失败/断开──> disconnected ──退避 1/2/4/8/15s──> connecting
任意状态 ──close()──> closed
```

- 首次连接前请求 `/api/info`，用来确认地址确实是本应用主机，并获取主机名称。
- 每次重连都重新发送 hello。主机已同意过的设备不会再次进入 pending。
- 聊天记录不在客户端持久化，每次 `welcome` 后由 `history` 全量覆盖，并按消息 ID 去重。

## 依赖关系

- 依赖：`core`、`storage`（SettingsStore 提供设备 ID 和名称，FileStore 保存下载的文件）。
- 通过协议依赖 `server`。
- 被依赖：`app_ui`。

## 变更影响

- 协议变更需与 `server`、`web_ui` 同步。
- 更改下载路径会影响 `app_ui` 中打开、分享文件和图片预览（`localPathFor`）。

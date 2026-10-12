# discovery 模块

## 职责

基于 bonsoir 的 mDNS（Android NSD / Apple Bonjour）服务广播与发现，服务类型为 `_lanchat._tcp`。

## 内部结构

| 文件 | 说明 |
| --- | --- |
| `lib/discovery/lan_discovery.dart` | `LanBroadcaster`（主机广播）、`LanDiscovery`（客户端发现，ChangeNotifier）、`DiscoveredHost` |

## 公开接口

- `LanBroadcaster.start(deviceId, deviceName, port)` / `stop()`。服务名为 `LanChat-<deviceId 前 8 位>`，TXT 包含 `id`、`name`、`v`。
- `LanDiscovery.start()` / `restart()` / `stop()`，`hosts`（已解析主机，按名称排序）、`error`、`ownDeviceId`（排除本机）。

## 数据流

发现到服务（found）后调用 `resolve`。解析完成后优先取 IPv4 地址，生成 `DiscoveredHost`；服务丢失（lost）时从列表移除。

## 依赖关系

- 依赖：bonsoir、`core/constants.dart`。
- 被依赖：`server`（HostSession 使用广播）、`app_ui`（首页发现列表）。
- 平台：iOS/macOS 需要声明 `NSBonjourServices`（`_lanchat._tcp`）和 `NSLocalNetworkUsageDescription`；Android 需要 `CHANGE_WIFI_MULTICAST_STATE`（组播锁由 bonsoir_android 管理）。

## 变更影响

- 修改服务类型需同步 `LanChatConstants.serviceType`、iOS/macOS Info.plist 与 README。
- 广播失败不影响主机服务，用户仍可通过 IP 或二维码访问。

# 局域网互传（lan_chat）

在同一局域网（或手机热点）内，让手机与手机、手机与电脑互传文字和文件。任意一台手机开启「主机」服务后：

- 其他手机用本 App 加入（自动发现或输入 IP）；
- 电脑无需安装，浏览器扫码或输入地址就能使用网页版。

主机可以选择「无需认证」或「需确认」两种访问模式，并且随时切换。

## 环境要求

- Flutter 3.38.1 及以上（开发验证版本：Flutter 3.47.7 / Dart 3.13.5）
- Android：Android Studio / Android SDK，真机 Android 5.0+
- iOS：Xcode，真机 iOS 15+（本地网络与 Bonjour 在模拟器上表现与真机不同）
- macOS（可选）：macOS 12+

## 启动步骤

```bash
cd lan-chat
flutter pub get
flutter devices          # 查看已连接设备
flutter run -d <设备ID>  # Android / iOS 真机
```

iOS 首次运行需要在 Xcode 打开 `ios/Runner.xcworkspace`，在 Signing & Capabilities 中选择开发团队，并按需修改 Bundle Identifier（默认 `com.lanchat.lanChat`）。

## 使用方式

### 1. 开启主机

App 首页点击「创建会话」后会显示：

- 网页访问二维码；
- 访问地址，例如 `http://192.168.1.8:8686`（端口 8686 被占用时会自动换成其他端口，以页面显示为准）；
- 加入方式：直接加入 / 需要我确认（分别对应无需认证 / 需确认）。

点击「进入会话」开始聊天。返回首页后服务会继续运行，点击「结束会话」并确认才会关闭。

### 2. 电脑扫码或输入 IP 访问

- 电脑浏览器直接输入主机页面上显示的地址，例如 `http://192.168.1.8:8686`；
- 或者用另一台手机的相机扫描二维码，在浏览器中打开。

网页端支持发送文字、点附件图标选择文件、把文件拖拽到页面、粘贴截图。上传时显示进度，点击文件消息即可下载。可在右上角「我的名称」修改显示名称。

### 3. 手机互连（App 客户端）

另一台手机打开 App，选择「加入会话」：

- 「附近的会话」列表会通过 mDNS 自动发现同一网络中的主机，点击即可加入；
- 如果没有自动发现，可以展开「输入会话地址」，填入 `192.168.1.8:8686` 后点「连接设备」。

在聊天页点击文件会先下载再用系统应用打开，分享按钮可以把文件转到其他应用。

### 4. 访问控制

| 模式 | 行为 |
| --- | --- |
| 无需认证 | 局域网内任何设备直接加入 |
| 需确认 | 新设备（网页或 App）加入时，主机 App 弹窗询问；对方显示「等待主机确认」。同意后进入会话，拒绝则断开，对方会看到提示 |

- 两种模式可在首页或聊天页右上角二维码面板中，点击「加入方式」随时切换，切到「无需认证」时，等待中的设备会被直接放行。
- 已同意的设备在本次服务运行期间断线重连不需要再次确认；停止服务后重新开启需要重新确认。
- 设备身份：App 使用本机生成的设备 ID；网页端把 ID 保存在浏览器 localStorage 中，清除浏览器数据后会被视为新设备。

### 5. 热点模式（没有 Wi-Fi 时）

1. 主机手机开启「个人热点」；
2. 电脑或其他手机连接该热点；
3. 主机 App 创建会话（如果已经开启，点「刷新地址」），使用页面上显示的地址访问。常见网段：Android 为 `192.168.43.x` 等，iPhone 为 `172.20.10.1`。

热点模式下 mDNS 自动发现可能不可用，请用二维码或手动输入 IP。

## 数据存储

- 聊天记录只保存在主机：`<ApplicationSupport>/history.jsonl`（JSON Lines）；
- 文件保存在 `<Documents>/files/<文件ID>/<文件名>`。iOS 可在「文件」App →「我的 iPhone」→「局域网互传」中查看；
- 主机可在聊天页菜单中「清空聊天记录」，消息和文件会同时删除，所有设备同步清空。

## 平台权限配置

以下配置已写入工程，修改时请保持一致。

### Android（`android/app/src/main/AndroidManifest.xml`）

- `INTERNET`：HTTP/WebSocket 服务与连接；
- `ACCESS_WIFI_STATE`、`ACCESS_NETWORK_STATE`：获取 Wi-Fi IP；
- `CHANGE_WIFI_MULTICAST_STATE`：mDNS 组播；
- `android:usesCleartextTraffic="true"`，并配置 `res/xml/network_security_config.xml`，允许局域网明文 HTTP/WS。

### iOS（`ios/Runner/Info.plist`）

- `NSLocalNetworkUsageDescription`：本地网络权限说明（iOS 14+ 首次访问时弹窗）；
- `NSBonjourServices`：`_lanchat._tcp`；
- `NSAppTransportSecurity` → `NSAllowsLocalNetworking = true`；
- `UIFileSharingEnabled`、`LSSupportsOpeningDocumentsInPlace`：在「文件」App 中显示接收的文件；
- `NSPhotoLibraryUsageDescription`、`NSCameraUsageDescription`：文件选择器访问相册。

### macOS（`macos/Runner/*.entitlements`）

原生窗口使用本地化产品名（中文「局域网互传」、英文「LAN Chat」）。MainFlutterWindow 通过 MethodChannel 同步 App 主题菜单，透明标题栏与页面背景统一，保留原生窗口按钮。macOS 首页所有窗口宽度均不重复显示产品标题导航栏。InfoPlist.strings / MainMenu.strings 已注册中英文资源；原生修改需完整重新运行 App，热重载无法更新。

- `com.apple.security.network.server` / `network.client`；
- `com.apple.security.files.user-selected.read-write`、`files.downloads.read-write`；
- Info.plist 中同样声明了 `NSLocalNetworkUsageDescription` 与 `NSBonjourServices`。

## 已知限制

- **安全性**：通信为明文 HTTP/WS，没有 TLS 和端到端加密，只适合在可信的局域网中使用；「需确认」模式只控制谁能加入会话，不能防止同一网络中的流量嗅探。
- **主机须保持前台**：iOS 应用进入后台后很快会被挂起，服务随之中断；Android 后台也可能被系统回收。传输期间请保持主机 App 在前台、屏幕常亮。
- **iOS 本地网络权限**：首次开启服务或搜索设备时，系统会请求「本地网络」权限。如果拒绝了，需要到「设置 → 隐私与安全性 → 本地网络」重新开启，否则其他设备无法连接。
- **网络隔离**：部分公共或企业 Wi-Fi 开启了 AP 隔离，设备之间无法互访；也有路由器会屏蔽组播，导致自动发现失败，此时请改用热点或手动输入 IP。
- **单主机**：一个会话只有一台主机，聊天记录只保存在主机上；客户端不保存聊天记录，重新连接后从主机同步最近 500 条。
- **上传不支持断点续传**：上传中断后需要重新发送；下载接口支持 Range，但 App 客户端目前不做断点续传。
- **网页端兼容性**：需要现代浏览器（Chrome / Edge / Safari / Firefox 近两年版本）。
- **主机修改设备名**：在服务运行中修改，下次开启服务时才会生效。

## 开发

- 架构文档：[project_architecture/Design.md](project_architecture/Design.md)
- Agent 工作流：[AGENTS.md](AGENTS.md) / [AGENTS_WORKFLOW.md](AGENTS_WORKFLOW.md)
- 类型检查：`flutter analyze`

### UI 与第三方库

首页采用创建 / 加入会话入口，桌面首页在宽度 ≥ 900 时使用创建 / 加入操作双栏（最大宽度 1440），窄屏使用单列，连接方式示意放在创建会话卡片中，宽会话窗口显示在线设备、消息与最近文件三栏；App 与网页使用统一明暗配色。App 右上角主题菜单提供跟随系统 / 浅色 / 深色，初始默认跟随系统并保存选择；网页跟随浏览器系统外观。图标采用 `lucide_icons_flutter 3.1.24` 与内联 `lucide-static 1.54.0` SVG，所有 UI 资源离线可用。文件选择、二维码、传输和系统分享继续复用现有库。调查结论与取舍见 [架构文档的 UI 第三方库选型](project_architecture/Design.md)。

### 语言

App 与网页支持简体中文和 English，默认跟随系统 / 浏览器语言，不支持的语言回退 English。App 文案维护在 lib/l10n/app_en.arb 与 app_zh.arb，使用 Flutter 官方本地化与 intl 0.20.3；修改资源后执行 flutter gen-l10n。平台显示名和权限说明维护在 macOS / iOS 的 en.lproj、zh-Hans.lproj 与 Android 字符串资源中。用户消息、文件名和设备名保持原值。

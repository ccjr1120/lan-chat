# 局域网互传（lan_chat）

在同一局域网（或手机热点）内，让手机与手机、手机与电脑互传文字和文件。任意一台设备在 App 中「创建会话」后成为主机：

- 其他手机用本 App 加入（自动发现或输入地址）；
- 电脑无需安装，用浏览器扫码或输入地址就能使用网页版。

主机可以选择「无需认证」或「需确认」两种访问模式，并且随时切换。聊天记录和文件只保存在主机上，不经过任何外部服务器。

### 支持平台

| 平台 | 形式 | 系统要求 | 可作为主机 |
| --- | --- | --- | --- |
| Android | App（APK） | Android 7.0+ | 是 |
| iOS | App（未签名 IPA） | iOS 15+ | 是 |
| macOS | App | macOS 12+ | 是 |
| 电脑浏览器 | 网页端，由主机 App 提供 | Chrome / Edge / Safari / Firefox 近两年版本 | 否 |

## 下载与安装

所有安装包都在 Release 页：<https://github.com/ccjr1120/lan-chat/releases/tag/v1.0.0>

| 平台 | 下载 |
| --- | --- |
| Android | [lan-chat-v1.0.0-android.apk](https://github.com/ccjr1120/lan-chat/releases/download/v1.0.0/lan-chat-v1.0.0-android.apk) |
| macOS | [lan-chat-v1.0.0-macos.zip](https://github.com/ccjr1120/lan-chat/releases/download/v1.0.0/lan-chat-v1.0.0-macos.zip) |
| iOS（未签名） | [lan-chat-v1.0.0-ios-unsigned.ipa](https://github.com/ccjr1120/lan-chat/releases/download/v1.0.0/lan-chat-v1.0.0-ios-unsigned.ipa) |
| 校验值 | [SHA256SUMS.txt](https://github.com/ccjr1120/lan-chat/releases/download/v1.0.0/SHA256SUMS.txt) |
| 电脑网页端 | 无需下载，由主机 App 提供 |

`SHA256SUMS.txt` 是各安装包的 SHA-256 校验值，可用 `shasum -a 256 -c SHA256SUMS.txt` 核对。

### Android

下载 APK 后在手机上打开安装，系统提示时允许「安装未知应用」。安装包使用调试证书签名：可以正常安装使用，但与将来使用正式证书签名的版本签名不同，届时需要先卸载再安装。

### macOS

解压 zip 得到 `lan_chat.app`，拖到「应用程序」文件夹。应用只做了本地临时签名、没有经过 Apple 公证，首次打开时需要在「访达」中右键（或按住 Control 点按）应用，选择「打开」并确认，之后可正常双击打开。

### iOS

IPA 未签名，不能直接安装。需要用自己的 Apple 开发者账号重新签名后再安装到设备（例如使用 Xcode 或其他签名工具），或参考下文「从源码构建」直接用 Xcode 安装到真机。

### 电脑网页端

无需安装。主机 App 开启会话后，在浏览器中输入聊天页显示的地址，或扫描二维码即可使用。

## 快速上手

1. 两台设备连上同一个 Wi-Fi（没有 Wi-Fi 时见下文「热点模式」）；
2. 在一台设备上打开 App，点「创建会话」，进入聊天页；
3. 另一台手机打开 App，在首页「附近的会话」里点击该会话加入；电脑则在浏览器中输入聊天页顶部显示的地址（例如 `http://192.168.1.8:8686`）；
4. 发送文字或文件，所有在线设备都能收到。

## 使用说明

### 开启主机

App 首页点击「创建会话」后直接进入聊天页，顶部的邀请条显示访问地址，例如 `http://192.168.1.8:8686`（端口 8686 被占用时会自动换成其他端口，以页面显示为准）。邀请条可展开，展开后显示：

- 网页访问二维码；
- 其他可用地址；
- 「刷新地址」按钮（切换网络后使用）；
- 「新设备加入需要确认」开关。

离开聊天页（返回或菜单中的「结束会话」）即结束会话；如果有其他设备在线，会先弹窗确认。

### 用 App 加入

另一台手机打开 App，首页的「附近的会话」列表会通过 mDNS 自动发现同一网络中的主机：

- 点击列表项即可加入；
- 如果没有自动发现，在「输入会话地址」中填入 `192.168.1.8:8686`，回车或点右侧箭头连接。

在线设备可在聊天页顶栏的下拉菜单中查看。

### 用电脑网页加入

- 电脑浏览器直接输入主机聊天页上显示的地址，例如 `http://192.168.1.8:8686`；
- 或者用另一台手机的相机扫描二维码，在浏览器中打开。

网页端支持发送文字（Enter 发送，Shift+Enter 换行）、点附件图标选择文件、把文件拖拽到页面、粘贴截图。断线后会自动重连。头部「在线 N」可查看在线设备，设置按钮中可切换主题、语言和修改显示名称。

### 访问模式

| 模式 | 开关状态 | 行为 |
| --- | --- | --- |
| 无需认证（open） | 「新设备加入需要确认」关闭 | 局域网内任何设备直接加入 |
| 需确认（approval） | 「新设备加入需要确认」打开 | 新设备（网页或 App）加入时，主机 App 弹窗询问，对方显示「等待主机确认」。同意后进入会话；拒绝则断开，对方会看到提示 |

- 切换方式：在聊天页展开顶部邀请条，拨动「新设备加入需要确认」开关，即时生效。切到「无需认证」时，正在等待的设备会被直接放行。
- 已同意的设备在本次会话期间断线重连不需要再次确认；结束会话后重新开启需要重新确认。
- 设备身份：App 使用本机生成的设备 ID；网页端把 ID 保存在浏览器 localStorage 中，清除浏览器数据后会被视为新设备。

### 传文件

- 网页端：点附件图标多选文件、拖拽文件到页面或粘贴截图。上传时显示进度，可取消或移除失败项；点击文件消息即可下载，图片会显示预览。
- App：在聊天页点击文件会先下载再用系统应用打开，分享按钮可以把文件转到其他应用。
- 上传不支持断点续传，中断后需要重新发送。

### 热点模式（没有 Wi-Fi 时）

1. 主机手机开启「个人热点」；
2. 电脑或其他手机连接该热点；
3. 主机 App 创建会话（如果已经开启，在邀请条中点「刷新地址」），使用页面上显示的地址访问。常见网段：Android 为 `192.168.43.x` 等，iPhone 为 `172.20.10.1`。

热点模式下 mDNS 自动发现可能不可用，请用二维码或手动输入地址。

### 个性化设置

App 右上角设置菜单提供：

- 主题：跟随系统 / 浅色 / 深色；
- 语言：跟随系统 / 简体中文 / English（不支持的系统语言回退 English）；
- 设备名称：在菜单中直接输入，回车保存，下次开启或加入会话时生效。

网页端头部的设置按钮提供同样三组选项，保存在浏览器本地；修改名称后重连生效。

### 数据存储与清空记录

- 聊天记录只保存在主机：`<ApplicationSupport>/history.jsonl`（JSON Lines）；客户端不保存聊天记录，连接后从主机同步最近 500 条；
- 文件保存在主机的 `<Documents>/files/<文件ID>/<文件名>`。iOS 可在「文件」App →「我的 iPhone」→「局域网互传」中查看；
- 主机可在聊天页菜单中点「清空聊天记录」，消息和主机保存的文件会同时删除，所有设备同步清空，无法恢复。

## 常见问题

**搜不到附近的会话？**
确认两台设备在同一网络。部分公共或企业 Wi-Fi 开启了 AP 隔离，设备之间无法互访；也有路由器会屏蔽组播，导致 mDNS 自动发现失败。此时可以手动输入地址、扫描二维码，或改用热点模式。

**iOS 上其他设备连不上，或搜不到会话？**
首次开启服务或搜索设备时，系统会请求「本地网络」权限。如果拒绝了，需要到「设置 → 隐私与安全性 → 本地网络」重新开启，否则其他设备无法连接。

**主机切到后台后其他设备断开了？**
iOS 应用进入后台后很快会被挂起，服务随之中断；Android 后台也可能被系统回收。传输期间请保持主机 App 在前台、屏幕常亮。

**主机改了设备名称，其他设备看到的还是旧名字？**
设备名称在下次开启或加入会话时才生效，会话进行中修改不会立即更新。

**电脑浏览器打不开主机地址？**
确认电脑与主机在同一网络（或已连接主机热点），并使用主机聊天页上当前显示的地址和端口（8686 被占用时会换成其他端口）；切换网络后在邀请条中点「刷新地址」。注意地址是 `http://` 而不是 `https://`。网页端需要现代浏览器（Chrome / Edge / Safari / Firefox 近两年版本）。

**macOS 提示「无法打开，因为无法验证开发者」？**
macOS 版本没有经过 Apple 公证，会被 Gatekeeper 拦截。在「访达」中右键（或按住 Control 点按）`lan_chat.app`，选择「打开」并确认即可，之后可以正常双击打开。也可以在「系统设置 → 隐私与安全性」中点「仍要打开」。

**传输安全吗？**
通信为明文 HTTP/WS，没有 TLS 和端到端加密，只适合在可信的局域网中使用。「需确认」模式只控制谁能加入会话，不能防止同一网络中的流量嗅探。

## 从源码构建

环境要求：

- Flutter 3.38.1 及以上（开发验证版本：Flutter 3.47.7 / Dart 3.13.5）
- Android：Android SDK；iOS / macOS：Xcode

开发运行：

```bash
flutter pub get
flutter devices          # 查看已连接设备
flutter run -d <设备ID>
```

Release 构建：

```bash
flutter build apk --release              # 产物：build/app/outputs/flutter-apk/app-release.apk
flutter build macos --release            # 产物：build/macos/Build/Products/Release/lan_chat.app
flutter build ios --release --no-codesign  # 产物：build/ios/iphoneos/Runner.app（未签名）
```

- Android release 构建当前使用调试证书签名，正式分发前请配置自己的签名。
- iOS 需要签名才能装到真机：在 Xcode 打开 `ios/Runner.xcworkspace`，在 Signing & Capabilities 中选择开发团队，并按需修改 Bundle Identifier（默认 `com.lanchat.lanChat`），然后从 Xcode 运行或 Archive。
- 没有 Flutter Web 构建：主机依赖 `dart:io` 的 HTTP 服务和 mDNS 插件，无法在浏览器中运行。电脑使用的网页端是 `assets/web/index.html`，由主机 App 直接在自己的地址上提供，不需要单独的 Web 产物。

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

原生窗口使用本地化产品名（中文「局域网互传」、英文「LAN Chat」）。MainFlutterWindow 通过 MethodChannel 同步 App 主题设置，透明标题栏与页面背景统一，保留原生窗口按钮。InfoPlist.strings / MainMenu.strings 已注册中英文资源；原生修改需完整重新运行 App，热重载无法更新。

- `com.apple.security.network.server` / `network.client`；
- `com.apple.security.files.user-selected.read-write`、`files.downloads.read-write`；
- Info.plist 中同样声明了 `NSLocalNetworkUsageDescription` 与 `NSBonjourServices`。

## 开发

- 架构文档：[project_architecture/Design.md](project_architecture/Design.md)
- Agent 工作流：[AGENTS.md](AGENTS.md) / [AGENTS_WORKFLOW.md](AGENTS_WORKFLOW.md)
- 类型检查：`flutter analyze`
- 界面文案：App 维护在 `lib/l10n/app_en.arb` 与 `app_zh.arb`，修改后执行 `flutter gen-l10n`；平台显示名和权限说明维护在 macOS / iOS 的 en.lproj、zh-Hans.lproj 与 Android 字符串资源中。

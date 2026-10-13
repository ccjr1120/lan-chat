# 局域网互传 · 项目架构

## 项目边界

- 同一局域网（含手机热点）内设备之间的文字与文件互传，不经过公网、无账号体系。
- 一台设备以「主机」模式运行 App，内置 HTTP + WebSocket 服务；其他设备以 App 客户端或浏览器（网页端）接入。
- 聊天记录与文件由主机保存；客户端只在需要时下载文件到本地。
- 不包含：公网中继、端到端加密、TLS、多主机互联、离线消息推送。

## 技术栈

| 领域 | 选型（版本锁定见 `pubspec.yaml`） |
| --- | --- |
| 框架 | Flutter 3.47 / Dart 3.13，Material 3 |
| HTTP/WS 服务 | shelf 1.4.2、shelf_router 1.1.4、shelf_web_socket 3.0.0 |
| WS 客户端 | web_socket_channel 3.0.3 |
| HTTP 传输（进度） | dio 5.11.1 |
| 设备发现 | bonsoir 7.1.5（mDNS，服务类型 `_lanchat._tcp`） |
| 本地网络信息 | network_info_plus 8.2.1（8.2.2 与 bonsoir 7.1.5 的 dbus 依赖冲突） |
| 文件 | file_picker 13.1.0、path_provider 2.1.6、open_filex 4.7.0、share_plus 13.3.1、mime 2.1.0 |
| 本地化 | flutter_localizations（随 Flutter SDK 锁定）、intl 0.20.3；ARB + Flutter gen-l10n |
| 其他 | qr_flutter 4.1.0、uuid 4.6.0、path 1.9.1 |
| 图标 | App：lucide_icons_flutter 3.1.24；网页：lucide-static 1.54.0 的 5 个内联 SVG（保留上游许可） |
| 网页端 | 原生 HTML/CSS/JS 单文件，主机从 rootBundle 读取托管 |

## 整体结构

```
lib/
  main.dart / app.dart        启动：打开存储 → MaterialApp → 首页
  core/                       模型、协议事件、会话抽象（无平台依赖）
  storage/                    设置、聊天记录（JSON Lines）、文件存储
  discovery/                  mDNS 广播与发现
  server/                     主机：shelf 服务、访问控制、主机会话
  client/                     客户端：WS 连接、dio 上传下载、客户端会话
  ui/                         App 界面（首页、聊天页、共享组件、主题）
  l10n/                       中英文 ARB、生成代码、UI 本地化辅助方法
assets/web/index.html         网页端单页聊天界面
android/ ios/ macos/          flutter create 生成，补充网络权限
```

## 模块地图

| 模块 | 文档 | 实现位置 |
| --- | --- | --- |
| core | [modules/core/Design.md](modules/core/Design.md) | `lib/core/` |
| storage | [modules/storage/Design.md](modules/storage/Design.md) | `lib/storage/` |
| discovery | [modules/discovery/Design.md](modules/discovery/Design.md) | `lib/discovery/` |
| server | [modules/server/Design.md](modules/server/Design.md) | `lib/server/` |
| client | [modules/client/Design.md](modules/client/Design.md) | `lib/client/` |
| app_ui（前端） | [modules/app_ui/Design.md](modules/app_ui/Design.md) | `lib/ui/` |
| web_ui（前端） | [modules/web_ui/Design.md](modules/web_ui/Design.md) | `assets/web/index.html` |

## 跨模块依赖

```
app_ui ──> server(HostSession) ──> storage, discovery(LanBroadcaster), core
   │  └──> client(ClientSession) ──> storage, core
   └────> discovery(LanDiscovery)
web_ui ──(HTTP/WS)──> server
client ──(HTTP/WS)──> server
```

- `core` 不依赖其他业务模块；`ChatSession` 是 UI 与主机/客户端实现之间的唯一接口。
- `server` 与 `client` 互不依赖，只通过协议交互。

## 通信协议

主机监听 `0.0.0.0:8686`（被占用时由系统分配端口），明文 HTTP/WS。

### WebSocket `/ws`

帧格式：`{"type": string, "data": any}`。

| 方向 | type | data |
| --- | --- | --- |
| C→H | `hello` | `{deviceId, name, platform: app\|web}`，连接后 10 秒内必须发送 |
| C→H | `message` | `{text}`（≤ 20000 字符） |
| H→C | `pending` | `{message}`：需确认模式下等待主机同意 |
| H→C | `welcome` | `{self, host, token, accessMode}`：已加入会话 |
| H→C | `rejected` | `{reason}`：被拒绝，随后关闭连接 |
| H→C | `peers` | `Peer[]`：在线设备（含主机） |
| H→C | `history` | `ChatMessage[]`：最近 500 条，空数组表示已清空 |
| H→C | `message` | `ChatMessage`：新消息广播 |
| H→C | `error` | `{message}` |

### HTTP

| 接口 | 鉴权 | 说明 |
| --- | --- | --- |
| `GET /`、`/index.html` | 无 | 网页端页面 |
| `GET /api/info` | 无 | `{app:'lanchat', version, name, deviceId, accessMode}`，客户端用来确认地址 |
| `GET /api/history?limit=` | token | 历史消息 |
| `POST /api/upload?name=` | token | multipart/form-data，取第一个文件分段；`name` 为 UTF-8 文件名 |
| `GET /api/files/<id>?download=1` | token | 文件下载，支持单段 `Range`（206/416） |

token 通过 `?token=` 或 `Authorization: Bearer` 传递。它只在对应 WS 连接已加入会话期间有效，连接断开即失效。

## 关键架构决策

1. **主机为唯一事实来源**：消息 ID、时间戳由主机分配，写入 `history.jsonl` 后广播；客户端不持久化聊天记录，重连后由 `history` 全量覆盖。
2. **访问控制**（主机可随时切换，持久化在设置中）：
   - 无需认证（`open`）：hello 后直接加入。
   - 需确认（`approval`）：hello 后进入 pending，主机 App 弹窗确认；同意后该设备 ID 在本次服务运行期间免确认（断线重连不重复弹窗），拒绝则发送 `rejected` 并断开。切换到 `open` 时，等待中的请求全部放行。
   - HTTP 接口依赖 WS 加入后下发的 token，未加入的设备无法读取历史或文件。
3. **网页端离线自包含**：单个 HTML 文件，通过 rootBundle 读取后内存托管；Lucide SVG 内联在 HTML 中并保留许可，无 CDN、运行时第三方 JS 或构建步骤。
4. **文件名传输**：上传时文件名同时放在查询参数 `name` 中，规避各客户端对 multipart `filename` 非 ASCII 字符编码不一致的问题。
5. **存储位置**：设置和历史放在 ApplicationSupport，文件放在 `Documents/files/<fileId>/<name>`（iOS 可在“文件”App 查看）。
6. **安全边界**：仅适用于可信局域网；通信为明文，token 仅用于区分是否已加入会话。

## UI 第三方库选型（2026-10-10）

本次 UI 优化沿用 Flutter Material 3 与原生 HTML/CSS/JS。App 通过 `lucide_icons_flutter 3.1.24` 使用 Lucide 线性图标；该社区封装仅依赖 Flutter，支持 Android / iOS / macOS，采用 MIT 许可。网页内联 `lucide-static 1.54.0` 的 SVG，并保留 ISC / Feather MIT 许可，不通过公网拉取字体、图标或脚本。

| 功能 | 采用的库（准确版本见 pubspec.yaml） | 判断 |
| --- | --- | --- |
| HTTP 主机 / WebSocket | shelf、shelf_router、shelf_web_socket、web_socket_channel | 保留已有库，业务层仅实现会话协议与访问控制 |
| 上传下载与进度 | dio | 保留已有库；网页 XHR 已支持进度，无需新依赖 |
| 局域网发现 | bonsoir | 已封装 mDNS 广播和发现，继续使用 |
| 文件选择 / 打开 / 分享 | file_picker、open_filex、share_plus | 继续复用平台插件 |
| 二维码 | qr_flutter | 继续复用，不手写编码器 |
| 图标 | lucide_icons_flutter / lucide-static | 新增并锁定版本，两端离线使用 |
| 完整聊天 UI | flutter_chat_ui（调查时为 2.12.0） | 支持自定义 builder 与独立后端；本次暂不采用，额外消息模型和控制器需要适配现有 ChatSession、上传队列与按需下载，不足以减少本次改版复杂度 |

参考：[Lucide Flutter 包](https://pub.dev/packages/lucide_icons_flutter)、[Lucide 官方文档](https://lucide.dev/guide/lucide)、[Flyer Chat](https://pub.dev/packages/flutter_chat_ui)、[Bonsoir](https://pub.dev/packages/bonsoir)、[Dio](https://pub.dev/packages/dio)、[file_picker](https://pub.dev/packages/file_picker)、[qr_flutter](https://pub.dev/packages/qr_flutter)、[share_plus](https://pub.dev/packages/share_plus)。实际跨平台运行兼容性仍需真机确认。

## App 主题、系统标题与桌面工作区

App 在 `lib/app.dart` 配置浅色 / 深色 ThemeData。右上角共享设置菜单（SettingsMenu）提供主题（跟随系统 / 浅色 / 深色）与界面语言（跟随系统 / 简体中文 / English）两组选项，初始均跟随系统。选项通过 SettingsStore 的 `themeMode`、`locale` 持久化，旧设置文件缺失字段时回退为 system；MaterialApp（themeMode、locale）与 AppPreferences 监听设置更新。`lib/ui/theme.dart` 的 AppColors ThemeExtension 提供语义配色（含 primaryGradient / glow 派生强调 token），首页、聊天页及共享组件从当前 BuildContext 读取；网页 CSS 同步明暗变量（含 `--primary-2`、`--glow`），默认通过 prefers-color-scheme 跟随浏览器系统外观，头部设置菜单可固定浅色 / 深色（`<html data-theme>`）。

首页宽度 ≥ 900 时采用最大宽度 1440 的操作双栏：左侧为创建 / 运行中的会话面板，右侧为设备身份和加入入口，比例 7:4、间距 24；其他宽度使用最大宽度 620 的单列。独立宣传 banner 与桌面统计卡移除，连接方式示意嵌入创建会话卡片。会话页仍在 900 / 1280 宽度分别显示在线设备栏与最近文件栏，辅助信息来自现有 HostSession / ChatSession。

首页与聊天页共享 WorkspaceBackground：background 纯色为底，顶部叠加极淡 primary 光晕（glow token 的径向渐变，终止色为 background），基底与 macOS 标题栏背景保持一致，衔接无缝。macOS 首页在所有窗口宽度均使用原生产品标题，不显示重复 AppBar；页面右上保留设置菜单，加入模式在正文提供返回入口。MainFlutterWindow 通过 `lanchat/window` MethodChannel 的 `setStyle` 接收本地化产品名与 themeMode，原生标题栏透明并与 Flutter 背景一致；system 时继承系统 appearance，light / dark 时设置对应 NSAppearance。effectiveAppearance 观察负责系统外观变化和背景更新。原生窗口按钮与标题区域保留。

App 微动效统一为 200ms easeOutCubic，集中在 `lib/ui/widgets/motion.dart`（AppMotion 常量、FadeSlideIn 入场、HoverLift 桌面悬停微提升、GradientFilledButton 渐变主按钮），不新增依赖；主题切换为 250ms 淡入淡出（MaterialApp themeAnimationDuration/Curve）。AppColors 的派生强调 token：primaryGradient（light `#3458E8→#4A76FF`，dark `#8BA4FF→#6C8CFF`）用于主操作按钮与自己发送的气泡，glow（primary 6–8% 透明度）用于工作区顶部光晕；网页端以 `--primary-2`、`--glow` CSS 变量与之一致。

## 中英文本地化

App 使用 Flutter SDK 的 flutter_localizations 与 intl 0.20.3，`lib/l10n/app_en.arb` / `app_zh.arb` 是文案来源，`l10n.yaml` 配置生成同目录 AppLocalizations。MaterialApp 的 delegates、supportedLocales、onGenerateTitle 默认跟随系统语言，支持中文和英文，其他语言回退英文；设备 / 文件数量使用 ICU 复数，日期格式按 locale 展示。UiStrings 在显示边界本地化平台标签和既有协议诊断文本，协议字段与事件不变，不翻译用户消息、文件名或设备名。

macOS / iOS 使用 en.lproj 与 zh-Hans.lproj 的 InfoPlist.strings 本地化显示名与权限说明；macOS MainMenu.strings 同步菜单标题，Xcode 注册语言资源。Android 使用 values / values-zh 的 app_name 资源。产品中文名为“局域网互传”，英文名为“LAN Chat”；编译产物和 Bundle ID 保持原有稳定标识。原生资源变更需完整重启 App 才能查看，热重载不更新它们。

网页端保持单 HTML 离线自包含，内联中英文词典，默认按 navigator.languages 选择支持语言（其他语言回退英文），也可在头部设置菜单固定为中文 / 英文并即时重渲染，不刷新页面、不断开连接；静态标签、可访问名称、状态提示与日期一起本地化。协议与上传 / 下载逻辑继续沿用现有实现。

参考：[Flutter 官方本地化](https://docs.flutter.dev/ui/internationalization)。具体实现及影响见 app_ui、storage、web_ui 模块文档。

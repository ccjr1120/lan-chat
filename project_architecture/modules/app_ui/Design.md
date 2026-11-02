# app_ui 模块（前端）

## 职责

Flutter App 界面：创建/加入会话、访问地址与二维码、访问控制切换、加入请求确认、聊天与文件收发。

## 页面索引

| 页面 | 文档 | 入口 |
| --- | --- | --- |
| 首页 | [pages/home/Design.md](pages/home/Design.md) | `lib/ui/pages/home/home_page.dart` |
| 聊天页 | [pages/chat/Design.md](pages/chat/Design.md) | `lib/ui/pages/chat/chat_page.dart` |

## 内部结构

| 文件 | 说明 |
| --- | --- |
| `lib/app.dart` | `LanChatApp`（MaterialApp，持久化主题、本地化 delegates、首页） |
| `lib/ui/theme.dart` | `AppColors` ThemeExtension 与 `buildAppTheme(brightness)`，提供明暗语义纯色配色（无渐变、光晕与卡片阴影），网页端 CSS 变量与之保持一致，统一按钮/输入框/弹层规范 |
| `lib/ui/format.dart` | 文件大小、按 locale 格式化消息日期 |
| `lib/l10n/`、`l10n.yaml` | 中英文 ARB、gen-l10n 生成代码、UiStrings 显示边界辅助方法 |
| `lib/ui/theme_controller.dart` | AppPreferences 将主题、语言、设备名称及更新回调传给页面 |
| `lib/ui/widgets/settings_menu.dart` | 首页右上角设置菜单：首先显示内联设备名称输入（回车保存），再显示主题和语言选项 |
| `lib/ui/widgets/native_window_theme.dart` | 向 macOS MethodChannel 同步本地化原生标题及主题 |
| `lib/ui/widgets/host_address_card.dart` | 共享组件：二维码、各访问地址、刷新地址与"加入需确认"开关；主机聊天页通过右上角按钮显示为覆盖聊天主体的面板 |
| `lib/ui/widgets/feature_icon.dart` | 共享品牌色装饰图标，用于首页、聊天空态和连接信息，不重复朗读 |
| `lib/ui/widgets/motion.dart` | 共享动效：AppMotion（200ms easeOutCubic）、`AppMotion.durationOf`（系统关闭动画时为零，供隐式动画使用）、FadeSlideIn 入场（淡入+上移 8px，尊重系统关闭动画；`enabled` 仅在首次构建时读取，延迟计时器不重复创建） |
| `lib/ui/widgets/workspace_panel.dart` | 共享工作区背景 WorkspaceBackground（background 纯色底，与 macOS 标题栏无缝） |
| `lib/ui/widgets/join_request_dialog.dart` | 共享弹窗：新设备加入确认（同意/拒绝）。请求失效时（设备断开或切换为无需认证）自动关闭 |
| `lib/ui/widgets/message_bubble.dart` | 共享组件：消息行按发送方对齐（`Align`：自己靠右、他人靠左，不受父级 Column 居中影响）；文字气泡（长按复制，自己的气泡为 selfBubble 浅底）、文件气泡（点击打开、分享按钮、下载进度为 64px MascotProgress、本地图片预览；surface 底色，尾角与水波纹形状跟随发送方）、发送中气泡（MascotProgress 进度 + 已传/总量百分比文字 / 失败） |
| `lib/ui/widgets/mascot_painter.dart` | 蓝猫几何绘制：MascotSpec（light/dark 调色板、帧表、BLINK/EAR 表、静态帧 k、`kAt` 帧时序）、MascotParams.anim（对应 animParams）、MascotPainter（CustomPainter，100×100 局部坐标，含 mini 分支）。与 `assets/web/index.html` mascot 脚本块逐行一致，修改须两端同步 |
| `lib/ui/widgets/mascot.dart` | 吉祥物组件：MascotLogo（静态猫脸 + 底板，<64px 自动 mini，语义标签为产品名）、MascotLoader（A/B/D 循环动画，AnimationController.repeat + RepaintBoundary；disableAnimations 时停止并显示静态帧，TickerMode 停止不可见路由）、MascotProgress（C，按真实进度绘制，进度变化用 TweenAnimationBuilder 平滑，系统关闭动画时直接跳到目标值，自身不朗读，沿用旁边百分比文字） |

## 会话所有权

- 主机会话（`HostSession`）由首页创建并持有，创建后立即进入聊天页；离开聊天页（返回键）即结束会话，仅当有其他设备在线时先确认。
- 加入请求弹窗由首页监听 `HostSession` 后统一弹出（经由根 Navigator，聊天页打开时同样可见），一次只弹一个。
- 客户端会话（`ClientSession`）由聊天页持有（`ownsSession: true`），返回首页即断开。

## 依赖关系

- 依赖：`core`（ChatSession 等）、`server`（HostSession）、`client`（ClientSession）、`discovery`（LanDiscovery）、`storage`（AppStorage）。
- 第三方：qr_flutter、file_picker、open_filex、share_plus、lucide_icons_flutter 3.1.24（统一线性图标）、flutter_localizations（SDK）、intl 0.20.3。

## 变更影响

- `ChatSession` 接口变更会影响聊天页和气泡组件。
- 视觉规范变更需同步 `assets/web/index.html` 的 `:root` CSS 变量。
- 吉祥物几何、调色板或帧参数变更需同步 `assets/web/index.html` 的 mascot 脚本块，并重新运行 `tool/mascot/render_icons.mjs` 生成应用图标。

## 布局与共享组件

首页是单屏单列（最大宽度 620）：标题、当前设备名、一张分区排列创建按钮和连接地址输入框的卡片（支持 IP、IP:端口与完整 http 地址）。macOS 设置菜单放在正文标题行右侧；其他平台放在 AppBar 右侧。

聊天页消息区与输入栏最大宽度 880。顶栏为在线设备下拉与主机连接信息按钮。邀请信息默认隐藏，按钮可切换覆盖整个聊天主体的面板，详见聊天页文档。

自己发送的文字气泡使用 selfBubble 浅底、正文色文字，对方气泡与文件卡使用 surface；主操作按钮使用主题 FilledButton，二维码保留白底以便扫描。

## 主题与本地化

LanChatApp 监听 SettingsStore，初始主题 system，支持持久化 light / dark 覆盖，AppPreferences 供设置菜单获取与更新主题 / 语言 / 设备名称。所有 AppColors 从当前 ThemeExtension 获取，页面、消息气泡、文件卡、输入框、弹窗和菜单随主题一起更新；主题切换为 250ms 淡入淡出（themeAnimationDuration/Curve）。微动效统一 200ms easeOutCubic：首页区块错峰 FadeSlideIn 入场、消息首次出现入场（已见消息 id 记录，滚动重建不重放）、状态横幅与空态/列表 AnimatedSwitcher 切换、输入栏聚焦边框高亮过渡；系统关闭动画（disableAnimations）时 FadeSlideIn 直接显示，隐式动画经 `AppMotion.durationOf` 时长为零。macOS 的 lanchat/window → setStyle 接收本地化标题与 themeMode，切换原生 appearance 并更新背景（深色 `#1A1F29`、浅色 `#F7F8FA`，与 AppColors.background 一致）；system 时为 nil，跟随系统 effectiveAppearance。titlebarAppearsTransparent 保留系统窗口控制与标题区域。

lib/l10n 的中英文 ARB 是 App 文案来源，Flutter gen-l10n 生成 AppLocalizations；UiStrings 扩展提供 context.l10n、平台 / 访问方式标签和既有系统诊断文本的展示转换。App 使用官方 Material / Cupertino 本地化 delegates，支持 en / zh，默认跟随系统（不支持的语言回退 en），可在设置菜单中固定为简体中文或 English，经 MaterialApp.locale 即时切换并持久化到 SettingsStore.locale。设备 / 文件数量采用 ICU 复数；日期使用 intl 0.20.3。设备名、文件名、消息正文保持原值。修改 ARB 后需要运行 flutter gen-l10n，生成代码与资源一并维护。

平台产品显示名为中文"局域网互传"、英文"LAN Chat"，macOS / iOS InfoPlist.strings、macOS MainMenu.strings 和 Android 字符串资源与之保持一致。Xcode 工程注册语言资源，原生窗口新增 MethodChannel；没有 HTTP / WebSocket 协议变更。

设置与在线设备弹出菜单共用主题化圆角、边框和柔和阴影；设置选中项使用品牌浅底。首页分区、聊天空态与连接信息使用主题图标及现有蓝猫组件，无新增图片资源或依赖。

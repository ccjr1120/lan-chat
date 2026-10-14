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
| `lib/ui/theme.dart` | `AppColors` ThemeExtension 与 `buildAppTheme(brightness)`，提供明暗语义配色（含 primaryGradient / glow 派生强调 token、浅色卡片极轻阴影），网页端 CSS 变量与之保持一致，统一按钮/输入框/弹层规范 |
| `lib/ui/format.dart` | 文件大小、按 locale 格式化消息日期 |
| `lib/l10n/`、`l10n.yaml` | 中英文 ARB、gen-l10n 生成代码、UiStrings 显示边界辅助方法 |
| `lib/ui/theme_controller.dart` | AppPreferences 将主题、语言选项及更新回调传给页面 |
| `lib/ui/widgets/settings_menu.dart` | 首页 / 聊天页右上角共享设置菜单：主题（system / light / dark）与语言（system / zh / en）两组单选，勾选显示当前选项 |
| `lib/ui/widgets/native_window_theme.dart` | 向 macOS MethodChannel 同步本地化原生标题及主题 |
| `lib/ui/widgets/host_address_card.dart` | 共享组件：二维码、主地址复制、其他地址折叠、刷新地址与加入方式弹层；首页和聊天页底部弹层共用 |
| `lib/ui/widgets/motion.dart` | 共享动效与强调组件：AppMotion（200ms easeOutCubic）、`AppMotion.durationOf`（系统关闭动画时为零，供隐式动画使用）、FadeSlideIn 入场（淡入+上移 8px，尊重系统关闭动画；`enabled` 仅在首次构建时读取，延迟计时器不重复创建）、HoverLift 桌面悬停微提升、GradientFilledButton 渐变主按钮（声明 button/enabled 语义，禁用态退化中性色） |
| `lib/ui/widgets/workspace_panel.dart` | 共享工作区背景（background 纯色底 + 顶部极淡 glow 光晕，渐变终止于 background，与 macOS 标题栏无缝）、创建会话卡片内的 ConnectionDiagram 连接方式示意 |
| `lib/ui/widgets/join_request_dialog.dart` | 共享弹窗：新设备加入确认（同意/拒绝）。请求失效时（设备断开或切换为无需认证）自动关闭 |
| `lib/ui/widgets/message_bubble.dart` | 共享组件：消息行按发送方对齐（`Align`：自己靠右、他人靠左，不受父级 Column 居中影响）；文字气泡（长按复制，自气泡使用前景色半透明选区）、文件气泡（点击打开、分享按钮、下载进度、本地图片预览；surface 底色，尾角与水波纹形状跟随发送方）、发送中气泡（进度/失败） |

## 会话所有权

- 主机会话（`HostSession`）由首页持有。进入、返回聊天页时服务保持运行；只有点击「结束会话」或在会话视图返回首页并确认，或首页销毁时才停止。
- 加入请求弹窗由首页监听 `HostSession` 后统一弹出（经由根 Navigator，聊天页打开时同样可见），一次只弹一个。
- 客户端会话（`ClientSession`）由聊天页持有（`ownsSession: true`），返回首页即断开。

## 依赖关系

- 依赖：`core`（ChatSession 等）、`server`（HostSession）、`client`（ClientSession）、`discovery`（LanDiscovery）、`storage`（AppStorage）。
- 第三方：qr_flutter、file_picker、open_filex、share_plus、lucide_icons_flutter 3.1.24（统一线性图标）、flutter_localizations（SDK）、intl 0.20.3。

## 变更影响

- `ChatSession` 接口变更会影响聊天页和气泡组件。
- 视觉规范变更需同步 `assets/web/index.html` 的 `:root` CSS 变量。

## 响应式布局与共享组件

首页分为首页 / 会话已开启 / 加入会话三个互斥视图：首页只有一张会话卡，上半部分创建会话、「或」分隔、下方一个「加入会话」按钮；加入视图显示附近会话实时列表（点击即加入，手动地址走弹窗）；会话视图只显示邀请内容。返回按钮与系统返回键回到首页（会话视图需确认结束会话）。所有宽度均使用最大宽度 620 的居中单列。连接示意嵌入会话卡创建区，改名入口为首页标题下的设备名胶囊。macOS 无论宽度均使用原生产品标题，首页不显示重复 AppBar，设置菜单放在正文标题行右侧，子视图在标题行左侧提供返回按钮；其他平台 AppBar 右侧为设置菜单。内容整体可滚动，适配低高度窗口。

聊天页宽度 ≥ 900 时显示 256 宽的在线设备侧栏，≥ 1280 时增加 288 宽的最近文件栏；中间消息区与输入栏最大宽度 880。最近文件取自当前同步的消息，显示总数量和大小，最多展示最近 12 个；点击复用 `ensureLocal` 与系统打开流程，正在下载时显示进度并禁用重复点击。清空记录后文件栏同步清空。宽屏已连接空会话显示文件发送/邀请操作卡；其他连接状态保持原有状态视图。

共享 `WorkspaceBackground` 以 background 纯色为底、顶部叠加极淡 primary 光晕（glow token，径向渐变终止于 background），与 macOS 标题栏背景保持一致，无新增依赖或图片。首页 `_FeatureIcon` 统一设备/操作图标底板；`HostAddressCard` 聚焦扫码邀请、主地址复制和加入方式设置，额外地址折叠展示。文件卡片使用主题 surface；自己发送的文字气泡使用 primaryGradient 渐变（前景色与 ColorScheme.onPrimary 一致），对方气泡保持 surface；主操作按钮（创建/进入会话、连接设备、选择文件发送）使用 GradientFilledButton 渐变样式，二维码保留白底以便扫描。

## 主题与本地化

LanChatApp 监听 SettingsStore，初始主题 system，支持持久化 light / dark 覆盖，AppPreferences 供设置菜单获取与更新主题 / 语言选项。所有 AppColors 从当前 ThemeExtension 获取，页面、消息气泡、文件卡、输入框、弹窗和弹层随主题一起更新；主题切换为 250ms 淡入淡出（themeAnimationDuration/Curve）。微动效统一 200ms easeOutCubic：首页区块错峰 FadeSlideIn 入场、消息首次出现入场（已见消息 id 记录，滚动重建不重放）、状态横幅与空态/列表 AnimatedSwitcher 切换、输入栏聚焦边框高亮过渡、桌面卡片 HoverLift 悬停微提升；系统关闭动画（disableAnimations）时 FadeSlideIn 直接显示，横幅、主体切换、输入栏聚焦与 HoverLift 等隐式动画经 `AppMotion.durationOf` 时长为零。macOS 的 lanchat/window → setStyle 接收本地化标题与 themeMode，切换原生 appearance 并更新背景；system 时为 nil，跟随系统 effectiveAppearance。titlebarAppearsTransparent 保留系统窗口控制与标题区域。

lib/l10n 的中英文 ARB 是 App 文案来源，Flutter gen-l10n 生成 AppLocalizations；UiStrings 扩展提供 context.l10n、平台 / 访问方式标签和既有系统诊断文本的展示转换。App 使用官方 Material / Cupertino 本地化 delegates，支持 en / zh，默认跟随系统（不支持的语言回退 en），可在设置菜单固定为简体中文或 English，经 MaterialApp.locale 即时切换并持久化到 SettingsStore.locale。设备 / 文件数量采用 ICU 复数；日期使用 intl 0.20.3。设备名、文件名、消息正文保持原值。修改 ARB 后需要运行 flutter gen-l10n，生成代码与资源一并维护。

平台产品显示名为中文“局域网互传”、英文“LAN Chat”，macOS / iOS InfoPlist.strings、macOS MainMenu.strings 和 Android字符串资源与之保持一致。Xcode 工程注册语言资源，原生窗口新增 MethodChannel；没有 HTTP / WebSocket 协议变更。

# 聊天页（App）

## 路由

从首页 `Navigator.push(MaterialPageRoute)` 进入：`ChatPage(session, ownsSession)`。主机会话 `ownsSession=false`，客户端会话为 `true`。

## 页面结构

所有宽度均为单列（消息区与输入栏最大宽度 880），没有设备侧栏、文件栏、底部详情弹层或桌面开始面板。

- AppBar：本地化标题（主机为「我的会话」，客户端为主机名）、副标题（连接状态 / 在线数）。右侧依次为：
  - 共享设置菜单（主题、语言、设备名称）。
  - 在线设备下拉（图标 + 数量）：列出每台设备的名称与平台，自己标注“我”。
  - 主机菜单：清空聊天记录（二次确认）、结束会话。
- 返回与结束：客户端返回即断开。主机返回 / “结束会话”即结束会话并回到首页；仅当有其他设备在线时，通过 `PopScope` 与 `AlertDialog` 先确认（继续会话 / 结束会话），无人在线时直接结束。
- 状态横幅：连接中、已断开（客户端有「立即重试」）；出现/消失与文案变化以 AnimatedSize + AnimatedSwitcher（滑动+淡入，200ms easeOutCubic）过渡。
- 邀请条（仅主机，`_InviteBar`）：收起时一行显示主地址、复制按钮和展开按钮；展开（进入页面时默认展开）显示 `HostAddressCard`——二维码、其他地址折叠、刷新地址和“新设备加入需要确认”开关（即时切换访问模式）。展开内容限制在屏幕高度 55% 内可滚动，AnimatedSize 过渡。
- 消息列表：`MessageBubble` 和发送中的 `OutgoingTransferBubble`。自己发送的消息靠右、其他设备的消息靠左（名称 / 时间行与气泡同侧对齐），发送中气泡靠右。相邻消息间隔大于 5 分钟时显示时间分组；同设备连续消息隐藏重复名称，文件统一使用主题 surface 卡片，自己发送的文字气泡为 selfBubble 浅底，对方气泡为 surface。数量变化时自动滚到底部。新到达的消息 FadeSlideIn 入场（淡入+上移 8px）；已进入过列表的消息 id 记录在 `_seenMessageIds`，滚动重建不重放动画；进入页面时已有的消息以及一次到达多条的历史回填直接显示，不逐条入场。
- 主体区域（等待确认 / 被拒绝 / 空态 / 消息列表）切换时使用 AnimatedSwitcher 淡入淡出，按状态分组键避免列表内更新重放。
- 输入栏：统一容器中的附件按钮（file_picker 多选，逐个发送）、多行输入框、发送按钮（主题 FilledButton 纯色）；Enter 发送、Shift+Enter 换行，输入法组字期间不触发发送；未连接或文本为空时禁用发送。容器聚焦时边框高亮为 primary（AnimatedContainer 200ms 过渡）。系统关闭动画时横幅、主体切换与聚焦过渡均直接切换。
- 工作区背景：共享 WorkspaceBackground（background 纯色底）。

## 交互状态

| SessionStatus | 主体区域 |
| --- | --- |
| `pending` | “等待主机确认”和进度指示 |
| `rejected` | “无法加入会话”、拒绝原因、返回按钮 |
| 列表为空 | 空状态图标和提示（主机的邀请入口在上方邀请条） |
| 其他 | 消息列表 |

文件操作：点击文件时调用 `ensureLocal` 拿到本地路径（客户端按需下载并显示进度），然后用 `OpenFilex.open` 打开；无可用应用时提示改用分享。分享按钮调用 `SharePlus.instance.share(ShareParams(files: [...]))`。

## 数据来源

`ChatSession`：`messages`、`outgoing`、`downloads`、`peers`、`status`。

## 接口依赖

- 主机端：直接调用 `LanServer`（不经 HTTP）。
- 客户端：`/ws`（文字）、`POST /api/upload`、`GET /api/files/<id>`。

## 实现入口

`lib/ui/pages/chat/chat_page.dart`，组件位于 `lib/ui/widgets/message_bubble.dart`。

## 系统明暗主题

聊天页、邀请条、消息气泡、发送进度和输入栏使用当前主题的 AppColors；弹窗与菜单继承同一 ThemeData。浅色 / 深色按全局主题选项更新（250ms 淡入淡出），默认跟随系统实时更新，状态提示保持语义配色。自己发送的文字气泡为 selfBubble 浅底 + 正文色文字，选区使用默认样式。二维码白底保留用于扫码。

## 本地化

所有页面 / 弹层文案、按钮提示、状态标签和系统诊断通过 AppLocalizations / UiStrings 展示，支持跟随系统的中英文。在线设备及文件数量使用 ICU 复数，日期按当前 locale 格式化。系统诊断在展示边界转换，不修改 ChatSession 和协议；用户消息、设备名、文件名保持原值。主题、语言与设备名称设置与首页共用 AppPreferences，可在聊天期间更新。

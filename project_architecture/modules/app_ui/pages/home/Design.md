# 首页（App）

## 路由

App 启动页（`MaterialApp.home`），`HomePage(storage)`。

## 页面结构

首页是单屏单列（最大宽度 620，可用空间内垂直居中，内容超高时整体可滚动），不再有"会话已开启 / 加入会话"子视图和返回按钮：

- 标题与"当前设备 · 名称"（只读文本；改名在设置菜单的"设备名称"里内联完成，新名称下次创建或加入会话时生效）。
- 创建与连接共用一张卡片，分区以品牌色图标标识并以分隔线区分；顶部产品标识沿用蓝猫。创建区包含标题、简短说明、失败原因及「创建会话」按钮，点击后启动 `HostSession` 并直接进入聊天页。
- 连接区：直接显示地址输入框（支持 IP、IP:端口与完整 http 地址，右侧箭头或回车连接，无效地址在输入框内提示），不展示附近会话列表。
- macOS 所有宽度均使用原生产品标题，无重复 AppBar，正文标题行右侧显示设置菜单；其他平台 AppBar 标题为 28px MascotLogo + 产品名，右侧为设置菜单；macOS 在正文标题前显示 40px MascotLogo。

## 交互状态

| 状态 | 表现 |
| --- | --- |
| `_starting` | 创建按钮图标位显示 18px mini 动画 B 并禁用 |
| 创建失败 | 创建卡内显示失败原因，可重试 |
| 主机在聊天页中 | 首页持有 `HostSession`，监听 `pendingRequests`，逐个弹出 `JoinRequestDialog`（弹在聊天页之上） |
| 从聊天页返回 | 主机会话随即结束 |

## 数据来源

- `AppStorage.settings`：设备名、访问模式、主题 / 语言选项（默认 system）。
- `HostSession`：创建会话后的待确认请求。
- 每次创建主机会话前归档旧记录，新会话从空记录开始，原有文件保留。

## 接口依赖

无直接 HTTP 调用。连接时创建 `ClientSession`，并在聊天页内调用 `/api/info` 和 `/ws`。

## 实现入口

`lib/ui/pages/home/home_page.dart`

## 视觉与动效

背景为 WorkspaceBackground 纯色，无渐变、光晕或连接示意图。页面区块以 FadeSlideIn 错峰入场（200ms easeOutCubic，延迟 0–80ms：标题 → 当前设备 → 创建与连接卡片）。页面、状态及错误提示从当前 locale 的 AppLocalizations 读取，中英文默认随系统语言；设备名保持原值。不改变 LanDiscovery 内部逻辑。

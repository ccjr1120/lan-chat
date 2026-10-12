# 网页聊天页

## 路由

`GET http://<主机IP>:<端口>/`（或 `/index.html`）。

## 页面结构

- 头部：主机名、连接状态圆点和文字、「我的名称」（原生 dialog 中编辑，保存后重连生效）、「在线 N」（窄屏时切换在线设备侧栏）。
- 断线横幅：自动重连提示。
- 消息列表（`role=log`，`aria-live=polite`）：主题文字气泡，5 分钟间隔时间分组和连续发送者合并；独立主题 surface 文件卡片（点击下载，`download=1`）；图片额外显示预览，点击在新标签页打开。
- 在线设备侧栏：宽度 ≥ 900 时左侧常驻（256px），含品牌、当前会话和在线设备；窄屏由顶部在线数量打开右侧浮层，支持遮罩、关闭按钮及 Escape。
- 输入栏：统一容器中的附件图标按钮（多选文件）、textarea（Enter 发送，Shift+Enter 换行，输入法组字时不发送，可粘贴文件；未连接或文本为空时禁用发送）、发送按钮。
- 全屏遮罩：连接中、等待主机确认、无法加入（带「重新连接」）。
- 拖拽遮罩：拖入文件时显示“松开以发送文件”。

## 交互状态

| 状态 | 表现 |
| --- | --- |
| 连接中（首次） | 遮罩 + spinner |
| `pending` | 遮罩：“等待主机确认” |
| `welcome` | 隐藏遮罩，启用输入 |
| `rejected` | 遮罩：拒绝原因 +「重新连接」，停止自动重连 |
| 断开 | 横幅 + 状态文字，按 1/2/4/8/15 秒退避重连，禁用输入 |

上传：文件进入队列后逐个用 XHR 上传（`/api/upload?name=&token=`），`upload.onprogress` 显示百分比（每 100ms 最多重绘一次）。可以取消或移除失败项。上传成功的消息与 WS 广播按 ID 去重。

## 数据来源

WS 事件：`welcome`（token、self、host）、`history`、`message`、`peers`、`pending`、`rejected`、`error`。

## 接口依赖

`/ws`、`POST /api/upload`、`GET /api/files/<id>?token=`（图片预览为 inline，下载链接为 `download=1`）。

## 实现入口

`assets/web/index.html`

## 视觉与资源

采用与 App 一致的明暗主题和蓝色强调，通过 `prefers-color-scheme` 跟随系统外观实时切换（颜色属性 250ms 过渡），原生控件声明 `color-scheme: light dark`；消息区域最大宽度约 880，响应式输入栏和文件卡片适配窄屏。视觉层次：body 顶部 `--glow` 径向光晕（终止色与背景一致），主按钮 / 发送按钮 / 自己的文字气泡使用 `--primary`→`--primary-2` 渐变（自气泡文字为 `--on-primary`，选区用 `--self-selection` 保证可见；文件卡与上传卡保持 surface 底色），主按钮与发送按钮禁用时降级为中性色，输入栏聚焦时边框高亮并带 `--glow` 外环，标题负字距微调。动效统一使用 `--ease`（easeOutCubic，与 App `AppMotion` 一致）：列表末条消息 fade + 上移入场（`renderAll` 会整体重建 DOM，故仅末条动画且排除含进度条的上送行，避免进度刷新重播）、文件卡与按钮 hover 微提升（仅 `hover: hover` 设备）、banner / toast / 遮罩 / dialog 入场过渡。`prefers-reduced-motion` 时全部动画与过渡禁用（含转圈与进度条）；交互控件使用 `:focus-visible` 焦点环与可访问名称。Lucide SVG 内联，无 CDN 和外部字体。WebSocket/HTTP、上传队列、取消上传、粘贴文件与退避重连逻辑沿用现有实现。

## 本地化

页面标题、静态提示、可访问名称、名称弹窗、连接 / 退避重连 / 加入确认状态、上传错误和平台标签支持中文 / 英文，按浏览器首个支持的语言选择，其他语言回退英文。日期使用 locale 格式。既有协议中文诊断在 UI 显示边界转换，拒绝 / 错误处理仍基于原字段，不修改 WebSocket 事件名。消息正文、文件名及设备名称保持原值。

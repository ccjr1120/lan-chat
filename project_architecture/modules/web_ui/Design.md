# web_ui 模块（前端）

## 职责

免安装的浏览器端：电脑或其他手机打开主机地址即可加入会话，收发文字和文件。

## 页面索引

| 页面 | 文档 | 入口 |
| --- | --- | --- |
| 网页聊天页 | [pages/chat/Design.md](pages/chat/Design.md) | `assets/web/index.html` |

## 内部结构

单个 `assets/web/index.html`，内联 CSS 与原生 JS（IIFE），无构建步骤或运行时第三方 JS，图标从 lucide-static 1.54.0 内联，并在 HTML 中保留上游许可。主机启动时用 `rootBundle.loadString` 读入内存，在 `/` 和 `/index.html` 返回。

## 吉祥物脚本块

主脚本之前的独立 `<script>` 内含 `/* mascot:begin */ … /* mascot:end */` 块：cat.js 的 ES5 改写（PALETTES、FRAMES、animParams、drawCat 等），与 `lib/ui/widgets/mascot_painter.dart` 逐行一致；块内不引用 DOM，供 `tool/mascot/render_icons.mjs` 截取生成应用图标。块外为 `window.LanMascot` 控制器：

- `mount(canvas, {anim, size, mini, progress})`：按 devicePixelRatio 设置画布像素，anim 为 blink / paw / sleep（循环）、tail（进度）或 face（静态 logo），<64px 默认 mini。
- 全局一个 rAF 循环，只绘制仍在 DOM 中且 `offsetParent !== null` 的循环画布，断开的画布自动移除；没有可见动画时停止，`wake()` 在遮罩显示时重新启动。
- `prefers-reduced-motion: reduce` 时不启动循环，只画静态帧（blink/sleep 取 k=0，paw 取 0.25）；tail 不进循环，挂载或 `setProgress` 时绘制一次。
- 配色按 `data-theme`，未设置时按 `prefers-color-scheme`；`applyTheme` 后与 matchMedia 变化时调用 `redraw()`，同时重新生成 favicon（32px mini 猫脸 data URI，head 中的占位 `link#favicon` 为透明像素，避免请求 /favicon.ico）。

## 设备身份

- `localStorage['lanchat.deviceId']`：首次访问时生成 UUID，用于主机识别同一浏览器（需确认模式下，重连不会再次弹窗）。
- `localStorage['lanchat.name']`：可修改的显示名，默认是“系统 浏览器 ID 前 4 位”。
- `localStorage['lanchat.theme']`：system / light / dark，缺省 system；head 内联脚本在样式解析前写入 `<html data-theme>`，避免闪烁。
- `localStorage['lanchat.language']`：system / zh-CN / en，缺省 system。

## 依赖关系

- 通过协议依赖 `server`（`/ws`、`/api/upload`、`/api/files/<id>`）。
- 视觉规范与 `lib/ui/theme.dart` 一致（`:root` 与 `prefers-color-scheme: dark` CSS 变量），默认随系统明暗实时切换，`data-theme=light|dark` 时固定对应配色；全部为纯色（无渐变、无光晕 token），浅色主色 `#4F6FF0`、分隔线 `#EEF0F3`，深色背景 `#1A1F29`、surface `#222834`；`--primary-hover` 用于主按钮 hover。双端色值须逐一保持一致。

## 视觉与动效

纯 CSS 视觉层（不改协议事件）：背景为纯色 `--bg`，无顶部光晕；主按钮、发送按钮使用 `--primary` 纯色（hover 为 `--primary-hover`），禁用时降级为中性色；自己的文字气泡为 `--self` 底 + `--self-border` 边框 + `--text` 文字，与对方 surface 气泡以底色和位置区分。阴影统一减弱（菜单、文件卡 hover）。微动效（列表末条消息入场、输入栏聚焦、hover、banner / toast / 全屏遮罩 / 弹出层入场）统一使用 `--ease`（easeOutCubic，对应 App `AppMotion`）；末条入场仅作用于末条，避免 `renderAll` 整体重建 DOM 时全部重播，上传进度行除外。hover 微提升放在 `@media (hover: hover)` 内，避免触屏粘滞。主题切换时颜色属性过渡与 App 主题动画一致。`prefers-reduced-motion: reduce` 时以通配选择器禁用全部动画与过渡，hover 不再位移；canvas 吉祥物由脚本按同一媒体查询切换为静态帧。原 CSS spinner、上传进度条与空态图标块已由吉祥物画布替代。

## 变更影响

- 协议变更需与 `server`、`client` 同步。
- 网页端没有类型检查，修改后需要人工核对事件名和字段。

## 中英文本地化

单 HTML 内联英文词典与 t()，中文作为资源键；语言默认按 navigator.languages 中首个支持的 en / zh 选择（其他语言回退英文，`languagechange` 时同步），设置菜单可固定为 zh-CN / en。启动时记录静态文本与 title / aria-label / placeholder 的中文原文，translatePage 据此双向翻译；状态、横幅、遮罩文案以函数保存，切换语言时与标题、在线设备、消息列表一起重新渲染，不刷新页面、不断开 WebSocket。动态状态、平台标签、文件操作与错误提示复用词典；日期按当前浏览器语言格式化。不翻译用户消息、文件名或设备名，不增加依赖、外部资源或协议字段。

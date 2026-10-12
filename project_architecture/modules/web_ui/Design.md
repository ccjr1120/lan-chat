# web_ui 模块（前端）

## 职责

免安装的浏览器端：电脑或其他手机打开主机地址即可加入会话，收发文字和文件。

## 页面索引

| 页面 | 文档 | 入口 |
| --- | --- | --- |
| 网页聊天页 | [pages/chat/Design.md](pages/chat/Design.md) | `assets/web/index.html` |

## 内部结构

单个 `assets/web/index.html`，内联 CSS 与原生 JS（IIFE），无构建步骤或运行时第三方 JS，5 个图标从 lucide-static 1.54.0 内联，并在 HTML 中保留上游许可。主机启动时用 `rootBundle.loadString` 读入内存，在 `/` 和 `/index.html` 返回。

## 设备身份

- `localStorage['lanchat.deviceId']`：首次访问时生成 UUID，用于主机识别同一浏览器（需确认模式下，重连不会再次弹窗）。
- `localStorage['lanchat.name']`：可修改的显示名，默认是“系统 浏览器 ID 前 4 位”。

## 依赖关系

- 通过协议依赖 `server`（`/ws`、`/api/upload`、`/api/files/<id>`）。
- 视觉规范与 `lib/ui/theme.dart` 一致（`:root` 与 `prefers-color-scheme: dark` CSS 变量），随系统明暗实时切换；除基础语义色外，包含派生 token `--primary-2`（与 App `primaryGradient` 渐变末色一致：light `#4A76FF` / dark `#6C8CFF`）与 `--glow`（primary 6–8% 透明度光晕色，对应 App `glow`），双端色值须逐一保持一致。

## 视觉与动效

纯 CSS 视觉层（不改 JS 逻辑、协议事件与 DOM id）：body 顶部 `--glow` 径向光晕，淡出到透明后与 `--bg` 合成，终止色即背景色；主按钮、发送按钮与自己的文字气泡使用 `--primary`→`--primary-2` 渐变，禁用时降级为中性色（不保留渐变），与 App `GradientFilledButton` 一致；自己的文字气泡用 `--self-selection` 定义 `::selection`，保证渐变底上的选区可见。微动效（列表末条消息入场、输入栏聚焦、hover、banner / toast / 全屏遮罩 / dialog 入场）统一使用 `--ease`（easeOutCubic，对应 App `AppMotion`）；末条入场仅作用于末条，避免 `renderAll` 整体重建 DOM 时全部重播，上传进度行除外。hover 微提升放在 `@media (hover: hover)` 内，避免触屏粘滞。主题切换时颜色属性过渡与 App 主题动画一致。`prefers-reduced-motion: reduce` 时以通配选择器禁用全部动画与过渡（含 `::backdrop`），hover 不再位移。

## 变更影响

- 协议变更需与 `server`、`client` 同步。
- 网页端没有类型检查，修改后需要人工核对事件名和字段。

## 中英文本地化

单 HTML 内联英文词典与 t()，中文作为资源键，按 navigator.languages 中首个支持的 en / zh 选择语言，其他语言回退英文。translatePage 处理静态文本和 title / aria-label / placeholder，动态状态、平台标签、文件操作与错误提示复用词典；日期按当前浏览器语言格式化。不翻译用户消息、文件名或设备名，不增加依赖、外部资源或协议字段。

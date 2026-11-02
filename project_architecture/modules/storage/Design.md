# storage 模块

## 职责

本地持久化：设备设置、主机聊天记录、传输文件。

## 内部结构

| 文件 | 说明 |
| --- | --- |
| `lib/storage/app_storage.dart` | `AppStorage.open()`：解析目录，创建三个 store（启动时调用一次） |
| `lib/storage/settings_store.dart` | `SettingsStore`（ChangeNotifier）：`deviceId`（首次生成 UUID）、`deviceName`、`accessMode`、`themeMode`、`locale` → `settings.json` |
| `lib/storage/history_store.dart` | `HistoryStore`：`history.jsonl`，每行一条 `ChatMessage`，只追加，写入串行化，坏行跳过 |
| `lib/storage/file_store.dart` | `FileStore`：`files/<fileId>/<fileName>`，先写 `.part` 再 `commit` 改名；文件 ID 和文件名经过清洗，防止路径穿越 |

## 存储位置

| 内容 | 目录 |
| --- | --- |
| `settings.json`、`history.jsonl` | `getApplicationSupportDirectory()` |
| 历史记录归档 | ApplicationSupport 下 `history_archive/<uuid>.jsonl` |
| 传输文件 | `getApplicationDocumentsDirectory()/files`（iOS 开启 `UIFileSharingEnabled`，可在“文件”App 中查看） |

## 公开接口

- `SettingsStore.setDeviceName()`、`setAccessMode()`、`setThemeMode(String)`。
- `HistoryStore.load({limit})`、`append()`、`archive()`、`clear()`。
- `FileStore.fileFor(meta)`、`dirFor(id)`、`createPartFile(id)`、`commit(part, meta)`、`importStream(meta, stream)`，以及 `sanitizeId` / `sanitizeFileName`。

## 依赖关系

- 依赖：`core`（ChatMessage、FileMeta、AccessMode）、path_provider、uuid。
- 被依赖：`server`、`client`、`app_ui`。

## 变更影响

- 修改 `ChatMessage` 的 JSON 结构时必须向后兼容已有的 `history.jsonl`（`fromJson` 对缺失字段给出默认值）。
- 修改文件目录结构会影响主机文件服务（`/api/files`）和客户端下载缓存。

## 主题选项兼容性

settings.json 新增 themeMode 字符串，仅接受 system / light / dark，缺失或非法值回退 system；旧设备身份、名称与访问方式保持原值。setThemeMode 校验选项后通知 UI 并保存。locale 字符串仅接受 system / zh / en，缺失或非法值回退 system（跟随系统 locale）；setLocale 校验后通知 UI 并保存。

每次创建主机会话时，`HistoryStore.archive()` 串行等待已有写入后将当前记录移动到归档目录，新会话使用空的 `history.jsonl`；归档不会删除传输文件。

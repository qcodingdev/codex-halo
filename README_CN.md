<p align="center">
  <img src="assets/brand/wordmark.svg" alt="Codex Halo" width="490">
</p>

<p align="center">
  <strong>Codex 在工作、等你操作，还是已经完成，一眼就知道。</strong><br>
  一个安静、纯本地的 Codex 桌面光环。
</p>

<p align="center">
  <a href="https://github.com/qcodingdev/codex-halo/releases/latest"><img alt="下载 macOS" src="https://img.shields.io/badge/下载-macOS-00bfd8?style=for-the-badge"></a>
  <a href="https://github.com/qcodingdev/codex-halo/releases/latest"><img alt="下载 Windows" src="https://img.shields.io/badge/下载-Windows-00bfd8?style=for-the-badge"></a>
  <a href="README.md"><img alt="English" src="https://img.shields.io/badge/Docs-English-263238?style=for-the-badge"></a>
</p>

<p align="center">
  <img src="assets/previews/hero.gif" alt="Codex Halo 工作、提醒、完成三种状态演示" width="960">
</p>

## 不切窗口，也不会错过 Codex

| Codex 状态 | 屏幕光效 | 含义 |
|---|---|---|
| **工作中** | 青蓝流光 | 当前回合正在执行 |
| **需要你** | 琥珀呼吸 + 系统通知 | 正在等待权限决定 |
| **已完成** | 绿色顺时针扫光 | 当前回合结束 |
| **空闲** | 完全隐藏 | 无窗口、无动画 |

Halo 的透明窗口不会获取焦点，所有鼠标操作都会穿透到下面的应用。每块
已连接屏幕都有独立且同步的四边光效；空闲时所有光效窗口直接隐藏。Rust
使用系统文件事件监听，不做 500ms 轮询。

## 下载

| 平台 | 发布包 |
|---|---|
| macOS 11+（Intel + Apple Silicon） | [下载 macOS 版](https://github.com/qcodingdev/codex-halo/releases/latest) |
| Windows 10/11 | [下载 Windows 版](https://github.com/qcodingdev/codex-halo/releases/latest) |

首版暂未签名。macOS 第一次打开时，请右键 **Codex Halo.app**，选择
**打开**。macOS Intel 已完成真机验收；Apple Silicon 和 Windows 当前
只声明 CI 构建通过，不把它们包装成真机测试。macOS 下载包中的同一个
App 同时包含 Intel `x86_64` 与 Apple Silicon `arm64` 代码。

## 一分钟安装

### macOS

1. 下载并完整解压 `Codex-Halo-macOS-Universal-v0.1.0.zip`。
2. 运行 **Install Codex Halo.command**。
3. 首次启动：右键 **Codex Halo.app** → **打开**。
4. 在 Codex 输入 `/hooks`，审核并信任 Halo 命令 Hook。
5. 点击菜单栏图标 → **Demo Mode**。

安装器只写用户目录：应用放到 `~/Applications`，先备份
`~/.codex/hooks.json`，再安全合并 5 个 Halo 生命周期 Hook。重复安装
不会重复添加。

### Windows

1. 下载并完整解压 `Codex-Halo-Windows-x64-v0.1.0.zip`。
2. 使用 PowerShell 运行 `Install-Codex-Halo.ps1`。
3. 在 Codex 输入 `/hooks`，审核并信任 Halo 命令 Hook。
4. 点击托盘图标 → **Demo Mode**。

不需要管理员权限，也不会写入系统级 `Program Files`。

## 三套主题

- **Cyber Blue**：冷色青蓝流光、琥珀提醒、亮绿完成。
- **Sakura**：更温暖柔和的粉紫光效。
- **Minimal**：只保留顶部细条，适合低干扰场景。

主题、启停、Demo Mode、开机启动和日志入口都在原生托盘菜单中，设置
会跨启动保存。

## 工作原理

```text
Codex 生命周期 Hook
       │  只写状态、时间戳、事件名
       ▼
~/.codex-halo/state.json
       │  原生文件事件监听
       ▼
Rust 状态机 ──Tauri 事件──▶ 鼠标穿透的 React/CSS 光效层
```

Halo 使用 Codex 文档化的 `UserPromptSubmit`、`PreToolUse`、
`PostToolUse`、`PermissionRequest` 和 `Stop` 生命周期事件。状态采用
原子写入；过期、未来或非法数据会被拒绝；遗留状态会按超时自动回到空闲。

没有 HTTP 服务、WebSocket、云端、数据库、更新下载器、账号或埋点。

## 隐私是结构约束

Hook 只读取 `hook_event_name`，主动丢弃其他输入。状态文件只有：

```json
{"state":"working","updatedAt":1784383200000,"event":"PreToolUse"}
```

不会保存 Prompt、工具参数、回复、源码、路径、Token 或环境变量。详见
[隐私说明](docs/PRIVACY.md)与[安全策略](SECURITY.md)。

## 性能

- 原生文件事件替代定时轮询；
- 空闲时隐藏窗口、停止 CSS 动画；
- 光效以 transform/opacity 动画为主；
- 单个可取消的超时工作线程；
- 生产 JS 197.61 KB，gzip 62.21 KB。

在 2018 款 Intel Core i9 MacBook Pro、macOS 15.7.7 上，成品 App 的主进程
空闲 CPU 连续 10 次采样均为 0.0%；同时驱动 3360×2100 Retina 主屏和
2560×1440 外接屏时，工作动画为 3.1–3.5%，RSS 约 50–51 MiB。测试方法和验收边界见
[v0.1.0 发布说明](docs/RELEASE_NOTES_v0.1.0.md)；Apple Silicon 与
Windows 目前仍是 CI 构建验证。

## 构建与贡献

```bash
pnpm install
pnpm check
cargo test --manifest-path src-tauri/Cargo.toml
pnpm tauri dev
```

详见[架构](docs/ARCHITECTURE.md)、[发布流程](docs/RELEASE.md)与
[贡献指南](CONTRIBUTING.md)。

## 干净卸载

运行发布包中的卸载器。它只从“当前配置”删除 Halo 自己的 Hook，因此
安装之后由用户新增的其他 Hook 不会丢失。应用和开机启动项会删除；配置
和日志需要显式选择清理（macOS `--purge`，Windows `-Purge`）。

v0.1 支持多显示器，保持未签名、纯本地。签名/公证、DMG/MSI 和更多
主题属于后续版本。

Codex Halo 是独立社区项目，与 OpenAI 无附属或背书关系。“Codex”仅用于
说明兼容对象。

## License

[MIT](LICENSE)

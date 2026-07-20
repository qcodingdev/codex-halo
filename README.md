<p align="center">
  <img src="assets/brand/wordmark.svg" alt="Codex Halo" width="490">
</p>

<p align="center">
  <strong>Give Codex a breathing light — know it is working from any window.</strong><br>
  A local-only screen-edge signal for working, waiting, and done.
</p>

<p align="center">
  <a href="https://github.com/qcodingdev/codex-halo/releases/latest"><img alt="Download for macOS" src="https://img.shields.io/badge/Download_for-macOS-00bfd8?style=for-the-badge"></a>
  <a href="https://github.com/qcodingdev/codex-halo/releases/latest"><img alt="Download for Windows" src="https://img.shields.io/badge/Download_for-Windows-00bfd8?style=for-the-badge"></a>
  <a href="README_CN.md"><img alt="中文" src="https://img.shields.io/badge/文档-中文-ff5d96?style=for-the-badge"></a>
</p>

<p align="center">
  <img src="assets/previews/hero.gif" alt="Codex Halo cycles through working, attention, and completed states" width="960">
</p>

## One glance. Zero interruption.

| Codex state | Halo | Meaning |
|---|---|---|
| **Working** | Cyan-blue flow | Your turn is actively running |
| **Needs you** | Amber pulse + notification | A permission decision is waiting |
| **Completed** | Green clockwise sweep | The turn finished |
| **Idle** | Invisible | No overlay and no animation |

The overlay never accepts focus and every mouse click passes through to the app
underneath it. Every connected display gets its own synchronized edge overlay.
When idle, all overlay windows are hidden. Native filesystem events are backed
by a bounded check of only the eight most recent session files.

## Download

| Platform | Package |
|---|---|
| macOS 11+ (Intel + Apple Silicon) | [Download for macOS](https://github.com/qcodingdev/codex-halo/releases/latest) |
| Windows 10/11 | [Download for Windows](https://github.com/qcodingdev/codex-halo/releases/latest) |

The first release is unsigned. On macOS, right-click **Codex Halo.app** and
choose **Open** the first time. Real-device smoke testing is complete on macOS
Intel; Apple Silicon and Windows packages are built in CI and are explicitly
not presented as real-hardware validation. The macOS download is one app that
contains both Intel `x86_64` and Apple Silicon `arm64` code.

## Install in under a minute

### macOS

1. Download and extract `Codex-Halo-macOS-Universal-v0.1.8.zip`.
2. Run **Install Codex Halo.command**.
3. Right-click **Codex Halo.app** → **Open** on first launch.
4. Use Codex normally. Halo begins breathing automatically on the next task.
5. Choose **Demo Mode** from the menu-bar icon.

The per-user installer copies the app to `~/Applications`. It does not add a
Codex Hook or ask for a trust confirmation. If an earlier Halo release added
its own marked hooks, the installer removes only those obsolete entries.

### Windows

1. Download and extract `Codex-Halo-Windows-x64-v0.1.8.zip`.
2. Run `Install-Codex-Halo.ps1` with PowerShell.
3. Use Codex normally; no file, Hook, or trust configuration is required.
4. Choose **Demo Mode** from the tray icon.

No administrator permission or system-level `Program Files` write is required.

## Three personalities

- **Cyber Blue** — cool cyan flow, amber attention, vivid green completion.
- **Sakura** — pink-violet motion with a warmer, softer glow.
- **Minimal** — a restrained top bar for distraction-sensitive setups.

Switch themes, toggle Halo, run Demo Mode, enable Start at Login, or open logs
from the native tray menu. Preferences persist across restarts.

## How it works

```text
Codex Desktop session lifecycle record
       │  task_started / task_complete only
       ▼
native watcher + bounded recent-session fallback
       ▼
Rust state machine ──Tauri event──▶ click-through React/CSS overlay
```

Halo observes only Codex Desktop's local `task_started` and `task_complete`
records. It never parses, stores, or logs prompt/tool payloads. State timeouts
return abandoned states to idle.

There is no HTTP server, WebSocket, cloud service, database, updater, account,
or analytics endpoint.

## Privacy by construction

Halo reads local lifecycle record types only; it never stores prompts, tool
inputs, responses, source code, paths, tokens, or environment variables. Logs
contain operational state transitions and errors only. See
[Privacy](docs/PRIVACY.md) and [Security](SECURITY.md).

## Performance

The performance design is intentionally boring:

- native filesystem notifications plus a 500 ms check limited to eight recent
  session files;
- hidden overlay and no CSS animation in idle;
- transform/opacity-first edge animations;
- one cancellable timeout worker instead of one sleeping thread per event;
- a 197.61 KB production JavaScript bundle (62.21 KB gzip).

The overlay remains hidden with no CSS animation while idle. The fallback reads
file metadata only for a bounded recent set rather than rescanning session
history. Apple Silicon and Windows remain CI-only validation.

## Build

Requirements: Node.js 22.12+, pnpm 9+, stable Rust, and the Tauri 2 platform
prerequisites.

```bash
pnpm install
pnpm check
cargo test --manifest-path src-tauri/Cargo.toml
pnpm tauri dev
```

Release packaging:

```bash
# macOS: real Universal .app, installers, hooks, README, ZIP
bash scripts/release/package-macos.sh 0.1.4

# Windows PowerShell
./scripts/release/package-windows.ps1 0.1.4
```

CI builds and verifies macOS Intel, macOS ARM64, macOS Universal, and Windows
x64 outputs. See [Release guide](docs/RELEASE.md) and
[Architecture](docs/ARCHITECTURE.md).

## Uninstall cleanly

Run the uninstaller included in the ZIP. It removes only Halo's current hook
handlers from the current config, so hooks added by the user after installation
remain intact. It also removes the app and login item; settings/log deletion is
opt-in (`--purge` on macOS or `-Purge` on Windows).

## Contributing

Issues and focused pull requests are welcome. Please read
[CONTRIBUTING.md](CONTRIBUTING.md). Visual changes should include a recording;
state, timeout, hook, and installer changes should include tests.

## Scope

Version 0.1 is multi-monitor, unsigned, and local-only. Signing/notarization,
DMG/MSI packaging, and additional themes belong to future releases.

Codex Halo is an independent community project and is not affiliated with or
endorsed by OpenAI. “Codex” is used only to describe compatibility.

## License

[MIT](LICENSE)

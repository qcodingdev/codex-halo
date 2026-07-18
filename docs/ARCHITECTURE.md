# Codex Halo architecture

## Data flow

```text
Codex documented hook event
        │ stdin JSON (hook_event_name is the only consumed field)
        ▼
Shell / PowerShell adapter
        │ atomic rename
        ▼
~/.codex-halo/state.json
        │ macOS FSEvents / Windows ReadDirectoryChangesW through notify
        ▼
Rust validation + state machine + timeout worker
        │ halo-state / halo-theme Tauri events
        ▼
React component + composited CSS edge animation
```

There is no process-to-process network channel. The app binds no port and has
no WebSocket, HTTP server, database, cloud component, updater, or telemetry.

## State machine

| Hook event | State | Timeout |
|---|---|---:|
| `UserPromptSubmit`, `PreToolUse`, `PostToolUse` | `working` | 30 minutes |
| `PermissionRequest` | `attention` | 60 minutes |
| `Stop` | `completed` | 2 seconds |
| timeout / disabled / quit | `idle` | hidden |

`StateFile::validate` rejects unknown states, unknown JSON fields, stale
timestamps, and timestamps too far in the future. The watcher ignores duplicate
or older revisions. A single timeout worker receives replacement deadlines, so
bursts of tool events do not create sleeping-thread buildup.

## Window model

The overlay is created lazily at the primary monitor's logical size. Before
showing, it is refit using the monitor's physical position and dimensions. It is:

- transparent and undecorated;
- always on top and visible on all workspaces;
- non-focusable and never explicitly focused;
- excluded from the taskbar/Dock;
- configured to ignore cursor events.

Idle hides the window. Non-idle rendering uses four thin edge elements (or one
top bar for Minimal). Animations primarily change transforms and opacity.

## Persistence

- State bridge: `~/.codex-halo/state.json`
- Hook adapter/manager: `~/.codex-halo/`
- macOS settings/logs: `~/Library/Application Support/Codex Halo/`
- Windows settings/logs: `%LOCALAPPDATA%\Codex Halo\`

Settings use temporary-file, flush, and rename semantics. Corrupt settings
recover to defaults. Logs rotate at 1 MiB and retain one previous file.

## Installer safety

Halo lives in the separate documented `~/.codex/hooks.json` source. Install:

1. parses and structurally validates the current document;
2. creates a timestamped backup;
3. removes only handlers whose command contains Halo's unique adapter path;
4. adds one handler for each of five events;
5. writes atomically.

Uninstall applies step 3 to the current file instead of restoring an old backup,
so hooks added after installation are preserved. Invalid JSON stops modification.

## Source layout

```text
src/                 React overlay, effects, themes, Tauri event hook
src-tauri/src/       window, tray, watcher, settings, logs, state machine
hooks/               minimal lifecycle adapters
scripts/macos/       install, verify, uninstall, state test, hook manager
scripts/windows/     equivalent PowerShell tools
scripts/release/     self-contained macOS/Windows ZIP builders
demo/                README hero source
tests/fixtures/      hook merge preservation fixture
```

## Quality gates

`pnpm check` runs ESLint, TypeScript, and the Vite production build. Rust gates
are `cargo fmt --check`, Clippy with warnings denied, and unit tests. CI repeats
these gates and builds macOS Universal plus Windows x64 packages.

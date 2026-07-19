# Privacy

Codex Halo is local-only by architecture.

## What lifecycle data is consumed

Halo watches Codex Desktop's append-only local session files and recognizes only
the `task_started` and `task_complete` record types. It does not parse, retain,
transmit, or log prompt text, tool names/input, source code, responses,
commands, file paths, session content, API keys, tokens, or environment
variables.

## What Halo reads

The running app watches the local Codex session directory and its optional
manual-state bridge:

```text
~/.codex/sessions/  and  ~/.codex-halo/state.json
```

The session watcher consumes complete JSONL records only and checks their
top-level lifecycle type without parsing payload objects. The optional state
bridge remains for Demo Mode and diagnostics.

## What Halo writes

The app writes settings and bounded operational logs to its platform application
data directory. Settings contain only `enabled`, `theme`, and `startAtLogin`.
Logs include version/platform, state transitions, watcher errors, and lifecycle
messages. They do not include session payloads or user content. A 1 MiB startup
rotation keeps at most the current and previous log.

The installer stores its safe legacy-cleanup manager under `~/.codex-halo`. It
does not add a current hook; it removes only marked Halo entries left by older
releases.

## Network

The application has no networking dependency, port listener, server, remote
API, account, analytics, crash reporter, or update downloader. Its CSP permits
only packaged application resources and Tauri IPC.

## Audit pointers

- `src-tauri/src/watcher.rs` — local lifecycle and state reads
- `src-tauri/src/logging.rs` — bounded log output
- `src-tauri/Cargo.toml` and `package.json` — complete runtime dependencies
- `scripts/*/Manage-*Hooks*` — scoped legacy cleanup behavior

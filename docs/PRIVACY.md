# Privacy

Codex Halo is local-only by architecture.

## What the hook consumes

Codex sends hook metadata on stdin. Halo parses only the documented
`hook_event_name` field and discards the rest. It never persists prompt text,
tool names or input, source code, responses, commands, file paths, session
content, API keys, tokens, or environment variables.

## What Halo reads

The running app watches one file:

```text
~/.codex-halo/state.json
```

Its schema is intentionally small:

```json
{"state":"working","updatedAt":1784383200000,"event":"PreToolUse"}
```

Only `state` and `updatedAt` are required. `event` and `sessionId` are allowed
for compatibility, although the bundled adapter never writes a session ID.
Unknown fields cause the update to be rejected.

## What Halo writes

The app writes settings and bounded operational logs to its platform application
data directory. Settings contain only `enabled`, `theme`, and `startAtLogin`.
Logs include version/platform, state transitions, watcher errors, and lifecycle
messages. They do not include hook stdin or user content. A 1 MiB startup
rotation keeps at most the current and previous log.

The installer also writes Halo's adapter and manager under `~/.codex-halo` and
adds a marked Halo-only section to `~/.codex/config.toml` after creating a
timestamped backup. It removes only Halo's legacy entries from `hooks.json`.

## Network

The application has no networking dependency, port listener, server, remote
API, account, analytics, crash reporter, or update downloader. Its CSP permits
only packaged application resources and Tauri IPC.

## Audit pointers

- `hooks/` — fields consumed and state data written
- `src-tauri/src/watcher.rs` — local event-driven reads
- `src-tauri/src/logging.rs` — bounded log output
- `src-tauri/Cargo.toml` and `package.json` — complete runtime dependencies
- `scripts/*/Manage-*Hooks*` — scoped merge and uninstall behavior

# Changelog

All notable changes are documented here.

## [0.1.8] - 2026-07-20

### Fixed

- Detect task start and completion reliably when Codex appends to an existing
  session file.
- Keep one correctly sized edge halo on every connected display.
- Remove the overlapping center activation light.

## [0.1.7] - 2026-07-19

### Improved

- Shorten and reduce the first central Logo flash so it identifies activation
  without obscuring the user's active window.

## [0.1.6] - 2026-07-19

### Fixed

- Recover lifecycle events when Codex atomically replaces a session JSONL file.
- Reduce the full-edge working rail to a text-safe 8px signal with inward glow.

## [0.1.5] - 2026-07-19

### Changed

- Remove obsolete Halo executable hooks during installation. Current Codex
  Desktop activity detection is built in and requires no trust prompt.

## [0.1.4] - 2026-07-19

### Fixed

- Detect Codex Desktop lifecycle records locally, so the working signal starts
  without relying on an executable hook trust confirmation.

## [0.1.3] - 2026-07-19

### Fixed

- Render the macOS menu-bar mark explicitly in white for dark menu bars.
- Make the default full-screen working signal visibly thicker and project its
  glow inward, where macOS does not clip it at a display boundary.

## [0.1.2] - 2026-07-19

### Fixed

- Remove the obsolete `/hooks` instruction from both bundled installers; the
  only possible first-use action is Codex's own native confirmation.

## [0.1.1] - 2026-07-19

### Fixed

- Install Halo lifecycle hooks into current Codex Desktop `config.toml` rather
  than the obsolete `hooks.json` location.
- Safely remove only old Halo JSON handlers while preserving all other hooks.

### Improved

- Use a branded, breathing tray icon instead of a generic ring.
- Make the first working transition flash the Halo mark at screen center before
  it resolves into a stronger edge-breathing signal.
- Rebuild the README visual around the actual breathing light instead of copy.
- Clarify the Chinese product promise: give Codex a breathing/running light that
  remains visible from any window.

## [0.1.0] - 2026-07-18

### Added

- Working, attention, completed, and idle screen-edge states
- Cyber Blue, Sakura, and Minimal themes
- Demo Mode, native tray controls, notifications, logs, and Start at Login
- Documented Codex lifecycle-hook adapters for macOS and Windows
- Idempotent hook merge, timestamped backup, exact verification, and scoped uninstall
- Universal macOS and Windows x64 release workflows

### Security and performance

- Local state-file bridge with no server, telemetry, prompt capture, or code access
- Strict state schema, timestamp validation, atomic writes, and stale update rejection
- Native filesystem events, hidden idle overlay, composited animations, bounded logs,
  and a single replacement timeout worker

[0.1.0]: https://github.com/qcodingdev/codex-halo/releases/tag/v0.1.0
[0.1.1]: https://github.com/qcodingdev/codex-halo/releases/tag/v0.1.1
[0.1.2]: https://github.com/qcodingdev/codex-halo/releases/tag/v0.1.2
[0.1.3]: https://github.com/qcodingdev/codex-halo/releases/tag/v0.1.3
[0.1.4]: https://github.com/qcodingdev/codex-halo/releases/tag/v0.1.4
[0.1.5]: https://github.com/qcodingdev/codex-halo/releases/tag/v0.1.5
[0.1.6]: https://github.com/qcodingdev/codex-halo/releases/tag/v0.1.6
[0.1.7]: https://github.com/qcodingdev/codex-halo/releases/tag/v0.1.7
[0.1.8]: https://github.com/qcodingdev/codex-halo/releases/tag/v0.1.8

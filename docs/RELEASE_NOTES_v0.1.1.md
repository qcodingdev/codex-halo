# Codex Halo 0.1.1

## Fixed: current Codex Desktop hook activation

Codex Halo now installs its five lifecycle hooks into Codex Desktop's active
`~/.codex/config.toml` configuration instead of relying on the older
`hooks.json` location. This restores automatic working, attention, and
completion effects in current Codex Desktop builds.

## Safe migration

- Existing `config.toml` content is preserved byte-for-byte outside Halo's
  clearly marked section.
- Existing hooks, including third-party tools such as Token Tracker, remain in
  place.
- An old Halo installation's handlers are removed from `hooks.json` without
  touching non-Halo handlers.
- Reinstall, verify, and uninstall are idempotent and write atomically.
- Codex may show its own one-time trust confirmation on first use. Halo never
  asks users to edit Hook files or fabricate that security decision.

## More visible by design

- The menu-bar/tray mark now matches the Codex Halo terminal-ring logo and
  breathes continuously.
- A first working transition flashes the mark at screen center before resolving
  into a thicker, brighter breathing edge signal.
- The README preview puts the breathing light first, with only a compact status
  label.

## Validation

- The generated configuration passed local `codex --strict-config` loading.
- macOS fixture tests cover install, repeat install, verification, uninstall,
  and unrelated-hook preservation.
- Windows receives the same managed TOML section, atomic replacement, legacy
  cleanup, and verification path in CI.

Download the ZIP for your platform, extract it, and run the installer. If
Codex displays its native one-time confirmation on the first turn, approve the
installed local helper there.

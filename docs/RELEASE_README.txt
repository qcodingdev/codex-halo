Codex Halo v0.1.3
=================

Your screen glows with Codex.

macOS
-----
1. Extract the entire ZIP.
2. Run "Install Codex Halo.command".
3. First launch: right-click "Codex Halo.app", then choose Open.
4. Approve Codex's one-time built-in trust confirmation if it appears.
5. From the menu-bar icon, choose Demo Mode.

Windows
-------
1. Extract the entire ZIP.
2. Run "Install-Codex-Halo.ps1" with PowerShell.
3. Approve Codex's one-time built-in trust confirmation if it appears.
4. From the tray icon, choose Demo Mode.

Privacy and safety
------------------
Codex Halo is local-only. It has no network service and no telemetry. The hook
adapter stores only a state, millisecond timestamp, and lifecycle event name in
~/.codex-halo/state.json. It never stores prompts, source code, tool input, or
responses. Installation backs up and safely extends ~/.codex/config.toml;
it removes only obsolete Halo entries from ~/.codex/hooks.json if present.

This is an independent community project and is not affiliated with or endorsed
by OpenAI.

# Installation

## macOS 11 or newer

1. Download and fully extract the Universal ZIP.
2. Run `Install Codex Halo.command`.
3. For the unsigned first release, right-click `Codex Halo.app`, choose **Open**,
   then confirm **Open**.
4. If Codex shows its built-in one-time trust confirmation on the first turn,
   approve the installed local Halo helper. No file or Hook configuration is
   required.
5. Open the menu-bar icon and run **Demo Mode**.

The installer uses `~/Applications` and needs no administrator permission. It
creates `~/.codex-halo`, backs up and safely extends the active
`~/.codex/config.toml` hook configuration with:

- `UserPromptSubmit`
- `PreToolUse`
- `PostToolUse`
- `PermissionRequest`
- `Stop`

Repeat installation is idempotent. Run `Verify Codex Halo.command` to check both
Universal architectures, the state directory, exactly five non-duplicate hooks,
an atomic state write, process status, and Start at Login consistency.

If an older Halo version created entries in `~/.codex/hooks.json`, the installer
removes only those legacy Halo entries and preserves every other JSON hook.

Uninstall with `Uninstall Codex Halo.command`. Add `--purge` in Terminal only if
you also want to delete preferences and logs.

## Windows 10/11 x64

1. Download and fully extract the Windows ZIP.
2. Run `Install-Codex-Halo.ps1` in PowerShell.
3. Approve Codex's one-time built-in trust confirmation if it appears. No file
   or Hook configuration is required.
4. Open the tray icon and run **Demo Mode**.

The installer writes `%LOCALAPPDATA%\Codex Halo`, safely extends
`%USERPROFILE%\.codex\config.toml`, creates a Start Menu shortcut, and requires
no administrator permission. Run `Verify-Codex-Halo.ps1` for the
installation checks. Uninstall with `Uninstall-Codex-Halo.ps1`; pass `-Purge`
only when settings/log removal is desired.

## Why a one-time confirmation can appear

Halo automates file installation and the safe configuration merge. Codex keeps
trust for executable hooks as its own security decision, so it can show one
native confirmation on first use. Halo never asks users to edit a configuration
file or manually register Hook events.

## Manual state test

```bash
# macOS
./scripts/macos/test-state.sh working
./scripts/macos/test-state.sh attention
./scripts/macos/test-state.sh completed
./scripts/macos/test-state.sh idle
```

```powershell
# Windows
.\scripts\windows\Test-State.ps1 -State working
```

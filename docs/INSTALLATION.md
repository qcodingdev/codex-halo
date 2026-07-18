# Installation

## macOS 11 or newer

1. Download and fully extract the Universal ZIP.
2. Run `Install Codex Halo.command`.
3. For the unsigned first release, right-click `Codex Halo.app`, choose **Open**,
   then confirm **Open**.
4. In Codex, run `/hooks`, inspect the five Halo command hooks, and trust them.
5. Open the menu-bar icon and run **Demo Mode**.

The installer uses `~/Applications` and needs no administrator permission. It
creates `~/.codex-halo`, backs up `~/.codex/hooks.json`, and safely merges:

- `UserPromptSubmit`
- `PreToolUse`
- `PostToolUse`
- `PermissionRequest`
- `Stop`

Repeat installation is idempotent. Run `Verify Codex Halo.command` to check both
Universal architectures, the state directory, exactly five non-duplicate hooks,
an atomic state write, process status, and Start at Login consistency.

Uninstall with `Uninstall Codex Halo.command`. Add `--purge` in Terminal only if
you also want to delete preferences and logs.

## Windows 10/11 x64

1. Download and fully extract the Windows ZIP.
2. Run `Install-Codex-Halo.ps1` in PowerShell.
3. In Codex, run `/hooks`, inspect the five Halo command hooks, and trust them.
4. Open the tray icon and run **Demo Mode**.

The installer writes `%LOCALAPPDATA%\Codex Halo`, creates a Start Menu shortcut,
and requires no administrator permission. Run `Verify-Codex-Halo.ps1` for the
installation checks. Uninstall with `Uninstall-Codex-Halo.ps1`; pass `-Purge`
only when settings/log removal is desired.

## Why `/hooks` is still required

Halo automates file installation and safe configuration merge, but trust is a
Codex user decision. Reviewing the command hooks in `/hooks` makes that boundary
visible instead of bypassing it.

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

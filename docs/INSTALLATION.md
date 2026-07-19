# Installation

## macOS 11 or newer

1. Download and fully extract the Universal ZIP.
2. Run `Install Codex Halo.command`.
3. For the unsigned first release, right-click `Codex Halo.app`, choose **Open**,
   then confirm **Open**.
4. Use Codex normally. Halo detects local task lifecycle events automatically.
5. Open the menu-bar icon and run **Demo Mode**.

The installer uses `~/Applications` and needs no administrator permission. It
creates `~/.codex-halo`, and does not add a Codex Hook or require a trust
approval. Repeat installation is idempotent. Run `Verify Codex Halo.command`
to check both Universal architectures, the state directory, an atomic state
write, process status, and Start at Login consistency. If an older Halo version
created entries in `~/.codex/config.toml` or `hooks.json`, the installer removes
only those marked legacy Halo entries.

Uninstall with `Uninstall Codex Halo.command`. Add `--purge` in Terminal only if
you also want to delete preferences and logs.

## Windows 10/11 x64

1. Download and fully extract the Windows ZIP.
2. Run `Install-Codex-Halo.ps1` in PowerShell.
3. Use Codex normally; no file, Hook, or trust configuration is required.
4. Open the tray icon and run **Demo Mode**.

The installer writes `%LOCALAPPDATA%\Codex Halo`, creates a Start Menu shortcut,
and requires no administrator permission. Run `Verify-Codex-Halo.ps1` for the
installation checks. Uninstall with `Uninstall-Codex-Halo.ps1`; pass `-Purge`
only when settings/log removal is desired.

## No Codex configuration step

Halo watches only the local `task_started` and `task_complete` lifecycle
records emitted by Codex Desktop. It does not install executable hooks, parse
prompts, or require a trust confirmation.

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

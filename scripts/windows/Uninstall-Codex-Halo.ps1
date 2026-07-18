param([switch]$Purge)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = Join-Path $env:LOCALAPPDATA "Codex Halo"
$HaloDir = Join-Path $env:USERPROFILE ".codex-halo"
$HooksFile = Join-Path (Join-Path $env:USERPROFILE ".codex") "hooks.json"
$Manager = Join-Path $HaloDir "Manage-Codex-HaloHooks.ps1"
if (-not (Test-Path $Manager)) {
    $Manager = Join-Path $ScriptDir "support\Manage-Codex-HaloHooks.ps1"
}

Write-Host "Codex Halo - Windows uninstaller"
if (Test-Path $HooksFile) {
    if (-not (Test-Path $Manager)) {
        throw "Hook manager is missing. Stopping before removing the app."
    }
    $Backup = "$HooksFile.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $HooksFile $Backup
    $Count = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Manager `
        -Operation Uninstall -HooksPath $HooksFile
    if ([int]$Count -ne 0) { throw "Halo hook removal was incomplete." }
    Write-Host "[PASS] Removed only Codex Halo hooks" -ForegroundColor Green
}

Get-Process CodexHalo -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
    -Name "Codex Halo" -ErrorAction SilentlyContinue
$Shortcut = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Codex Halo.lnk"
Remove-Item $Shortcut -Force -ErrorAction SilentlyContinue
Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue

if ($Purge) {
    Remove-Item $HaloDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[PASS] Removed settings, state, and logs" -ForegroundColor Green
} else {
    Remove-Item (Join-Path $HaloDir "codex-halo-hook.ps1") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $HaloDir "Manage-Codex-HaloHooks.ps1") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $HaloDir "state.json") -Force -ErrorAction SilentlyContinue
    Write-Host "[WARN] Preferences and logs were kept. Use -Purge to delete them." -ForegroundColor Yellow
}
Write-Host "Uninstall complete. Codex and non-Halo hooks were left untouched."

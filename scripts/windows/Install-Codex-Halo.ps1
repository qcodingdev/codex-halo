param([switch]$Silent)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = Join-Path $env:LOCALAPPDATA "Codex Halo"
$HaloDir = Join-Path $env:USERPROFILE ".codex-halo"
$CodexDir = Join-Path $env:USERPROFILE ".codex"
$HooksFile = Join-Path $CodexDir "hooks.json"
$AppSource = Join-Path $ScriptDir "CodexHalo.exe"
$AppDest = Join-Path $InstallDir "CodexHalo.exe"
$HookSource = Join-Path $ScriptDir "hooks\windows\codex-halo-hook.ps1"
$HookDest = Join-Path $HaloDir "codex-halo-hook.ps1"
$ManagerSource = Join-Path $ScriptDir "support\Manage-Codex-HaloHooks.ps1"
$ManagerDest = Join-Path $HaloDir "Manage-Codex-HaloHooks.ps1"

Write-Host "Codex Halo - Windows installer"
if (-not $IsWindows -and $PSVersionTable.PSVersion.Major -ge 6) {
    throw "This installer only supports Windows."
}
if ([Environment]::OSVersion.Version.Major -lt 10) {
    throw "Codex Halo requires Windows 10 or Windows 11."
}
foreach ($Required in @($AppSource, $HookSource, $ManagerSource)) {
    if (-not (Test-Path $Required)) { throw "Release file is missing: $Required" }
}

New-Item -ItemType Directory -Force -Path $InstallDir, $HaloDir, $CodexDir | Out-Null
Copy-Item $HookSource $HookDest -Force
Copy-Item $ManagerSource $ManagerDest -Force

if (Test-Path $HooksFile) {
    $Backup = "$HooksFile.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $HooksFile $Backup
    Write-Host "[PASS] Backed up hooks.json to $(Split-Path -Leaf $Backup)" -ForegroundColor Green
}

$HookCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$HookDest`""
$Count = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ManagerDest `
    -Operation Install -HooksPath $HooksFile -Command $HookCommand
if ([int]$Count -ne 5) { throw "Expected 5 Halo hooks, found $Count." }
Write-Host "[PASS] Installed 5 idempotent Codex lifecycle hooks" -ForegroundColor Green

Get-Process CodexHalo -ErrorAction SilentlyContinue | Stop-Process -Force
Copy-Item $AppSource $AppDest -Force
Write-Host "[PASS] Installed $AppDest" -ForegroundColor Green

$ShortcutPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Codex Halo.lnk"
try {
    $Shell = New-Object -ComObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $AppDest
    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.Save()
    Write-Host "[PASS] Created Start Menu shortcut" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Start Menu shortcut could not be created." -ForegroundColor Yellow
}

Start-Process $AppDest
Write-Host ""
Write-Host "Installation complete."
Write-Host "In Codex, open /hooks and review/trust the Halo command hooks."
Write-Host "Use the tray icon > Demo Mode for the 8-second preview."

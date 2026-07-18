$HaloDir = Join-Path $env:USERPROFILE ".codex-halo"
$InstallDir = Join-Path $env:LOCALAPPDATA "Codex Halo"
$AppExe = Join-Path $InstallDir "CodexHalo.exe"
$ConfigFile = Join-Path (Join-Path $env:USERPROFILE ".codex") "config.toml"
$LegacyHooksFile = Join-Path (Join-Path $env:USERPROFILE ".codex") "hooks.json"
$Manager = Join-Path $HaloDir "Manage-Codex-HaloHooks.ps1"
$Pass = 0
$Fail = 0

function Pass($Message) { Write-Host "[PASS] $Message" -ForegroundColor Green; $script:Pass++ }
function Fail($Message, $Hint) { Write-Host "[FAIL] $Message - $Hint" -ForegroundColor Red; $script:Fail++ }
function Warn($Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }

if (Test-Path $AppExe) { Pass "Application installed" } else { Fail "Application missing" "Run the installer" }
try {
    New-Item -ItemType Directory -Force $HaloDir | Out-Null
    $Probe = Join-Path $HaloDir (".write-test." + [Guid]::NewGuid().ToString("N"))
    [IO.File]::WriteAllText($Probe, "ok")
    Remove-Item $Probe
    Pass "State directory is writable"
} catch { Fail "State directory is not writable" "Check $HaloDir permissions" }

if (Test-Path (Join-Path $HaloDir "codex-halo-hook.ps1")) {
    Pass "Hook adapter installed"
} else { Fail "Hook adapter missing" "Re-run the installer" }

if ((Test-Path $ConfigFile) -and (Test-Path $Manager)) {
    try {
        $Count = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Manager `
            -Operation Verify -HooksPath $ConfigFile
        if ([int]$Count -eq 5) { Pass "Exactly 5 Halo hooks installed in config.toml" }
        else { Fail "Halo hook count is $Count" "Re-run the installer" }
    } catch { Fail "Codex hook configuration is invalid" $_.Exception.Message }
} else { Fail "Codex hook configuration missing" "Re-run the installer" }

if ((Test-Path $LegacyHooksFile) -and (Test-Path $Manager)) {
    try {
        $LegacyCount = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Manager `
            -Operation Verify -HooksPath $LegacyHooksFile
        if ([int]$LegacyCount -eq 0) { Pass "No legacy Halo hooks remain in hooks.json" }
        else { Fail "Legacy Halo hook count is $LegacyCount" "Re-run the installer" }
    } catch { Fail "Legacy Codex hook configuration is invalid" $_.Exception.Message }
}

$TestScript = Join-Path $PSScriptRoot "Test-State.ps1"
try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $TestScript -State idle | Out-Null
    Pass "Atomic state test succeeded"
} catch { Fail "State test failed" "Check the extracted release" }

if (Get-Process CodexHalo -ErrorAction SilentlyContinue) {
    Pass "Codex Halo is running; Demo Mode is available"
} else { Warn "Codex Halo is not running" }

$Settings = Join-Path $InstallDir "settings.json"
if (Test-Path $Settings) {
    $Desired = (Get-Content -Raw $Settings | ConvertFrom-Json).startAtLogin
    $Actual = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
        -Name "Codex Halo" -ErrorAction SilentlyContinue) -ne $null
    if ([bool]$Desired -eq $Actual) { Pass "Start at Login matches settings" }
    else { Fail "Start at Login is out of sync" "Toggle it from the tray" }
} else { Warn "Start at Login has not been configured yet" }

Write-Host ""
Write-Host "Results: $Pass passed, $Fail failed"
if ($Fail -gt 0) { exit 1 }

param([string]$Version = "0.1.0")

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Output = Join-Path $Root "dist\release"
$Stage = Join-Path $Output "windows"
$Zip = Join-Path $Output "Codex-Halo-Windows-x64-v$Version.zip"

Push-Location $Root
try {
    Write-Host "[1/3] Building Windows x64 binary..."
    pnpm tauri build --no-bundle --target x86_64-pc-windows-msvc
    if ($LASTEXITCODE -ne 0) { throw "Tauri build failed." }

    Remove-Item $Stage -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force `
        (Join-Path $Stage "hooks\windows"), (Join-Path $Stage "support") | Out-Null
    Copy-Item (Join-Path $Root "src-tauri\target\x86_64-pc-windows-msvc\release\codex-halo-lite.exe") `
        (Join-Path $Stage "CodexHalo.exe")
    Copy-Item (Join-Path $Root "scripts\windows\Install-Codex-Halo.ps1") $Stage
    Copy-Item (Join-Path $Root "scripts\windows\Uninstall-Codex-Halo.ps1") $Stage
    Copy-Item (Join-Path $Root "scripts\windows\Verify-Codex-Halo.ps1") $Stage
    Copy-Item (Join-Path $Root "scripts\windows\Test-State.ps1") $Stage
    Copy-Item (Join-Path $Root "hooks\windows\codex-halo-hook.ps1") (Join-Path $Stage "hooks\windows")
    Copy-Item (Join-Path $Root "scripts\windows\Manage-Codex-HaloHooks.ps1") (Join-Path $Stage "support")
    Copy-Item (Join-Path $Root "docs\RELEASE_README.txt") (Join-Path $Stage "README.txt")
    Write-Host "[2/3] Self-contained installer staged"

    Remove-Item $Zip -Force -ErrorAction SilentlyContinue
    Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $Zip -CompressionLevel Optimal
    Write-Host "[3/3] Created $Zip"
} finally {
    Pop-Location
}

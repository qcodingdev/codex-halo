param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("idle", "working", "attention", "completed")]
    [string]$State
)

$ErrorActionPreference = "Stop"
$HaloDir = Join-Path $env:USERPROFILE ".codex-halo"
$StateFile = Join-Path $HaloDir "state.json"
New-Item -ItemType Directory -Force -Path $HaloDir | Out-Null
$Timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
if (Test-Path $StateFile) {
    try {
        $Previous = [long](Get-Content -Raw $StateFile | ConvertFrom-Json).updatedAt
        if ($Previous -ge $Timestamp) { $Timestamp = $Previous + 1 }
    } catch {}
}
$Data = @{ state = $State; updatedAt = $Timestamp; event = "ManualTest" } |
    ConvertTo-Json -Compress
$Temp = Join-Path $HaloDir ("state.json.{0}.tmp" -f [Guid]::NewGuid().ToString("N"))
try {
    [IO.File]::WriteAllText($Temp, $Data, (New-Object Text.UTF8Encoding($false)))
    Move-Item -Force $Temp $StateFile
} finally {
    Remove-Item -Force -ErrorAction SilentlyContinue $Temp
}
Write-Host "[OK] $State -> $StateFile"

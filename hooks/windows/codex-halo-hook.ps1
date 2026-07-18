# Codex Halo lifecycle adapter for Windows.
# Reads only documented metadata and never persists prompts or tool inputs.

$ErrorActionPreference = "SilentlyContinue"
$InputJson = $input | Out-String

try {
    $HookEvent = ($InputJson | ConvertFrom-Json).hook_event_name
} catch {
    exit 0
}

$HaloState = switch ($HookEvent) {
    "UserPromptSubmit" { "working"; break }
    "PreToolUse"       { "working"; break }
    "PostToolUse"      { "working"; break }
    "PermissionRequest" { "attention"; break }
    "Stop"             { "completed"; break }
    default            { $null }
}

if (-not $HaloState) {
    exit 0
}

$HaloDir = Join-Path $env:USERPROFILE ".codex-halo"
$StateFile = Join-Path $HaloDir "state.json"
$Timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$TempFile = Join-Path $HaloDir ("state.json.{0}.{1}.tmp" -f $PID, [Guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Force -Path $HaloDir | Out-Null
    if (Test-Path $StateFile) {
        try {
            $PreviousTimestamp = (Get-Content -Raw $StateFile | ConvertFrom-Json).updatedAt
            if ([long]$PreviousTimestamp -ge $Timestamp) {
                $Timestamp = [long]$PreviousTimestamp + 1
            }
        } catch {}
    }
    $Data = @{
        state = $HaloState
        updatedAt = $Timestamp
        event = $HookEvent
    } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($TempFile, $Data, (New-Object Text.UTF8Encoding($false)))
    Move-Item -Force -Path $TempFile -Destination $StateFile
} finally {
    Remove-Item -Force -ErrorAction SilentlyContinue $TempFile
}

if ($HookEvent -eq "Stop") {
    Write-Output "{}"
}
exit 0

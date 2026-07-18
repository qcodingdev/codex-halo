param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Install", "Uninstall", "Verify")]
    [string]$Operation,
    [Parameter(Mandatory = $true)]
    [string]$HooksPath,
    [string]$Command = ""
)

$ErrorActionPreference = "Stop"
$Events = @("UserPromptSubmit", "PreToolUse", "PostToolUse", "PermissionRequest", "Stop")
$Marker = "\.codex-halo\codex-halo-hook.ps1"

function Test-HaloHandler($Handler) {
    return $null -ne $Handler -and
        $null -ne $Handler.command -and
        [string]$Handler.command -like "*$Marker*"
}

function Get-HaloHandlerCount($Hooks) {
    $Count = 0
    foreach ($Property in $Hooks.PSObject.Properties) {
        foreach ($Group in @($Property.Value)) {
            foreach ($Handler in @($Group.hooks)) {
                if (Test-HaloHandler $Handler) { $Count++ }
            }
        }
    }
    return $Count
}

if (Test-Path $HooksPath) {
    $Document = Get-Content -Raw -Path $HooksPath | ConvertFrom-Json
} else {
    $Document = [PSCustomObject]@{
        description = "User lifecycle hooks."
        hooks = [PSCustomObject]@{}
    }
}

if ($null -eq $Document -or $Document -is [Array]) {
    throw "hooks.json must contain a JSON object."
}
if ($null -eq $Document.hooks) {
    $Document | Add-Member -MemberType NoteProperty -Name hooks -Value ([PSCustomObject]@{})
}

if ($Operation -eq "Verify") {
    Write-Output (Get-HaloHandlerCount $Document.hooks)
    exit 0
}

foreach ($Property in @($Document.hooks.PSObject.Properties)) {
    $Groups = @($Property.Value)
    $UpdatedGroups = @()
    foreach ($Group in $Groups) {
        if ($null -eq $Group.hooks) {
            throw "Every hook matcher group must contain a hooks array."
        }
        $Handlers = @($Group.hooks | Where-Object { -not (Test-HaloHandler $_) })
        if ($Handlers.Count -gt 0) {
            $Group.hooks = $Handlers
            $UpdatedGroups += $Group
        }
    }
    if ($UpdatedGroups.Count -gt 0) {
        $Property.Value = $UpdatedGroups
    } else {
        $Document.hooks.PSObject.Properties.Remove($Property.Name)
    }
}

if ($Operation -eq "Install") {
    if ($Command -notlike "*$Marker*") {
        throw "Unexpected Halo hook command."
    }
    foreach ($EventName in $Events) {
        $Group = [PSCustomObject]@{
            hooks = @([PSCustomObject]@{
                type = "command"
                command = $Command
                timeout = 3
            })
        }
        $Property = $Document.hooks.PSObject.Properties[$EventName]
        if ($null -eq $Property) {
            $Document.hooks | Add-Member -MemberType NoteProperty -Name $EventName -Value @($Group)
        } else {
            $Property.Value = @($Property.Value) + @($Group)
        }
    }
}

$Parent = Split-Path -Parent $HooksPath
New-Item -ItemType Directory -Force -Path $Parent | Out-Null
$Temp = "$HooksPath.$PID.tmp"
$Json = $Document | ConvertTo-Json -Depth 20
[IO.File]::WriteAllText($Temp, $Json + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
if (Test-Path $HooksPath) {
    [IO.File]::Replace($Temp, $HooksPath, $null)
} else {
    Move-Item -Path $Temp -Destination $HooksPath
}
Write-Output (Get-HaloHandlerCount $Document.hooks)

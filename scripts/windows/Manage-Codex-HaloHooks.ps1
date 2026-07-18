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
$BeginMarker = "# >>> Codex Halo managed hooks >>>"
$EndMarker = "# <<< Codex Halo managed hooks <<<"

function Test-HaloHandler($Handler) {
    return $null -ne $Handler -and $null -ne $Handler.command -and [string]$Handler.command -like "*$Marker*"
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

function Write-Atomically([string]$Path, [string]$Content) {
    $Parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $Parent | Out-Null
    $Temp = "$Path.$PID.tmp"
    [IO.File]::WriteAllText($Temp, $Content, (New-Object Text.UTF8Encoding($false)))
    if (Test-Path $Path) {
        $ReplacementBackup = "$Path.$PID.replace-backup"
        try { [IO.File]::Replace($Temp, $Path, $ReplacementBackup) }
        finally { Remove-Item -Force -ErrorAction SilentlyContinue $ReplacementBackup }
    } else {
        Move-Item -Path $Temp -Destination $Path
    }
}

function Manage-LegacyJson {
    if (Test-Path $HooksPath) { $Document = Get-Content -Raw -Path $HooksPath | ConvertFrom-Json }
    else { $Document = [PSCustomObject]@{ description = "User lifecycle hooks."; hooks = [PSCustomObject]@{} } }
    if ($null -eq $Document -or $Document -is [Array]) { throw "hooks.json must contain a JSON object." }
    if ($null -eq $Document.hooks) { $Document | Add-Member -MemberType NoteProperty -Name hooks -Value ([PSCustomObject]@{}) }
    if ($Operation -eq "Verify") { return Get-HaloHandlerCount $Document.hooks }
    foreach ($Property in @($Document.hooks.PSObject.Properties)) {
        $UpdatedGroups = @()
        foreach ($Group in @($Property.Value)) {
            if ($null -eq $Group.hooks) { throw "Every hook matcher group must contain a hooks array." }
            $Handlers = @($Group.hooks | Where-Object { -not (Test-HaloHandler $_) })
            if ($Handlers.Count -gt 0) { $Group.hooks = $Handlers; $UpdatedGroups += $Group }
        }
        if ($UpdatedGroups.Count -gt 0) { $Property.Value = $UpdatedGroups }
        else { $Document.hooks.PSObject.Properties.Remove($Property.Name) }
    }
    if ($Operation -eq "Install") {
        if ($Command -notlike "*$Marker*") { throw "Unexpected Halo hook command." }
        foreach ($EventName in $Events) {
            $Group = [PSCustomObject]@{ hooks = @([PSCustomObject]@{ type = "command"; command = $Command; timeout = 3 }) }
            $Property = $Document.hooks.PSObject.Properties[$EventName]
            if ($null -eq $Property) { $Document.hooks | Add-Member -MemberType NoteProperty -Name $EventName -Value @($Group) }
            else { $Property.Value = @($Property.Value) + @($Group) }
        }
    } elseif ($Operation -ne "Uninstall") { throw "Unknown operation: $Operation" }
    Write-Atomically $HooksPath (($Document | ConvertTo-Json -Depth 20) + [Environment]::NewLine)
    return Get-HaloHandlerCount $Document.hooks
}

function Get-ManagedTomlBlock([string]$Text) {
    $First = $Text.IndexOf($BeginMarker, [StringComparison]::Ordinal)
    if ($First -lt 0) {
        if ($Text.Contains($EndMarker)) { throw "Codex Halo TOML marker is incomplete." }
        return [PSCustomObject]@{ Before = $Text; Section = ""; After = "" }
    }
    if ($First -ne $Text.LastIndexOf($BeginMarker, [StringComparison]::Ordinal)) { throw "More than one Codex Halo TOML block exists; stopping safely." }
    $End = $Text.IndexOf($EndMarker, $First, [StringComparison]::Ordinal)
    if ($End -lt 0 -or $End -ne $Text.LastIndexOf($EndMarker, [StringComparison]::Ordinal)) { throw "Codex Halo TOML marker is incomplete." }
    $AfterStart = $End + $EndMarker.Length
    if ($Text.Substring($AfterStart).StartsWith("`r`n")) { $AfterStart += 2 }
    elseif ($Text.Substring($AfterStart).StartsWith("`n")) { $AfterStart += 1 }
    return [PSCustomObject]@{ Before = $Text.Substring(0, $First); Section = $Text.Substring($First, $End + $EndMarker.Length - $First); After = $Text.Substring($AfterStart) }
}

function Get-TomlHandlerCount([string]$Section) {
    if ([string]::IsNullOrEmpty($Section)) { return 0 }
    $Count = 0
    foreach ($EventName in $Events) {
        if ($Section.Contains("[[hooks.$EventName]]") -and $Section.Contains("[[hooks.$EventName.hooks]]")) { $Count++ }
    }
    return $Count
}

function New-HaloTomlBlock {
    if ($Command -notlike "*$Marker*") { throw "Unexpected Halo hook command." }
    $EscapedCommand = $Command.Replace('\', '\\').Replace('"', '\"')
    $Entries = foreach ($EventName in $Events) {
        "[[hooks.$EventName]]`n[[hooks.$EventName.hooks]]`ntype = `"command`"`ncommand = `"$EscapedCommand`"`ntimeout = 3"
    }
    return "$BeginMarker`n# Installed by Codex Halo. Remove only with its uninstaller.`n$($Entries -join "`n`n")`n$EndMarker"
}

function Manage-Toml {
    $Original = if (Test-Path $HooksPath) { Get-Content -Raw -Path $HooksPath } else { "" }
    $Block = Get-ManagedTomlBlock $Original
    if ($Operation -eq "Verify") { return Get-TomlHandlerCount $Block.Section }
    if ($Operation -ne "Install" -and $Operation -ne "Uninstall") { throw "Unknown operation: $Operation" }
    $Retained = ($Block.Before + $Block.After).TrimEnd()
    if ($Operation -eq "Install") {
        $Separator = if ($Retained) { "`n`n" } else { "" }
        $Output = $Retained + $Separator + (New-HaloTomlBlock) + "`n"
    } elseif ($Retained) {
        $Output = $Retained + "`n"
    } else {
        $Output = ""
    }
    Write-Atomically $HooksPath $Output
    return $(if ($Operation -eq "Install") { 5 } else { 0 })
}

if ($HooksPath.EndsWith(".json", [StringComparison]::OrdinalIgnoreCase)) { Write-Output (Manage-LegacyJson) }
else { Write-Output (Manage-Toml) }

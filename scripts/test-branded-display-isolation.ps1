# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param([Parameter(Mandatory = $true)][string] $RuntimeRoot)
$ErrorActionPreference = 'Stop'
$system = Join-Path ([IO.Path]::GetFullPath($RuntimeRoot)) 'System64'
$localRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../local')).TrimEnd('\') + '\'
if (-not $system.StartsWith($localRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'This test changes display settings; use a disposable copy under repository local/.'
}

function Read-DisplaySettings([string] $Profile) {
    $active = $false
    $result = @{}
    foreach ($line in Get-Content -LiteralPath (Join-Path $system $Profile)) {
        if ($line -match '^\[(.+)\]$') { $active = $Matches[1] -eq 'XInputWinDrv.WindowsClient' }
        elseif ($active -and $line -match '^([^=]+)=(.*)$') { $result[$Matches[1]] = $Matches[2] }
    }
    return $result
}

function Run-DisplayCheck([string] $Name, [string] $InactiveProfile, [string[]] $Commands) {
    $inactivePath = Join-Path $system $InactiveProfile
    $beforeHash = (Get-FileHash -LiteralPath $inactivePath).Hash
    $arguments = @{ FilePath=(Join-Path $system "$Name.exe"); WorkingDirectory=$system; WindowStyle='Hidden'; PassThru=$true }
    if ($Commands) {
        $execName = "$Name-display-isolation.txt"
        Set-Content -LiteralPath (Join-Path $system $execName) -Value $Commands -Encoding ASCII
        $arguments.ArgumentList = "exec=$execName"
    }
    $game = Start-Process @arguments
    try {
        Start-Sleep -Seconds 15
        $game.Refresh()
        if ($game.HasExited) { throw "$Name exited before display validation" }
        [void]$game.CloseMainWindow()
        if (-not $game.WaitForExit(10000)) { throw "$Name did not close normally" }
    } finally { if (-not $game.HasExited) { $game.Kill(); $game.WaitForExit() } }
    if ((Get-FileHash -LiteralPath $inactivePath).Hash -ne $beforeHash) { throw "$Name changed the inactive $InactiveProfile" }
    $log = Get-Content -LiteralPath (Join-Path $system "$Name.log") -Raw
    if ($log -notmatch 'Game engine initialized' -or $log -match 'Critical:|Connection attempt failed') { throw "$Name startup failed" }
    Write-Host "PASS: $Name left $InactiveProfile byte-for-byte unchanged."
}

Run-DisplayCheck 'UnrealRevivedVR' 'Unreal.ini' @('SetScreenMode Windowed', 'SetRes 1440x900')
$vr = Read-DisplaySettings 'UnrealVR.ini'
if ($vr.StartupFullscreen -ne 'False' -or $vr.StartupBorderless -ne 'False' -or $vr.WindowedViewportX -ne '1440' -or $vr.WindowedViewportY -ne '900') { throw 'VR display change was not saved' }
Run-DisplayCheck 'UnrealRevived' 'UnrealVR.ini' @('SetScreenMode Windowed', 'SetScreenMode Fullscreen', 'SetRes 1600x900')
$desktop = Read-DisplaySettings 'Unreal.ini'
if ($desktop.StartupFullscreen -ne 'True' -or $desktop.StartupBorderless -ne 'False' -or $desktop.FullscreenViewportX -ne '1600' -or $desktop.FullscreenViewportY -ne '900') { throw 'Desktop display change was not saved' }

Run-DisplayCheck 'UnrealRevivedVR' 'Unreal.ini' @()
$vrAfter = Read-DisplaySettings 'UnrealVR.ini'
foreach ($key in @('StartupFullscreen','StartupBorderless','WindowedViewportX','WindowedViewportY')) {
    if ($vrAfter[$key] -ne $vr[$key]) { throw "VR relaunch changed $key" }
}
Run-DisplayCheck 'UnrealRevived' 'UnrealVR.ini' @()
$desktopAfter = Read-DisplaySettings 'Unreal.ini'
foreach ($key in @('StartupFullscreen','StartupBorderless','FullscreenViewportX','FullscreenViewportY')) {
    if ($desktopAfter[$key] -ne $desktop[$key]) { throw "Desktop relaunch changed $key" }
}
Write-Host 'PASS: VR retained 1440x900 windowed; desktop retained 1600x900 fullscreen after changing and relaunching both modes.'

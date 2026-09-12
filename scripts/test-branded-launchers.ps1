# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

# Run only against a disposable copy: the engine updates configuration on exit.
param([Parameter(Mandatory = $true)][string] $RuntimeRoot)
$ErrorActionPreference = 'Stop'
$system = Join-Path ([IO.Path]::GetFullPath($RuntimeRoot)) 'System64'
$repoLocal = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../local')).TrimEnd('\') + '\'
if (-not $system.StartsWith($repoLocal, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Launch validation requires a disposable runtime under repository local/.'
}
$originalHashes = @{}
foreach ($name in @('Core.dll','Engine.dll','Render.dll','Unreal.exe','WinDrv.dll','D3D12Drv.dll','XInputWinDrv.dll','ModernMenu.u')) {
    $originalHashes[$name] = (Get-FileHash -LiteralPath (Join-Path $system $name)).Hash
}
function Invoke-LaunchCheck {
    param([string] $Name, [string] $Arguments, [string] $LogName, [bool] $VR)
    $path = Join-Path $system "$Name.exe"
    $start = @{ FilePath=$path; WorkingDirectory=$env:TEMP; WindowStyle='Hidden'; PassThru=$true }
    if ($Arguments) { $start.ArgumentList = $Arguments }
    $game = Start-Process @start
    try {
        Start-Sleep -Seconds 8
        $game.Refresh()
        if ($game.HasExited) { throw "$Name exited early ($($game.ExitCode))" }
        $modules = @($game.Modules | ForEach-Object ModuleName)
        foreach ($module in @('Engine.dll','D3D12Drv.dll','XInputWinDrv.dll')) {
            if ($module -notin $modules) { throw "$Name does not host $module in its own process" }
        }
        Write-Host "$Name PID $($game.Id): owns Engine/D3D12/Input; window title: $($game.MainWindowTitle)"
        [void]$game.CloseMainWindow()
        if (-not $game.WaitForExit(5000)) { throw "$Name did not shut down normally" }
    } finally { if (-not $game.HasExited) { $game.Kill(); $game.WaitForExit() } }
    $log = Get-Content -LiteralPath (Join-Path $system $LogName) -Raw
    if ($log -notmatch 'Game engine initialized' -or $log -notmatch 'Browse: (Unreal|NyLeve)\.unr') { throw "$Name did not initialize the map" }
    if ($log -match 'Connection attempt failed|Pending connect to|Critical:|No localization: UnrealRevived') { throw "$Name reported a startup failure" }
    $expected = if ($VR) { 'requested by command-line -vr' } else { 'disabled; loader not queried \(command-line -novr\)' }
    if ($log -notmatch $expected) { throw "$Name did not select its mode" }
    if ($VR -and $log -notmatch 'logical render size 1280x1024') { throw 'VR mirror dimensions changed' }
    $log -split "`r?`n" | Where-Object { $_ -match 'Command line:|headset detected|headset unavailable|runtime=|D3D12 session|logical render size' } | Write-Host
    Write-Host "PASS: $Name $LogName"
}
Invoke-LaunchCheck 'UnrealRevived' '' 'UnrealRevived.log' $false
Invoke-LaunchCheck 'UnrealRevivedVR' '' 'UnrealRevivedVR.log' $true
Invoke-LaunchCheck 'UnrealRevivedVR' 'NyLeve.unr -novr ini=Wrong.ini userini=WrongUser.ini log="VR launch with spaces.log"' 'VR launch with spaces.log' $true
foreach ($name in @('UnrealRevived', 'UnrealRevivedVR')) {
    $vr = $name -eq 'UnrealRevivedVR'
    $mode = if ($vr) { '-vr' } else { '-novr' }
    $ini = if ($vr) { 'UnrealVR.ini' } else { 'Unreal.ini' }
    $logName = "$name-restart-$(Get-Date -Format yyyyMMddHHmmss).log"
    $execFile = Join-Path $system "$name-restart-test.txt"
    # This is the same RELAUNCH command issued by Preferences Restart.
    Set-Content -LiteralPath $execFile -Encoding ASCII -Value "RELAUNCH Unreal.unr?Game=ModernMenu.ModernIntro ini=$ini userini=User.ini $mode log=$logName"
    $path = Join-Path $system "$name.exe"
    $before = @(Get-Process -Name UnrealRevived,UnrealRevivedVR -ErrorAction SilentlyContinue | ForEach-Object Id)
    $game = Start-Process -FilePath $path -ArgumentList "exec=$name-restart-test.txt" -WorkingDirectory $system -WindowStyle Hidden -PassThru
    try {
        Start-Sleep -Seconds 12
        $children = @(Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object { $_.Id -notin $before -and $_.Id -ne $game.Id -and $_.Path -eq $path })
        if (-not $game.HasExited -or $children.Count -ne 1) { throw "$name restart did not replace itself with the same executable" }
        [void]$children[0].CloseMainWindow()
        if (-not $children[0].WaitForExit(5000)) { throw "$name restarted process did not close normally" }
        $log = Get-Content -LiteralPath (Join-Path $system $logName) -Raw
        if ($log -notmatch 'Game engine initialized' -or $log -notmatch "ini=$ini userini=User.ini $mode") { throw "$name restart lost mode/profile" }
        if ($log -match 'Connection attempt failed|Pending connect to|Critical:') { throw "$name restart reported an error" }
        Write-Host "PASS: $name Preferences RELAUNCH stays in the same executable, mode and profile."
    } finally {
        Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object { $_.Id -notin $before -and $_.Path -eq $path } | ForEach-Object { Stop-Process -Id $_.Id -Force }
    }
}
foreach ($name in $originalHashes.Keys) {
    if ((Get-FileHash -LiteralPath (Join-Path $system $name)).Hash -ne $originalHashes[$name]) { throw "Baseline module changed: $name" }
}
Write-Host 'PASS: all baseline engine/renderer/input/game-package hashes unchanged.'

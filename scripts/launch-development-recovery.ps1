# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [Parameter(Mandatory = $true)]
    [string] $GameRoot
)

$ErrorActionPreference = 'Stop'

$runtimeRoot = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot $GameRoot
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force
$system64 = Join-Path $runtimeRoot 'System64'
$unrealExe = Join-Path $system64 'Unreal.exe'
$runningMarker = Join-Path $system64 'Running.ini'
$sourceIni = Join-Path $system64 'D3D12Test.ini'
$recoveryIniName = 'D3D12Recovery.ini'
$recoveryIni = Join-Path $system64 $recoveryIniName

$activeGame = Get-Process Unreal -ErrorAction SilentlyContinue |
    Where-Object { [string]::Equals($_.Path, $unrealExe, [StringComparison]::OrdinalIgnoreCase) } |
    Select-Object -First 1

if ($activeGame) {
    $shell = New-Object -ComObject WScript.Shell
    $shell.Popup('Close Unreal before launching recovery mode.', 0, 'Unreal Revived Recovery', 48) | Out-Null
    exit 1
}

$recoveryLines = Get-Content -LiteralPath $sourceIni
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'Engine.Engine' 'ViewportManager' 'XInputWinDrv.WindowsClient'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'UseJoystick' 'True'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'UseXInput' 'True'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'XInputFallbackToWinMM' 'True'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'XInputControllerIndex' '-1'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'DeadZoneXYZ' 'True'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'DeadZoneRUV' 'True'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'LeftStickDeadZonePercent' '25.000000'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'RightStickDeadZonePercent' '25.000000'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'ScaleXYZ' '100.000000'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'ScaleRUV' '100.000000'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'InvertVertical' 'True'
$recoveryLines = Set-UnrealRevivedIniValue $recoveryLines 'XInputWinDrv.WindowsClient' 'UseRawHIDInput' 'True'
Set-Content -LiteralPath $recoveryIni -Value $recoveryLines -Encoding ASCII

New-Item -Path $runningMarker -ItemType File -Force | Out-Null
Start-Process -FilePath $unrealExe -WorkingDirectory $system64 -ArgumentList @(
    'Unreal.unr',
    "ini=$recoveryIniName",
    'userini=D3D12TestUser.ini',
    '-novr'
)

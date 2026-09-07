# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param()

$ErrorActionPreference = 'Stop'

$oldUnrealRoot = 'C:\Unreal'
if (Test-Path -LiteralPath (Join-Path $oldUnrealRoot 'System\Unreal.exe') -PathType Leaf) {
    Write-Output ([IO.Path]::GetFullPath($oldUnrealRoot))
    exit 0
}

$steamRoots = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($registryPath in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam')) {
    $steam = Get-ItemProperty -LiteralPath $registryPath -ErrorAction SilentlyContinue
    foreach ($value in @($steam.SteamPath, $steam.InstallPath)) {
        if ($value) {
            $null = $steamRoots.Add([IO.Path]::GetFullPath($value))
        }
    }
}

foreach ($steamRoot in $steamRoots) {
    $steamAppsRoots = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $null = $steamAppsRoots.Add((Join-Path $steamRoot 'steamapps'))
    $libraryFile = Join-Path $steamRoot 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $libraryFile -PathType Leaf) {
        foreach ($line in Get-Content -LiteralPath $libraryFile) {
            if ($line -match '^\s*"path"\s+"(.+)"') {
                $libraryPath = $Matches[1] -replace '\\\\', '\'
                $null = $steamAppsRoots.Add((Join-Path $libraryPath 'steamapps'))
            }
        }
    }

    foreach ($steamAppsRoot in $steamAppsRoots) {
        $manifestPath = Join-Path $steamAppsRoot 'appmanifest_13250.acf'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            continue
        }

        $manifestText = Get-Content -LiteralPath $manifestPath -Raw
        if ($manifestText -notmatch '"installdir"\s+"([^"]+)"') {
            continue
        }

        $gameRoot = Join-Path $steamAppsRoot "common\$($Matches[1])"
        if (Test-Path -LiteralPath (Join-Path $gameRoot 'System\Unreal.exe') -PathType Leaf) {
            Write-Output ([IO.Path]::GetFullPath($gameRoot))
            exit 0
        }
    }
}

throw @'
Could not find an Unreal Gold installation in C:\Unreal or the registered Steam libraries.
Install Unreal Gold using OldUnreal's official installer:
https://www.oldunreal.com/downloads/unreal/full-game-installers/

Then rerun bootstrap, or pass -OriginalGameRoot with the folder containing System\Unreal.exe.
'@
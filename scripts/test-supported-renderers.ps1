# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [ValidateRange(3, 120)]
    [int]$RunSeconds = 8
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class UnrealRendererSmokeExit
{
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PostThreadMessage(uint threadId, uint message, UIntPtr wParam, IntPtr lParam);
}
'@
$gameRoot = if ($env:UE1_GAME_ROOT) { [IO.Path]::GetFullPath($env:UE1_GAME_ROOT) } else { Join-Path $repoRoot 'local/game' }
$null = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot $gameRoot
$systemDir = Join-Path $gameRoot 'System64'
$unrealExe = Join-Path $systemDir 'Unreal.exe'
$sourceIni = Join-Path $systemDir 'D3D12Test.ini'
$userIni = Join-Path $systemDir 'D3D12TestUser.ini'
$runtimeLog = Join-Path $systemDir 'Unreal.log'
$runningMarker = Join-Path $systemDir 'Running.ini'
$evidenceRoot = Join-Path $repoRoot (Join-Path 'local/logs' ("supported-renderers-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
$maps = @('NyLeve', 'DmDeck16', 'Chizra', 'Vortex2', 'Dug', 'Terraniux')
$renderers = @(
    [pscustomobject]@{ Name = 'd3d12'; Class = 'D3D12Drv.D3D12RenderDevice'; Module = 'D3D12Drv.dll' }
    [pscustomobject]@{ Name = 'opengl'; Class = 'OpenGLDrv.OpenGLRenderDevice'; Module = 'OpenGLDrv.dll' }
    [pscustomobject]@{ Name = 'xopengl'; Class = 'XOpenGLDrv.XOpenGLRenderDevice'; Module = 'XOpenGLDrv.dll' }
)

foreach ($requiredPath in @($unrealExe, $sourceIni, $userIni)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required disposable-runtime file is missing: $requiredPath"
    }
}
if (Get-Process Unreal -ErrorAction SilentlyContinue) {
    throw 'Unreal is already running. Close it before starting automated checks.'
}
# This script is restricted to the disposable development runtime. A marker left
# by an interrupted prior test would otherwise open Recovery Mode for every case.
Remove-Item -LiteralPath $runningMarker -Force -ErrorAction SilentlyContinue

function Set-IniValue {
    param(
        [string[]]$Lines,
        [string]$Section,
        [string]$Key,
        [string]$Value
    )

    $inSection = $false
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^\[(.+)\]$') {
            $inSection = $Matches[1] -eq $Section
            continue
        }
        if ($inSection -and $Lines[$index] -match ('^{0}=' -f [regex]::Escape($Key))) {
            $Lines[$index] = "$Key=$Value"
            return $Lines
        }
    }
    throw "Could not find $Key in [$Section]."
}

function Request-UnrealExit([System.Diagnostics.Process]$Process) {
    $Process.Refresh()
    $posted = $false
    foreach ($thread in $Process.Threads) {
        if ([UnrealRendererSmokeExit]::PostThreadMessage($thread.Id, 0x0012, [UIntPtr]::Zero, [IntPtr]::Zero)) {
            $posted = $true
        }
    }
    if (-not $posted) {
        throw 'Could not post a clean shutdown request to any Unreal process thread.'
    }
}

$sourceHash = (Get-FileHash -LiteralPath $sourceIni -Algorithm SHA256).Hash
$userHash = (Get-FileHash -LiteralPath $userIni -Algorithm SHA256).Hash
$results = @()
$process = $null
$temporaryIni = $null
New-Item -ItemType Directory -Force -Path $evidenceRoot | Out-Null

try {
    foreach ($renderer in $renderers) {
        foreach ($map in $maps) {
            $caseName = "$($renderer.Name)-$($map.ToLowerInvariant())"
            $caseDir = Join-Path $evidenceRoot $caseName
            $temporaryIniName = "RendererSmoke-$($renderer.Name).ini"
            $temporaryIni = Join-Path $systemDir $temporaryIniName
            New-Item -ItemType Directory -Force -Path $caseDir | Out-Null

            $iniLines = Get-Content -LiteralPath $sourceIni
            $iniLines = Set-IniValue $iniLines 'Engine.Engine' 'GameRenderDevice' $renderer.Class
            $iniLines = Set-IniValue $iniLines 'Engine.Engine' 'WindowedRenderDevice' $renderer.Class
            # Renderer smoke tests must never request an exclusive display-mode change.
            # Besides disrupting the desktop, a rejected mode switch opens an interactive
            # Failed3D dialog and can leave the otherwise healthy test process waiting on it.
            $iniLines = Set-IniValue $iniLines 'WinDrv.WindowsClient' 'StartupFullscreen' 'False'
            $iniLines = Set-IniValue $iniLines 'XInputWinDrv.WindowsClient' 'StartupFullscreen' 'False'
            Set-Content -LiteralPath $temporaryIni -Value $iniLines -Encoding Unicode
            Copy-Item -LiteralPath $temporaryIni -Destination (Join-Path $caseDir $temporaryIniName)
            Remove-Item -LiteralPath $runtimeLog -Force -ErrorAction SilentlyContinue

            $arguments = @($map, "ini=$temporaryIniName", 'userini=D3D12TestUser.ini', '-nosplash', '-windowed')
            Write-Host "Running ${caseName}: $($arguments -join ' ')"
            $process = Start-Process -FilePath $unrealExe -ArgumentList $arguments -WorkingDirectory $systemDir -PassThru
            if ($process.WaitForExit($RunSeconds * 1000)) {
                throw "$caseName exited before its $RunSeconds-second observation window."
            }
            $openXRLoaderLoaded = @($process.Modules | Where-Object { $_.ModuleName -ieq 'openxr_loader.dll' }).Count -gt 0
            Request-UnrealExit $process
            if (-not $process.WaitForExit(15000)) {
                $process.Refresh()
                throw "$caseName did not exit within 15 seconds after a clean shutdown request (window='$($process.MainWindowTitle)', handle=$($process.MainWindowHandle))."
            }
            $process = $null

            if (-not (Test-Path -LiteralPath $runtimeLog -PathType Leaf)) {
                throw "$caseName did not produce Unreal.log."
            }
            $caseLog = Join-Path $caseDir 'Unreal.log'
            Copy-Item -LiteralPath $runtimeLog -Destination $caseLog
            $logText = Get-Content -LiteralPath $caseLog -Raw
            $filteredLog = $logText -replace "(?m)^Warning: Failed to load 'EntryIII\.unr': Can't find file 'EntryIII\.unr'\r?\n?|^Warning: Failed to load 'Level None\.MyLevel': Can't find file 'EntryIII\.unr'\r?\n?", ''
            if (-not $logText.Contains("LoadMap: $map")) {
                throw "$caseName did not load $map."
            }
            if (-not $logText.Contains("Bound to $($renderer.Module)") -or -not $logText.Contains("Unbound to $($renderer.Module)")) {
                throw "$caseName did not complete a clean $($renderer.Module) bind/unbind cycle."
            }
            if ($filteredLog -match "Critical Error|Assertion|General protection fault|Can't find file|Failed to load|Missing package|Package .* not found|Failed to set resolution|ChangeDisplaySettings failed|Errors\.Failed3D") {
                throw "$caseName contains a runtime failure signature."
            }
            if ($renderer.Name -eq 'd3d12' -and
                ($openXRLoaderLoaded -or -not $logText.Contains('Unreal Revived OpenXR: disabled; loader not queried (flat-screen default)'))) {
                throw "$caseName did not preserve strict flat-screen OpenXR isolation."
            }

            $results += [pscustomobject]@{ Renderer = $renderer.Class; Map = $map; Result = 'Passed' }
        }
        Remove-Item -LiteralPath $temporaryIni -Force -ErrorAction SilentlyContinue
        $temporaryIni = $null
    }
} finally {
    if ($process -and -not $process.HasExited) {
        try { Request-UnrealExit $process } catch {}
        if (-not $process.WaitForExit(5000)) {
            Stop-Process -Id $process.Id -Force
            $process.WaitForExit()
        }
    }
    Remove-Item -LiteralPath $runningMarker -Force -ErrorAction SilentlyContinue
    if ($temporaryIni) {
        Remove-Item -LiteralPath $temporaryIni -Force -ErrorAction SilentlyContinue
    }
}

if ((Get-FileHash -LiteralPath $sourceIni -Algorithm SHA256).Hash -ne $sourceHash) {
    throw 'D3D12Test.ini changed during supported-renderer testing.'
}
if ((Get-FileHash -LiteralPath $userIni -Algorithm SHA256).Hash -ne $userHash) {
    throw 'D3D12TestUser.ini changed during supported-renderer testing.'
}

$results | Export-Csv -LiteralPath (Join-Path $evidenceRoot 'results.csv') -NoTypeInformation
$results | Format-Table -AutoSize
Write-Host "All supported renderer checks passed. Evidence: $evidenceRoot"

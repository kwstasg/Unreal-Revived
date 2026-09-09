# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [ValidateSet('Content', 'Settings', 'MenuDisplay', 'Input', 'VRFoundation', 'All')]
    [string]$Suite = 'Content',

    [string[]]$Maps,

    [ValidateRange(3, 120)]
    [int]$RunSeconds = 8,

    [ValidateSet('Off', 'Capture', 'Update', 'Compare')]
    [string]$ScreenshotMode = 'Off',

    [ValidateSet('int', 'elt')]
    [string]$Language = 'int',

    [ValidateRange(0, 255)]
    [double]$MaxMeanChannelDelta = 12,

    [ValidateRange(0, 1)]
    [double]$MaxChangedSampleRatio = 0.12,

    [switch]$MeasurePerformance
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force

Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class UnrealAutomationExit
{
    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PostThreadMessage(uint threadId, uint message, UIntPtr wParam, IntPtr lParam);
}
'@

if ($ScreenshotMode -ne 'Off') {
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class ScreenshotInput
{
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr window, out WindowRect rect);

    [StructLayout(LayoutKind.Sequential)]
    public struct WindowRect
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
'@
}

$gameRoot = if ($env:UE1_GAME_ROOT) { [IO.Path]::GetFullPath($env:UE1_GAME_ROOT) } else { Join-Path $repoRoot 'local/game' }
$null = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot $gameRoot
$systemDir = Join-Path $gameRoot 'System64'
$unrealExe = Join-Path $systemDir 'Unreal.exe'
$sourceIni = Join-Path $systemDir 'D3D12Test.ini'
$userIni = Join-Path $systemDir 'D3D12TestUser.ini'
$temporaryIniName = 'D3D12Automation.ini'
$temporaryIni = Join-Path $systemDir $temporaryIniName
$runtimeLog = Join-Path $systemDir 'Unreal.log'
$runningMarker = Join-Path $systemDir 'Running.ini'
$evidenceRoot = Join-Path $repoRoot (Join-Path 'local/logs' ("automated-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
$screenshotBaselineRoot = Join-Path $repoRoot 'local/logs/screenshot-baselines'

foreach ($requiredPath in @($unrealExe, $sourceIni, $userIni)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required disposable-runtime file is missing: $requiredPath"
    }
}

if (Get-Process Unreal -ErrorAction SilentlyContinue) {
    throw 'Unreal is already running. Close it before starting automated checks.'
}
# A marker left by an interrupted development run would otherwise open Recovery
# Mode instead of the requested test map.
Remove-Item -LiteralPath $runningMarker -Force -ErrorAction SilentlyContinue

function Set-IniValue {
    param(
        [string[]]$Lines,
        [string]$Section,
        [string]$Key,
        [string]$Value
    )

    $inSection = $false
    $found = $false
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^\[(.+)\]$') {
            $inSection = $Matches[1] -eq $Section
            continue
        }

        if ($inSection -and $Lines[$index] -match ('^{0}=' -f [regex]::Escape($Key))) {
            $Lines[$index] = "$Key=$Value"
            $found = $true
            break
        }
    }

    if (-not $found) {
        throw "Could not find $Key in [$Section]."
    }

    return $Lines
}

function New-TestCase {
    param(
        [string]$Name,
        [string]$Map,
        [hashtable]$Settings = @{},
        [hashtable]$ProfileSettings = @{},
        [string[]]$AdditionalArguments = @(),
        [ValidateSet('Disabled', 'DisabledOverride', 'Requested')]
        [string]$OpenXRExpectation = 'Disabled',
        [bool]$CompareScreenshot = $true,
        [bool]$CloneWindowsClient = $false
    )

    [pscustomobject]@{
        Name = $Name
        Map = $Map
        Settings = $Settings
        ProfileSettings = $ProfileSettings
        AdditionalArguments = $AdditionalArguments
        OpenXRExpectation = $OpenXRExpectation
        CompareScreenshot = $CompareScreenshot
        CloneWindowsClient = $CloneWindowsClient
    }
}

function Wait-Interval([int]$Milliseconds) {
    $event = [System.Threading.ManualResetEventSlim]::new($false)
    try {
        $null = $event.Wait($Milliseconds)
    } finally {
        $event.Dispose()
    }
}

function Request-UnrealExit([System.Diagnostics.Process]$Process) {
    $Process.Refresh()
    $posted = $false
    foreach ($thread in $Process.Threads) {
        if ([UnrealAutomationExit]::PostThreadMessage($thread.Id, 0x0012, [UIntPtr]::Zero, [IntPtr]::Zero)) {
            $posted = $true
        }
    }
    if (-not $posted) {
        throw 'Could not post a clean shutdown request to any Unreal process thread.'
    }
}

function Save-CaseScreenshot {
    param(
        [System.Diagnostics.Process]$Process,
        [string]$CaseDir
    )

    $Process.Refresh()
    if ($Process.MainWindowHandle -eq [IntPtr]::Zero) {
        throw 'Unreal has no viewport window for screenshot capture.'
    }

    $shell = New-Object -ComObject WScript.Shell
    if (-not $shell.AppActivate($Process.Id)) {
        throw 'Could not activate the Unreal window for screenshot capture.'
    }
    Wait-Interval 500

    $rect = New-Object ScreenshotInput+WindowRect
    if (-not [ScreenshotInput]::GetWindowRect($Process.MainWindowHandle, [ref]$rect)) {
        throw 'Could not read the Unreal window bounds.'
    }
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    if ($width -lt 320 -or $height -lt 200) {
        throw "Unreal window dimensions are unexpectedly small: ${width}x${height}."
    }

    $caseScreenshot = Join-Path $CaseDir 'screenshot.png'
    $image = [System.Drawing.Bitmap]::new($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($image)
    try {
        $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $image.Size)
        $image.Save($caseScreenshot, [System.Drawing.Imaging.ImageFormat]::Png)
        $samples = @(
            $image.GetPixel([int]($image.Width * 0.25), [int]($image.Height * 0.25)).ToArgb(),
            $image.GetPixel([int]($image.Width * 0.50), [int]($image.Height * 0.50)).ToArgb(),
            $image.GetPixel([int]($image.Width * 0.75), [int]($image.Height * 0.75)).ToArgb()
        )
        if (($samples | Select-Object -Unique).Count -lt 2) {
            throw 'Screenshot sample pixels are blank or uniform.'
        }
    } finally {
        $graphics.Dispose()
        $image.Dispose()
    }

    return $caseScreenshot
}

function Compare-CaseScreenshot {
    param(
        [string]$ActualPath,
        [string]$BaselinePath
    )

    if (-not (Test-Path -LiteralPath $BaselinePath -PathType Leaf)) {
        throw "Screenshot baseline is missing: $BaselinePath. Run with -ScreenshotMode Update after reviewing the captured images."
    }

    $actual = [System.Drawing.Bitmap]::FromFile($ActualPath)
    $baseline = [System.Drawing.Bitmap]::FromFile($BaselinePath)
    try {
        if ($actual.Width -ne $baseline.Width -or $actual.Height -ne $baseline.Height) {
            throw "Screenshot dimensions differ: actual $($actual.Width)x$($actual.Height), baseline $($baseline.Width)x$($baseline.Height)."
        }

        $stepX = [Math]::Max(1, [int]($actual.Width / 128))
        $stepY = [Math]::Max(1, [int]($actual.Height / 72))
        $startY = [int]($actual.Height * 0.18)
        $endY = [int]($actual.Height * 0.90)
        $channelDelta = 0.0
        $changedSamples = 0
        $sampleCount = 0
        for ($y = $startY; $y -lt $endY; $y += $stepY) {
            for ($x = 0; $x -lt $actual.Width; $x += $stepX) {
                $actualPixel = $actual.GetPixel($x, $y)
                $baselinePixel = $baseline.GetPixel($x, $y)
                $sampleDelta = (
                    [Math]::Abs($actualPixel.R - $baselinePixel.R) +
                    [Math]::Abs($actualPixel.G - $baselinePixel.G) +
                    [Math]::Abs($actualPixel.B - $baselinePixel.B)
                ) / 3.0
                $channelDelta += $sampleDelta
                if ($sampleDelta -gt 32) {
                    $changedSamples++
                }
                $sampleCount++
            }
        }

        $meanChannelDelta = $channelDelta / $sampleCount
        $changedSampleRatio = $changedSamples / $sampleCount
        return [pscustomobject]@{
            MeanChannelDelta = [Math]::Round($meanChannelDelta, 3)
            ChangedSampleRatio = [Math]::Round($changedSampleRatio, 4)
            Passed = $meanChannelDelta -le $MaxMeanChannelDelta -and $changedSampleRatio -le $MaxChangedSampleRatio
        }
    } finally {
        $actual.Dispose()
        $baseline.Dispose()
    }
}

$contentCases = @(
    New-TestCase -Name 'content-nyleve' -Map 'NyLeve'
    New-TestCase -Name 'content-dmdeck16' -Map 'DmDeck16'
    New-TestCase -Name 'content-chizra' -Map 'Chizra'
    New-TestCase -Name 'content-vortex2' -Map 'Vortex2' -CompareScreenshot $false
    New-TestCase -Name 'content-dug' -Map 'Dug'
    New-TestCase -Name 'content-terraniux' -Map 'Terraniux' -CompareScreenshot $false
)

$settingsCases = @(
    New-TestCase -Name 'setting-msaa2' -Map 'NyLeve' -Settings @{ AntialiasMode = 'MSAA_2x' }
    New-TestCase -Name 'setting-msaa4' -Map 'NyLeve' -Settings @{ AntialiasMode = 'MSAA_4x' }
    New-TestCase -Name 'setting-msaa8' -Map 'NyLeve' -Settings @{ AntialiasMode = 'MSAA_8x' }
    New-TestCase -Name 'setting-anisotropy-off' -Map 'NyLeve' -Settings @{ MaxAnisotropy = '0' }
    New-TestCase -Name 'setting-anisotropy-16x' -Map 'NyLeve' -Settings @{ MaxAnisotropy = '16' }
    New-TestCase -Name 'setting-no-precache' -Map 'DmDeck16' -Settings @{ UsePrecache = 'False' }
    New-TestCase -Name 'setting-vsync' -Map 'NyLeve' -Settings @{ UseVSync = 'True' }
    New-TestCase -Name 'setting-one-x-lighting' -Map 'DmDeck16' -Settings @{ LightMode = 'OneXBlending' }
    New-TestCase -Name 'setting-brighter-actors' -Map 'Dug' -Settings @{ LightMode = 'BrighterActors' }
    New-TestCase -Name 'setting-xopengl-gamma' -Map 'NyLeve' -Settings @{ GammaMode = 'XOpenGL'; GammaOffset = '0.3' }
    New-TestCase -Name 'setting-lod-negative' -Map 'DmDeck16' -Settings @{ LODBias = '-1.0' }
    New-TestCase -Name 'setting-lod-positive' -Map 'DmDeck16' -Settings @{ LODBias = '1.0' }
    New-TestCase -Name 'setting-brightness-min' -Map 'NyLeve' -ProfileSettings @{ 'WinDrv.WindowsClient|Brightness' = '0.25' }
    New-TestCase -Name 'setting-brightness-max' -Map 'NyLeve' -ProfileSettings @{ 'WinDrv.WindowsClient|Brightness' = '1.0' }
    New-TestCase -Name 'setting-brightness-stale-low' -Map 'NyLeve' -ProfileSettings @{ 'WinDrv.WindowsClient|Brightness' = '0.1' }
    New-TestCase -Name 'setting-brightness-stale-high' -Map 'NyLeve' -ProfileSettings @{ 'WinDrv.WindowsClient|Brightness' = '1.5' }
    New-TestCase -Name 'setting-contrast-min' -Map 'NyLeve' -Settings @{ Contrast = '64' }
    New-TestCase -Name 'setting-contrast-max' -Map 'NyLeve' -Settings @{ Contrast = '170' }
    New-TestCase -Name 'setting-contrast-stale-low' -Map 'NyLeve' -Settings @{ Contrast = '0' }
    New-TestCase -Name 'setting-contrast-stale-high' -Map 'NyLeve' -Settings @{ Contrast = '255' }
    New-TestCase -Name 'setting-saturation' -Map 'NyLeve' -Settings @{ Saturation = '128' }
    New-TestCase -Name 'setting-bloom-off' -Map 'NyLeve' -Settings @{ Bloom = 'False'; BloomAmount = '0' }
    New-TestCase -Name 'setting-bloom' -Map 'NyLeve' -Settings @{ Bloom = 'True'; BloomAmount = '255' }
    New-TestCase -Name 'setting-chromatic-aberration-off' -Map 'NyLeve' -Settings @{ Bloom = 'False'; BloomAmount = '0'; ChromaticAberration = '0' }
    New-TestCase -Name 'setting-chromatic-aberration-max' -Map 'NyLeve' -Settings @{ Bloom = 'False'; BloomAmount = '0'; ChromaticAberration = '255' }
    New-TestCase -Name 'setting-vignette-max' -Map 'NyLeve' -Settings @{ Bloom = 'False'; BloomAmount = '0'; VignetteIntensity = '255' }
    New-TestCase -Name 'setting-film-grain-max' -Map 'NyLeve' -Settings @{ Bloom = 'False'; BloomAmount = '0'; FilmGrainAmount = '255' }
    New-TestCase -Name 'setting-scanlines-max' -Map 'NyLeve' -Settings @{ Bloom = 'False'; BloomAmount = '0'; ScanlineStrength = '255' }
    New-TestCase -Name 'setting-world-postprocess-msaa8' -Map 'NyLeve' -Settings @{ Bloom = 'True'; BloomAmount = '255'; ChromaticAberration = '255'; VignetteIntensity = '255'; FilmGrainAmount = '255'; ScanlineStrength = '255'; AntialiasMode = 'MSAA_8x' }
    New-TestCase -Name 'setting-occluded-lines' -Map 'DmDeck16' -Settings @{ OccludeLines = 'True' }
)

$menuDisplayCases = @(
    New-TestCase -Name 'menu-fps-enabled' -Map 'Unreal.unr' -ProfileSettings @{ 'ModernMenu.ModernVideoClientWindow|bShowFPS' = 'True' }
    New-TestCase -Name 'menu-fps-disabled' -Map 'Unreal.unr' -ProfileSettings @{ 'ModernMenu.ModernVideoClientWindow|bShowFPS' = 'False' }
    New-TestCase -Name 'menu-world-preview-enabled' -Map 'NyLeve' -ProfileSettings @{ 'ModernMenu.ModernHUDConfigCW|bShowGameBehindMenus' = 'True' }
    New-TestCase -Name 'menu-world-preview-disabled' -Map 'NyLeve' -ProfileSettings @{ 'ModernMenu.ModernHUDConfigCW|bShowGameBehindMenus' = 'False' }
    New-TestCase -Name 'display-1280x720' -Map 'Unreal.unr' -ProfileSettings @{ 'WinDrv.WindowsClient|FullscreenViewportX' = '1280'; 'WinDrv.WindowsClient|FullscreenViewportY' = '720' }
    New-TestCase -Name 'display-1024x768' -Map 'Unreal.unr' -ProfileSettings @{ 'WinDrv.WindowsClient|FullscreenViewportX' = '1024'; 'WinDrv.WindowsClient|FullscreenViewportY' = '768' }
    New-TestCase -Name 'display-2560x1440' -Map 'Unreal.unr' -ProfileSettings @{ 'WinDrv.WindowsClient|FullscreenViewportX' = '2560'; 'WinDrv.WindowsClient|FullscreenViewportY' = '1440' }
    New-TestCase -Name 'display-3840x2160' -Map 'Unreal.unr' -ProfileSettings @{ 'WinDrv.WindowsClient|FullscreenViewportX' = '3840'; 'WinDrv.WindowsClient|FullscreenViewportY' = '2160' }
    New-TestCase -Name 'display-3840x2160-msaa8' -Map 'NyLeve' -Settings @{ AntialiasMode = 'MSAA_8x' } -ProfileSettings @{ 'WinDrv.WindowsClient|FullscreenViewportX' = '3840'; 'WinDrv.WindowsClient|FullscreenViewportY' = '2160' }
    New-TestCase -Name 'display-windowed-1600x1024' -Map 'Unreal.unr' -ProfileSettings @{ 'WinDrv.WindowsClient|StartupFullscreen' = 'False'; 'WinDrv.WindowsClient|WindowedViewportX' = '1600'; 'WinDrv.WindowsClient|WindowedViewportY' = '1024' }
)

$inputCases = @(
    New-TestCase -Name 'input-xinputwindrv-baseline' -Map 'NyLeve' -CloneWindowsClient $true -ProfileSettings @{ 'Engine.Engine|ViewportManager' = 'XInputWinDrv.WindowsClient' }
)

$vrFoundationCases = @(
    New-TestCase -Name 'vr-command-line-opt-in' -Map 'NyLeve' -AdditionalArguments @('-vr') -OpenXRExpectation 'Requested'
    New-TestCase -Name 'vr-config-opt-in' -Map 'NyLeve' -Settings @{ EnableVR = 'True' } -OpenXRExpectation 'Requested'
    New-TestCase -Name 'vr-command-line-disable' -Map 'NyLeve' -Settings @{ EnableVR = 'True' } -AdditionalArguments @('-novr') -OpenXRExpectation 'DisabledOverride'
)

if ($Maps) {
    $cases = foreach ($map in $Maps) {
        New-TestCase -Name ("content-{0}" -f $map.ToLowerInvariant()) -Map $map
    }
} elseif ($Suite -eq 'Content') {
    $cases = $contentCases
} elseif ($Suite -eq 'Settings') {
    $cases = $settingsCases
} elseif ($Suite -eq 'MenuDisplay') {
    $cases = $menuDisplayCases
} elseif ($Suite -eq 'Input') {
    $cases = $inputCases
} elseif ($Suite -eq 'VRFoundation') {
    $cases = $vrFoundationCases
} else {
    $cases = @($contentCases) + @($settingsCases) + @($menuDisplayCases) + @($inputCases) + @($vrFoundationCases)
}

$rendererSection = 'D3D12Drv.D3D12RenderDevice'
$failurePattern = "Critical Error|Assertion|ResizeTarget failed|ResizeViewport failed|Could not resize scene buffers|Could not flush d3d12 renderer|CreateCommittedResource.*failed|CreateGraphicsPipelineState.*failed|Bound to XOpenGLDrv|Can't find file|Failed to load|Missing package|Package .* not found"
$knownEntryFallbackPattern = "(?m)^Warning: Failed to load 'EntryIII\.unr': Can't find file 'EntryIII\.unr'\r?\n?|^Warning: Failed to load 'Level None\.MyLevel': Can't find file 'EntryIII\.unr'\r?\n?"
$sourceHash = (Get-FileHash -LiteralPath $sourceIni -Algorithm SHA256).Hash
$userHash = (Get-FileHash -LiteralPath $userIni -Algorithm SHA256).Hash
$results = @()
$process = $null
$previousPerformanceEnvironment = $env:UNREAL_REVIVED_MEASURE_PERFORMANCE
New-Item -ItemType Directory -Force -Path $evidenceRoot | Out-Null

try {
    if ($MeasurePerformance) {
        $env:UNREAL_REVIVED_MEASURE_PERFORMANCE = '1'
    } else {
        Remove-Item Env:\UNREAL_REVIVED_MEASURE_PERFORMANCE -ErrorAction SilentlyContinue
    }

    foreach ($case in $cases) {
        $caseDir = Join-Path $evidenceRoot $case.Name
        New-Item -ItemType Directory -Force -Path $caseDir | Out-Null

        $iniLines = Get-Content -LiteralPath $sourceIni
        $iniLines = Set-IniValue -Lines $iniLines -Section 'Engine.Engine' -Key 'Language' -Value $Language
        if ($case.CloneWindowsClient) {
            $iniLines = Copy-UnrealRevivedIniSection $iniLines 'WinDrv.WindowsClient' 'XInputWinDrv.WindowsClient'
            $iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'UseJoystick' 'True'
            $iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'UseXInput' 'True'
            $iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'XInputFallbackToWinMM' 'True'
            $iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'XInputControllerIndex' '-1'
        }
        foreach ($setting in $case.Settings.GetEnumerator()) {
            $iniLines = Set-IniValue -Lines $iniLines -Section $rendererSection -Key $setting.Key -Value $setting.Value
        }
        foreach ($setting in $case.ProfileSettings.GetEnumerator()) {
            $section, $key = $setting.Key -split '\|', 2
            $iniLines = Set-IniValue -Lines $iniLines -Section $section -Key $key -Value $setting.Value
        }
        Set-Content -LiteralPath $temporaryIni -Value $iniLines -Encoding Unicode
        Copy-Item -LiteralPath $temporaryIni -Destination (Join-Path $caseDir $temporaryIniName)
        Remove-Item -LiteralPath $runtimeLog -Force -ErrorAction SilentlyContinue

        $arguments = @($case.Map, "ini=$temporaryIniName", 'userini=D3D12TestUser.ini', '-nosplash') + @($case.AdditionalArguments)
        Write-Host ("Running {0}: {1}" -f $case.Name, ($arguments -join ' '))
        $process = Start-Process -FilePath $unrealExe -ArgumentList $arguments -WorkingDirectory $systemDir -PassThru
        if ($MeasurePerformance) {
            $null = $process.WaitForInputIdle(5000)
            $shell = New-Object -ComObject WScript.Shell
            if (-not $shell.AppActivate($process.Id)) {
                throw "$($case.Name) could not activate the Unreal window for performance measurement."
            }
        }
        if ($process.WaitForExit($RunSeconds * 1000)) {
            throw "$($case.Name) exited before its $RunSeconds-second observation window."
        }
        $openXRLoaderLoaded = @($process.Modules | Where-Object { $_.ModuleName -ieq 'openxr_loader.dll' }).Count -gt 0

        $caseScreenshot = ''
        $comparison = $null
        $comparisonStatus = ''
        if ($ScreenshotMode -ne 'Off') {
            $caseScreenshot = Save-CaseScreenshot -Process $process -CaseDir $caseDir
            $baselinePath = Join-Path $screenshotBaselineRoot ("{0}.png" -f $case.Name)
            if ($ScreenshotMode -eq 'Update') {
                New-Item -ItemType Directory -Force -Path $screenshotBaselineRoot | Out-Null
                Copy-Item -LiteralPath $caseScreenshot -Destination $baselinePath -Force
                $comparisonStatus = 'Updated'
            } elseif ($ScreenshotMode -eq 'Compare' -and -not $case.CompareScreenshot) {
                $comparisonStatus = 'SkippedDynamic'
            } elseif ($ScreenshotMode -eq 'Compare') {
                $comparison = Compare-CaseScreenshot -ActualPath $caseScreenshot -BaselinePath $baselinePath
                if (-not $comparison.Passed) {
                    throw "$($case.Name) screenshot regression: mean channel delta $($comparison.MeanChannelDelta), changed sample ratio $($comparison.ChangedSampleRatio)."
                }
                $comparisonStatus = 'Passed'
            } else {
                $comparisonStatus = 'Captured'
            }
        }

        Request-UnrealExit $process
        if (-not $process.WaitForExit(15000)) {
            throw "$($case.Name) did not exit within 15 seconds after a clean shutdown request."
        }
        $process = $null
        if (-not (Test-Path -LiteralPath $runtimeLog -PathType Leaf)) {
            throw "$($case.Name) did not produce Unreal.log."
        }

        $caseLog = Join-Path $caseDir 'Unreal.log'
        Copy-Item -LiteralPath $runtimeLog -Destination $caseLog
        $logText = Get-Content -LiteralPath $caseLog -Raw
        $failureText = $logText -replace $knownEntryFallbackPattern, ''
        $expectedMap = "LoadMap: $($case.Map)"
        if (-not $logText.Contains($expectedMap)) {
            throw "$($case.Name) did not load $($case.Map)."
        }
        if (-not $logText.Contains('Bound to D3D12Drv.dll') -or -not $logText.Contains('Unbound to D3D12Drv.dll')) {
            throw "$($case.Name) did not complete a clean D3D12 bind/unbind cycle."
        }
        if ($case.CloneWindowsClient -and (-not $logText.Contains('Bound to XInputWinDrv.dll') -or -not $logText.Contains('Unbound to XInputWinDrv.dll'))) {
            throw "$($case.Name) did not complete a clean XInputWinDrv bind/unbind cycle."
        }
        if ($case.CloneWindowsClient -and $logText -notmatch 'XInputWinDrv loaded xinput(1_4|9_1_0)\.dll') {
            throw "$($case.Name) did not load a supported system XInput library."
        }
        if ($failureText -match $failurePattern) {
            throw "$($case.Name) contains a renderer failure signature."
        }
        if ($case.OpenXRExpectation -eq 'Disabled') {
            if ($openXRLoaderLoaded -or -not $logText.Contains('Unreal Revived OpenXR: disabled; loader not queried (flat-screen default)')) {
                throw "$($case.Name) did not preserve strict flat-screen OpenXR isolation."
            }
        }
        elseif ($case.OpenXRExpectation -eq 'DisabledOverride') {
            if ($openXRLoaderLoaded -or -not $logText.Contains('Unreal Revived OpenXR: disabled; loader not queried (command-line -novr)')) {
                throw "$($case.Name) did not honor the -novr command-line override."
            }
        }
        elseif ($case.OpenXRExpectation -eq 'Requested') {
            if ($logText -notmatch 'Unreal Revived OpenXR: requested by (command-line -vr|stored EnableVR); probing loader' -or
                -not $logText.Contains('continuing flat-screen D3D12')) {
                throw "$($case.Name) did not probe OpenXR and fall back safely to flat-screen D3D12."
            }
            if ($openXRLoaderLoaded -and
                $logText -notmatch 'Unreal Revived OpenXR: (runtime=|active runtime unavailable|active runtime does not support|instance creation failed)') {
                throw "$($case.Name) loaded OpenXR without reporting the runtime detection result."
            }
            if ($logText -match 'Unreal Revived OpenXR: headset detected=' -and
                $logText -notmatch 'Unreal Revived OpenXR: (D3D12 session (created|and monoscopic game presentation initialized)|runtime requires a different graphics adapter|runtime requires D3D feature level|D3D12 graphics requirements|xrCreateSession unavailable|D3D12 session creation failed)') {
                throw "$($case.Name) detected an HMD without reporting a D3D12 session outcome."
            }
            if ($logText -match 'Unreal Revived OpenXR: D3D12 session and monoscopic game presentation initialized' -and
                $logText -notmatch 'Unreal Revived OpenXR: stereo swapchains ready views=2') {
                throw "$($case.Name) initialized headset presentation without reporting two ready eye swapchains."
            }
            if ($logText -match 'Unreal Revived OpenXR: stereo session begun' -and
                $logText -notmatch 'Unreal Revived OpenXR: first monoscopic game frame submitted to both eyes') {
                throw "$($case.Name) began an OpenXR stereo session without submitting the game image."
            }
            if ($logText -match 'Unreal Revived OpenXR: stereo session begun' -and
                ($logText -notmatch 'Unreal Revived OpenXR: head orientation baseline captured' -or
                 $logText -notmatch 'Unreal Revived OpenXR: render-only head orientation applied; gameplay view rotation remains unchanged')) {
                throw "$($case.Name) began an OpenXR stereo session without applying isolated head orientation."
            }
        }
        if (($case.Settings.ContainsKey('AntialiasMode') -or $case.Name -match '^display-(2560x1440|3840x2160)') -and $logText -notmatch 'requested MSAA \d+x, effective MSAA \d+x') {
            throw "$($case.Name) did not log requested and effective MSAA."
        }
        if ($case.Settings.ContainsKey('MaxAnisotropy')) {
            $expectedAnisotropy = [Math]::Min([Math]::Max([int]$case.Settings.MaxAnisotropy, 0), 16)
            if ($logText -notmatch "requested anisotropy $($case.Settings.MaxAnisotropy), effective anisotropy $expectedAnisotropy") {
                throw "$($case.Name) did not apply the requested anisotropic-filtering level."
            }
        }

        $performanceMatch = $null
        if ($MeasurePerformance) {
            $performanceMatches = [regex]::Matches($logText, 'D3D12Drv performance: samples=(\d+) average_ms=([\d.]+) median_ms=([\d.]+) p95_ms=([\d.]+) p99_ms=([\d.]+) max_ms=([\d.]+) average_fps=([\d.]+)')
            if ($performanceMatches.Count -eq 0) {
                throw "$($case.Name) did not log D3D12 performance telemetry."
            }
            $performanceMatch = $performanceMatches[$performanceMatches.Count - 1]
        }

        $results += [pscustomobject]@{
            Case = $case.Name
            Map = $case.Map
            Settings = (($case.Settings.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';')
            ProfileSettings = (($case.ProfileSettings.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';')
            AdditionalArguments = ($case.AdditionalArguments -join ' ')
            OpenXRExpectation = $case.OpenXRExpectation
            OpenXRLoaderLoaded = $openXRLoaderLoaded
            Screenshot = if ($caseScreenshot) { Split-Path $caseScreenshot -Leaf } else { '' }
            ScreenshotComparison = $comparisonStatus
            MeanChannelDelta = if ($comparison) { $comparison.MeanChannelDelta } else { '' }
            ChangedSampleRatio = if ($comparison) { $comparison.ChangedSampleRatio } else { '' }
            PerformanceSamples = if ($performanceMatch) { [int]$performanceMatch.Groups[1].Value } else { '' }
            AverageFrameMs = if ($performanceMatch) { [double]$performanceMatch.Groups[2].Value } else { '' }
            MedianFrameMs = if ($performanceMatch) { [double]$performanceMatch.Groups[3].Value } else { '' }
            P95FrameMs = if ($performanceMatch) { [double]$performanceMatch.Groups[4].Value } else { '' }
            P99FrameMs = if ($performanceMatch) { [double]$performanceMatch.Groups[5].Value } else { '' }
            MaxFrameMs = if ($performanceMatch) { [double]$performanceMatch.Groups[6].Value } else { '' }
            AverageFps = if ($performanceMatch) { [double]$performanceMatch.Groups[7].Value } else { '' }
            Result = 'Passed'
        }
    }
} finally {
    if ($null -ne $previousPerformanceEnvironment) {
        $env:UNREAL_REVIVED_MEASURE_PERFORMANCE = $previousPerformanceEnvironment
    } else {
        Remove-Item Env:\UNREAL_REVIVED_MEASURE_PERFORMANCE -ErrorAction SilentlyContinue
    }
    if ($process -and -not $process.HasExited) {
        try { Request-UnrealExit $process } catch {}
        if (-not $process.WaitForExit(5000)) {
            Stop-Process -Id $process.Id -Force
        }
    }
    Remove-Item -LiteralPath $runningMarker -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $temporaryIni -Force -ErrorAction SilentlyContinue
}

$finalSourceHash = (Get-FileHash -LiteralPath $sourceIni -Algorithm SHA256).Hash
if ($finalSourceHash -ne $sourceHash) {
    throw 'D3D12Test.ini changed during automated testing.'
}
if ((Get-FileHash -LiteralPath $userIni -Algorithm SHA256).Hash -ne $userHash) {
    throw 'D3D12TestUser.ini changed during automated testing.'
}

$results | Export-Csv -LiteralPath (Join-Path $evidenceRoot 'results.csv') -NoTypeInformation
$results | Format-Table -AutoSize
Write-Host "Automated D3D12 checks passed. Evidence: $evidenceRoot"

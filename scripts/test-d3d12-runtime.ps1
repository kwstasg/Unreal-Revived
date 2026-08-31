param(
    [ValidateSet('Content', 'Settings', 'MenuDisplay', 'All')]
    [string]$Suite = 'Content',

    [string[]]$Maps,

    [ValidateRange(3, 120)]
    [int]$RunSeconds = 8
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$systemDir = Join-Path $repoRoot 'local/game/System64'
$unrealExe = Join-Path $systemDir 'Unreal.exe'
$sourceIni = Join-Path $systemDir 'D3D12Test.ini'
$userIni = Join-Path $systemDir 'D3D12TestUser.ini'
$temporaryIniName = 'D3D12Automation.ini'
$temporaryIni = Join-Path $systemDir $temporaryIniName
$runtimeLog = Join-Path $systemDir 'Unreal.log'
$evidenceRoot = Join-Path $repoRoot (Join-Path 'local/logs' ("automated-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))

foreach ($requiredPath in @($unrealExe, $sourceIni, $userIni)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required disposable-runtime file is missing: $requiredPath"
    }
}

if (Get-Process Unreal -ErrorAction SilentlyContinue) {
    throw 'Unreal is already running. Close it before starting automated checks.'
}

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
        [hashtable]$ProfileSettings = @{}
    )

    [pscustomobject]@{
        Name = $Name
        Map = $Map
        Settings = $Settings
        ProfileSettings = $ProfileSettings
    }
}

$contentCases = @(
    New-TestCase -Name 'content-nyleve' -Map 'NyLeve'
    New-TestCase -Name 'content-dmdeck16' -Map 'DmDeck16'
    New-TestCase -Name 'content-chizra' -Map 'Chizra'
    New-TestCase -Name 'content-vortex2' -Map 'Vortex2'
    New-TestCase -Name 'content-dug' -Map 'Dug'
    New-TestCase -Name 'content-terraniux' -Map 'Terraniux'
)

$settingsCases = @(
    New-TestCase -Name 'setting-msaa2' -Map 'NyLeve' -Settings @{ AntialiasMode = 'MSAA_2x' }
    New-TestCase -Name 'setting-msaa4' -Map 'NyLeve' -Settings @{ AntialiasMode = 'MSAA_4x' }
    New-TestCase -Name 'setting-no-precache' -Map 'DmDeck16' -Settings @{ UsePrecache = 'False' }
    New-TestCase -Name 'setting-vsync' -Map 'NyLeve' -Settings @{ UseVSync = 'True' }
    New-TestCase -Name 'setting-one-x-lighting' -Map 'DmDeck16' -Settings @{ LightMode = 'OneXBlending' }
    New-TestCase -Name 'setting-brighter-actors' -Map 'Dug' -Settings @{ LightMode = 'BrighterActors' }
    New-TestCase -Name 'setting-xopengl-gamma' -Map 'NyLeve' -Settings @{ GammaMode = 'XOpenGL'; GammaOffset = '0.3' }
    New-TestCase -Name 'setting-lod-negative' -Map 'DmDeck16' -Settings @{ LODBias = '-1.0' }
    New-TestCase -Name 'setting-lod-positive' -Map 'DmDeck16' -Settings @{ LODBias = '1.0' }
    New-TestCase -Name 'setting-bloom' -Map 'NyLeve' -Settings @{ Bloom = 'True'; BloomAmount = '255' }
    New-TestCase -Name 'setting-occluded-lines' -Map 'DmDeck16' -Settings @{ OccludeLines = 'True' }
)

$menuDisplayCases = @(
    New-TestCase -Name 'menu-fps-enabled' -Map 'Unreal.unr' -ProfileSettings @{ 'ModernMenu.ModernVideoClientWindow|bShowFPS' = 'True' }
    New-TestCase -Name 'menu-fps-disabled' -Map 'Unreal.unr' -ProfileSettings @{ 'ModernMenu.ModernVideoClientWindow|bShowFPS' = 'False' }
    New-TestCase -Name 'display-1280x720' -Map 'Unreal.unr' -ProfileSettings @{ 'WinDrv.WindowsClient|FullscreenViewportX' = '1280'; 'WinDrv.WindowsClient|FullscreenViewportY' = '720' }
    New-TestCase -Name 'display-1024x768' -Map 'Unreal.unr' -ProfileSettings @{ 'WinDrv.WindowsClient|FullscreenViewportX' = '1024'; 'WinDrv.WindowsClient|FullscreenViewportY' = '768' }
    New-TestCase -Name 'display-windowed-1600x1024' -Map 'Unreal.unr' -ProfileSettings @{ 'WinDrv.WindowsClient|StartupFullscreen' = 'False'; 'WinDrv.WindowsClient|WindowedViewportX' = '1600'; 'WinDrv.WindowsClient|WindowedViewportY' = '1024' }
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
} else {
    $cases = @($contentCases) + @($settingsCases) + @($menuDisplayCases)
}

$rendererSection = 'D3D12Drv.D3D12RenderDevice'
$failurePattern = 'Critical Error|Assertion|ResizeTarget failed|ResizeViewport failed|Could not resize scene buffers|Could not flush d3d12 renderer|Bound to XOpenGLDrv'
$sourceHash = (Get-FileHash -LiteralPath $sourceIni -Algorithm SHA256).Hash
$results = @()
New-Item -ItemType Directory -Force -Path $evidenceRoot | Out-Null

try {
    foreach ($case in $cases) {
        $caseDir = Join-Path $evidenceRoot $case.Name
        New-Item -ItemType Directory -Force -Path $caseDir | Out-Null

        $iniLines = Get-Content -LiteralPath $sourceIni
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

        $arguments = @($case.Map, "ini=$temporaryIniName", 'userini=D3D12TestUser.ini', '-nosplash')
        Write-Host ("Running {0}: {1}" -f $case.Name, ($arguments -join ' '))
        $process = Start-Process -FilePath $unrealExe -ArgumentList $arguments -WorkingDirectory $systemDir -PassThru
        if ($process.WaitForExit($RunSeconds * 1000)) {
            throw "$($case.Name) exited before its $RunSeconds-second observation window."
        }

        if (-not $process.CloseMainWindow()) {
            throw "$($case.Name) did not expose a window that could be closed normally."
        }
        if (-not $process.WaitForExit(15000)) {
            throw "$($case.Name) did not exit within 15 seconds after a normal close request."
        }
        if (-not (Test-Path -LiteralPath $runtimeLog -PathType Leaf)) {
            throw "$($case.Name) did not produce Unreal.log."
        }

        $caseLog = Join-Path $caseDir 'Unreal.log'
        Copy-Item -LiteralPath $runtimeLog -Destination $caseLog
        $logText = Get-Content -LiteralPath $caseLog -Raw
        $expectedMap = "LoadMap: $($case.Map)"
        if (-not $logText.Contains($expectedMap)) {
            throw "$($case.Name) did not load $($case.Map)."
        }
        if (-not $logText.Contains('Bound to D3D12Drv.dll') -or -not $logText.Contains('Unbound to D3D12Drv.dll')) {
            throw "$($case.Name) did not complete a clean D3D12 bind/unbind cycle."
        }
        if ($logText -match $failurePattern) {
            throw "$($case.Name) contains a renderer failure signature."
        }

        $results += [pscustomobject]@{
            Case = $case.Name
            Map = $case.Map
            Settings = (($case.Settings.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';')
            ProfileSettings = (($case.ProfileSettings.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';')
            Result = 'Passed'
        }
    }
} finally {
    Remove-Item -LiteralPath $temporaryIni -Force -ErrorAction SilentlyContinue
}

$finalSourceHash = (Get-FileHash -LiteralPath $sourceIni -Algorithm SHA256).Hash
if ($finalSourceHash -ne $sourceHash) {
    throw 'D3D12Test.ini changed during automated testing.'
}

$results | Export-Csv -LiteralPath (Join-Path $evidenceRoot 'results.csv') -NoTypeInformation
$results | Format-Table -AutoSize
Write-Host "Automated D3D12 checks passed. Evidence: $evidenceRoot"
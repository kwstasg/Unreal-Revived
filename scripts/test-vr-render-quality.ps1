# Requires a connected OpenXR headset/runtime; never writes the player's INIs.
param([int[]] $Qualities = @(0, 1, 2, 3, 4, 5))
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot (Join-Path $repoRoot 'local/game')
if (Get-Process -Name Unreal -ErrorAction SilentlyContinue) { throw 'Close the game before testing VR quality.' }
$systemDir = Join-Path $gameRoot 'System64'
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($quality in $Qualities) {
    if ($quality -lt 0 -or $quality -gt 5) { throw 'Quality must be 0 through 5.' }
    $iniName = "VRQuality-$stamp-$quality.ini"
    $userName = "VRQualityUser-$stamp-$quality.ini"
    $logName = "VRQuality-$stamp-$quality.log"
    $lines = Get-Content -LiteralPath (Join-Path $systemDir 'D3D12Test.ini')
    $lines = Set-UnrealRevivedIniValue $lines 'D3D12Drv.D3D12RenderDevice' 'VRRenderQuality' ([string] $quality)
    $lines = Set-UnrealRevivedIniValue $lines 'Core.System' 'NoLogBuffering' 'True'
    Set-Content -LiteralPath (Join-Path $systemDir $iniName) -Value $lines -Encoding ASCII
    Copy-Item -LiteralPath (Join-Path $systemDir 'D3D12TestUser.ini') -Destination (Join-Path $systemDir $userName)
    $testProcess = $null
    try {
        $testProcess = Start-Process -FilePath (Join-Path $systemDir 'Unreal.exe') -WindowStyle Hidden -PassThru `
            -WorkingDirectory $systemDir -ArgumentList @('NyLeve?Game=ModernMenu.ModernVRQualityTestGame',
                "ini=$iniName", "userini=$userName", "log=$logName", '-vr', '-nosplash')
        if (!$testProcess.WaitForExit(30000)) { throw "VR quality $quality timed out: $logName" }
        $log = Get-Content -LiteralPath (Join-Path $systemDir $logName) -Raw
        if ($testProcess.ExitCode -ne 0 -or $log -notmatch 'VRQUALITYTEST completed' -or
            $log -match 'ScriptWarning|Critical Error|Assertion failed|VRQUALITYTEST FAIL|VRQUALITYTEST status=fallback') {
            throw "VR quality $quality failed: $logName"
        }
        $eyes = [regex]::Matches($log, 'eye=(\d) quality=(\d) output=(\d+)x(\d+) recommended=(\d+)x(\d+) max=(\d+)x(\d+)')
        if ($eyes.Count -ne 2) { throw "Two OpenXR views not initialized; headset/runtime required: $logName" }
        foreach ($eye in $eyes) {
            $g = $eye.Groups
            if ([int] $g[2].Value -ne $quality) { throw "Unexpected fallback in $logName" }
            $scale = @(1.0, 0.75, 1.0, 1.25, 1.5, 2.0)[$quality]
            if ($quality -ne 0) {
                $scale = [Math]::Min($scale, [Math]::Min([int] $g[7].Value, 16384) / [double] $g[5].Value)
                $scale = [Math]::Min($scale, [Math]::Min([int] $g[8].Value, 16384) / [double] $g[6].Value)
            }
            $width = [Math]::Max(1, [Math]::Floor([int] $g[5].Value * $scale))
            $height = [Math]::Max(1, [Math]::Floor([int] $g[6].Value * $scale))
            if ([int] $g[3].Value -ne $width -or [int] $g[4].Value -ne $height) {
                throw "Unexpected eye output dimensions in $logName"
            }
        }
        $rendered = $log -match 'first independent stereo game frame submitted'
        Write-Output "Quality ${quality}: output sizes verified; stereo frame rendered=$rendered; $logName"
    }
    finally {
        if ($testProcess -and !$testProcess.HasExited) { Stop-Process -Id $testProcess.Id -Force }
        Remove-Item -LiteralPath (Join-Path $systemDir $iniName), (Join-Path $systemDir $userName) -Force
    }
}

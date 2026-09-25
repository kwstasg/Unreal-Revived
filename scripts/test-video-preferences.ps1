$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot (Join-Path $repoRoot 'local/game')
if (Get-Process -Name Unreal -ErrorAction SilentlyContinue) { throw 'Close the game before testing video preferences.' }
$systemDir = Join-Path $gameRoot 'System64'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$iniName = "VideoPreferences-$stamp.ini"
$userName = "VideoPreferencesUser-$stamp.ini"
$logName = "VideoPreferences-$stamp.log"
$logPath = Join-Path $systemDir $logName
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force
$lines = Get-Content -LiteralPath (Join-Path $systemDir 'D3D12Test.ini')
# Exercise the absent-key default without overwriting the user's chosen preset.
$lines = Set-UnrealRevivedIniValue $lines 'D3D12Drv.D3D12RenderDevice' 'VRRenderQuality' '0'
$lines = Remove-UnrealRevivedIniValue $lines 'D3D12Drv.D3D12RenderDevice' 'VRRenderQuality' '0'
$lines = Set-UnrealRevivedIniValue $lines 'D3D12Drv.D3D12RenderDevice' 'VRTurnMode' '0'
$lines = Remove-UnrealRevivedIniValue $lines 'D3D12Drv.D3D12RenderDevice' 'VRTurnMode' '0'
$lines = Set-UnrealRevivedIniValue $lines 'D3D12Drv.D3D12RenderDevice' 'VRSnapAngle' '30'
$lines = Remove-UnrealRevivedIniValue $lines 'D3D12Drv.D3D12RenderDevice' 'VRSnapAngle' '30'
$lines = Set-UnrealRevivedIniValue $lines 'Core.System' 'NoLogBuffering' 'True'
$lines = Set-UnrealRevivedIniValue $lines 'WinDrv.WindowsClient' 'Brightness' '0.600000'
$lines = Set-UnrealRevivedIniValue $lines 'XInputWinDrv.WindowsClient' 'Brightness' '0.600000'
Set-Content -LiteralPath (Join-Path $systemDir $iniName) -Value $lines -Encoding ASCII
Copy-Item -LiteralPath (Join-Path $systemDir 'D3D12TestUser.ini') -Destination (Join-Path $systemDir $userName)
$testProcess = $null
try {
    $testProcess = Start-Process -FilePath (Join-Path $systemDir 'Unreal.exe') -WindowStyle Hidden -PassThru `
        -WorkingDirectory $systemDir -ArgumentList @('NyLeve?Game=ModernMenu.ModernVideoTestGame',
            "ini=$iniName", "userini=$userName", "log=$logName", '-novr', '-nosplash')
    if (!$testProcess.WaitForExit(30000)) { throw "Video preferences timed out: $logPath" }
    $log = Get-Content -LiteralPath $logPath -Raw
    if ($testProcess.ExitCode -ne 0 -or $log -notmatch 'VIDEOTEST completed' -or
        $log -match 'ScriptWarning|Critical Error|Assertion failed|invalid outer|broken pointer|VIDEOTEST FAIL') {
        throw "Video preferences failed: $logPath"
    }
    Write-Output "Video preferences and shutdown passed: $logPath"
}
finally {
    if ($testProcess -and !$testProcess.HasExited) { Stop-Process -Id $testProcess.Id -Force }
    Remove-Item -LiteralPath (Join-Path $systemDir $iniName), (Join-Path $systemDir $userName) -Force
}

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot (Join-Path $repoRoot 'local/game')
if (Get-Process -Name Unreal -ErrorAction SilentlyContinue) { throw 'Close the game before testing map travel.' }
$systemDir = Join-Path $gameRoot 'System64'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$iniName = "VRTravel-$stamp.ini"
$userName = "VRTravelUser-$stamp.ini"
$logName = "VRTravel-$stamp.log"
$logPath = Join-Path $systemDir $logName
$saveDirectory = Join-Path $repoRoot "local/tests/vr-travel-$stamp"
New-Item -ItemType Directory -Path $saveDirectory -ErrorAction Stop | Out-Null
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force
$lines = Get-Content -LiteralPath (Join-Path $systemDir 'D3D12Test.ini')
$lines = Set-UnrealRevivedIniValue $lines 'Core.System' 'NoLogBuffering' 'True'
$lines = Set-UnrealRevivedIniValue $lines 'Core.System' 'SavePath' $saveDirectory
Set-Content -LiteralPath (Join-Path $systemDir $iniName) -Value $lines -Encoding ASCII
Copy-Item -LiteralPath (Join-Path $systemDir 'D3D12TestUser.ini') -Destination (Join-Path $systemDir $userName)
$testProcess = $null
try {
    $testProcess = Start-Process -FilePath (Join-Path $systemDir 'Unreal.exe') -WindowStyle Hidden -PassThru `
        -WorkingDirectory $systemDir -ArgumentList @('NyLeve?Game=ModernMenu.ModernVRTravelTestGame',
            "ini=$iniName", "userini=$userName", "log=$logName", '-novr', '-nosplash')
    if (!$testProcess.WaitForExit(30000)) { throw "VR map travel timed out: $logPath" }
    $log = Get-Content -LiteralPath $logPath -Raw
    if ($testProcess.ExitCode -ne 0 -or $log -notmatch 'VRTRAVEL repeated map changes and hook rebinding completed' -or
        $log -notmatch 'VRTRAVEL save load and production hook rebinding completed' -or
        $log -notmatch 'VRTRAVEL all 14 gaze weapon profiles stable after motion/save/load' -or
        $log -match 'ScriptWarning|Critical Error|Assertion failed|invalid outer|broken pointer|VRTRAVEL FAIL') {
        throw "VR map travel failed: $logPath"
    }
    Write-Output "VR map travel, save/load and shutdown passed: $logPath"
}
finally {
    if ($testProcess -and !$testProcess.HasExited) { Stop-Process -Id $testProcess.Id -Force }
    Remove-Item -LiteralPath (Join-Path $systemDir $iniName), (Join-Path $systemDir $userName) -Force
    Remove-Item -LiteralPath $saveDirectory -Recurse -Force
}

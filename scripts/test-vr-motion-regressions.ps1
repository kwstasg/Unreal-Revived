# Run the controller weapon regression map without a headset or user-profile writes.
param([string] $GameRoot = '', [switch] $ListenServer)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
if (!$GameRoot) { $GameRoot = Join-Path $repoRoot 'local/game' }
$GameRoot = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot $GameRoot
if (Get-Process -Name Unreal -ErrorAction SilentlyContinue) {
    throw 'Close the running game before the regression test.'
}
$systemDir = Join-Path $GameRoot 'System64'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$testIni = "VRMotionRegression-$stamp.ini"
$testUserIni = "VRMotionRegressionUser-$stamp.ini"
$testLog = "VRMotionRegression-$stamp.log"
Copy-Item -LiteralPath (Join-Path $systemDir 'D3D12Test.ini') -Destination (Join-Path $systemDir $testIni)
Copy-Item -LiteralPath (Join-Path $systemDir 'D3D12TestUser.ini') -Destination (Join-Path $systemDir $testUserIni)
Add-Content -LiteralPath (Join-Path $systemDir $testUserIni) -Encoding ASCII -Value @'

[ModernMenu.ModernVRWeaponTuningTestConfig]
Profiles=(WeaponClass="UnrealShare.AutoMag",Scale=1.2,GazeOffsetCM=(X=2,Y=4,Z=-6),MotionOffsetCM=(X=4,Y=-2,Z=6))
Profiles=(WeaponClass="OldWeapons.OldAutoMag",Scale=0.8,GazeOffsetCM=(X=0,Y=0,Z=0),MotionOffsetCM=(X=0,Y=0,Z=0))
'@
$testProcess = $null
$mapUrl = 'NyLeve?Game=ModernMenu.ModernVRMotionTestGame'
if ($ListenServer) { $mapUrl += '?Listen' }
try {
    $testProcess = Start-Process -FilePath (Join-Path $systemDir 'Unreal.exe') -WindowStyle Hidden -PassThru `
        -WorkingDirectory $systemDir -ArgumentList @($mapUrl,
            "ini=$testIni", "userini=$testUserIni", "log=$testLog", '-novr', '-nosplash', '-multihome=127.0.0.1', '-port=17777')
    if (!$testProcess.WaitForExit(30000)) { throw 'VR motion regression game did not exit within 30 seconds.' }
    $log = Get-Content -LiteralPath (Join-Path $systemDir $testLog) -Raw
    if ($testProcess.ExitCode -ne 0 -or $log -notmatch 'VRMOTION regression failures: 0' -or
        ($ListenServer -and $log -notmatch 'VRMOTION listen server True') -or
        $log -match 'VRMOTION False|Critical Error|Assertion failed|ScriptWarning') {
        throw "VR motion regressions failed; inspect $systemDir\$testLog"
    }
    Write-Output "VR motion game regressions passed: $systemDir\$testLog"
}
finally {
    if ($testProcess -and !$testProcess.HasExited) { Stop-Process -Id $testProcess.Id -Force }
    Remove-Item -LiteralPath (Join-Path $systemDir $testIni), (Join-Path $systemDir $testUserIni) -Force
}

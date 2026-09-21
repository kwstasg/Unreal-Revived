# Exercise disk edits and removal in a running game, restoring the original bytes.
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot (Join-Path $repoRoot 'local/game')
if (Get-Process -Name Unreal -ErrorAction SilentlyContinue) { throw 'Close the game before testing reload.' }
$systemDir = Join-Path $gameRoot 'System64'
$tuningPath = Join-Path $systemDir 'ModernVRWeapons.ini'
$originalBytes = [IO.File]::ReadAllBytes($tuningPath)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$iniName = "VRReload-$stamp.ini"
$userName = "VRReloadUser-$stamp.ini"
$logName = "VRReload-$stamp.log"
$logPath = Join-Path $systemDir $logName
Copy-Item -LiteralPath (Join-Path $systemDir 'D3D12Test.ini') -Destination (Join-Path $systemDir $iniName)
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force
$testLines = Get-Content -LiteralPath (Join-Path $systemDir $iniName)
$testLines = Set-UnrealRevivedIniValue $testLines 'Core.System' 'NoLogBuffering' 'True'
Set-Content -LiteralPath (Join-Path $systemDir $iniName) -Value $testLines -Encoding ASCII
Copy-Item -LiteralPath (Join-Path $systemDir 'D3D12TestUser.ini') -Destination (Join-Path $systemDir $userName)
$testProcess = $null
$stage = 0
try {
    $testProcess = Start-Process -FilePath (Join-Path $systemDir 'Unreal.exe') -WindowStyle Hidden -PassThru `
        -WorkingDirectory $systemDir -ArgumentList @('NyLeve?Game=ModernMenu.ModernVRWeaponReloadTestGame',
            "ini=$iniName", "userini=$userName", "log=$logName", '-novr', '-nosplash', '-forcelogflush')
    $deadline = (Get-Date).AddSeconds(30)
    while (!$testProcess.HasExited -and (Get-Date) -lt $deadline) {
        $log = if (Test-Path -LiteralPath $logPath) { Get-Content -LiteralPath $logPath -Raw } else { '' }
        if ($stage -eq 0 -and $log -match 'VRRELOAD ready for edit') {
            Add-Content -LiteralPath $tuningPath -Encoding ASCII -Value @'

[ModernMenu.ModernVRWeaponTuning]
Profiles=(WeaponClass="ModernMenu.ModernVRMotionTestWeapon",Scale=1.37,MotionOffsetCM=(X=2,Y=-4,Z=6))
'@
            $stage = 1
            Write-Output 'Live test wrote the edited profile.'
        }
        if ($stage -eq 1 -and $log -match 'VRRELOAD edited values applied') {
            [IO.File]::WriteAllBytes($tuningPath, $originalBytes)
            $stage = 2
            Write-Output 'Live test restored the original INI.'
        }
        Start-Sleep -Milliseconds 200
    }
    if (!$testProcess.HasExited) { throw 'Live reload test timed out.' }
    $log = Get-Content -LiteralPath $logPath -Raw
    if ($stage -ne 2 -or $testProcess.ExitCode -ne 0 -or $log -notmatch 'VRRELOAD removed profile reverted to neutral' -or
        $log -notmatch 'VRMOTION regression failures: 0' -or $log -match 'ScriptWarning|Critical Error|VRMOTION False') {
        throw "Live reload failed; inspect $logPath"
    }
    Write-Output "Live weapon INI reload and profile removal passed: $logPath"
}
finally {
    if ($testProcess -and !$testProcess.HasExited) { Stop-Process -Id $testProcess.Id -Force }
    [IO.File]::WriteAllBytes($tuningPath, $originalBytes)
    Remove-Item -LiteralPath (Join-Path $systemDir $iniName), (Join-Path $systemDir $userName) -Force
}

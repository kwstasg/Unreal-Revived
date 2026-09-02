param(
    [Parameter(Mandatory = $true)]
    [string] $GameRoot
)

$ErrorActionPreference = 'Stop'

$runtimeRoot = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot $GameRoot
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$system64 = Join-Path $runtimeRoot 'System64'
$unrealExe = Join-Path $system64 'Unreal.exe'
$brandingIcon = Join-Path $repositoryRoot 'branding\UnrealRevived.ico'
$brandingIconHash = (Get-FileHash -LiteralPath $brandingIcon -Algorithm SHA256).Hash.ToLowerInvariant()
$brandingDirectory = Join-Path $runtimeRoot 'UnrealRevived'
$installedIcon = Join-Path $brandingDirectory "UnrealRevived-Icon-$($brandingIconHash.Substring(0, 12)).ico"
$recoveryScript = Join-Path $PSScriptRoot 'launch-development-recovery.ps1'
$powershellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
$shell = New-Object -ComObject WScript.Shell

New-Item -ItemType Directory -Path $brandingDirectory -Force | Out-Null
Copy-Item -LiteralPath $brandingIcon -Destination $installedIcon -Force

$normalPath = Join-Path $runtimeRoot 'Unreal Revived.lnk'
$normal = $shell.CreateShortcut($normalPath)
$normal.TargetPath = $unrealExe
$normal.Arguments = 'Unreal.unr?Game=ModernMenu.ModernIntro ini=D3D12Test.ini userini=D3D12TestUser.ini'
$normal.WorkingDirectory = $system64
$normal.IconLocation = "$installedIcon,0"
$normal.Description = 'Launch Unreal Revived with the Direct3D 12 renderer'
$normal.Save()

$recoveryPath = Join-Path $runtimeRoot 'Unreal Revived Recovery.lnk'
$recovery = $shell.CreateShortcut($recoveryPath)
$recovery.TargetPath = $powershellExe
$recovery.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -GameRoot "{1}"' -f `
    $recoveryScript, $runtimeRoot
$recovery.WorkingDirectory = $system64
$recovery.IconLocation = "$installedIcon,0"
$recovery.Description = 'Launch Unreal Revived recovery mode'
$recovery.Save()

Write-Host "Development shortcuts created in $runtimeRoot"
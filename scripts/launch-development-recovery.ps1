param(
    [Parameter(Mandatory = $true)]
    [string] $GameRoot
)

$ErrorActionPreference = 'Stop'

$runtimeRoot = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot $GameRoot
$system64 = Join-Path $runtimeRoot 'System64'
$unrealExe = Join-Path $system64 'Unreal.exe'
$runningMarker = Join-Path $system64 'Running.ini'

$activeGame = Get-Process Unreal -ErrorAction SilentlyContinue |
    Where-Object { [string]::Equals($_.Path, $unrealExe, [StringComparison]::OrdinalIgnoreCase) } |
    Select-Object -First 1

if ($activeGame) {
    $shell = New-Object -ComObject WScript.Shell
    $shell.Popup('Close Unreal before launching recovery mode.', 0, 'Unreal Revived Recovery', 48) | Out-Null
    exit 1
}

New-Item -Path $runningMarker -ItemType File -Force | Out-Null
Start-Process -FilePath $unrealExe -WorkingDirectory $system64 -ArgumentList @(
    'Unreal.unr',
    'ini=D3D12Test.ini',
    'userini=D3D12TestUser.ini'
)
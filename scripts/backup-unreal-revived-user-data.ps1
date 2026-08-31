param(
    [Parameter(Mandatory = $true)]
    [string] $InstallRoot
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath (Join-Path $InstallRoot '.unreal-revived.json') -PathType Leaf)) {
    return
}

$backupRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) ('Unreal Revived Backup ' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$items = @(
    @{ Source = 'Save'; Destination = 'Save' },
    @{ Source = 'System64\UnrealRevived.ini'; Destination = 'System64\UnrealRevived.ini' },
    @{ Source = 'System64\UnrealRevivedUser.ini'; Destination = 'System64\UnrealRevivedUser.ini' }
)

foreach ($item in $items) {
    $source = Join-Path $InstallRoot $item.Source
    if (-not (Test-Path -LiteralPath $source)) {
        continue
    }
    $destination = Join-Path $backupRoot $item.Destination
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
}

if (Test-Path -LiteralPath $backupRoot) {
    Write-Host "Saved user data to $backupRoot"
}
# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [Parameter(Mandatory = $true)][string] $RuntimeRoot,
    [Parameter(Mandatory = $true)][string] $BinaryRoot,
    [string] $SdkRoot
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $SdkRoot) { $SdkRoot = Join-Path $repo 'local/sdk/227k_15' }
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Integrity.psm1') -Force
$hostManifest = Get-Content -LiteralPath (Join-Path $repo 'manifests/hosts/unreal-gold-227k_15-win64.json') -Raw | ConvertFrom-Json
Assert-UnrealRevivedHostModules -HostRoot $RuntimeRoot -HostManifest $hostManifest
$system = Join-Path $RuntimeRoot 'System64'
$english = Join-Path $RuntimeRoot 'SystemLocalized/int/Unreal.int'
if (-not (Test-Path -LiteralPath $english -PathType Leaf)) {
    throw "Missing base launcher localization: $english"
}
foreach ($name in @('UnrealRevived', 'UnrealRevivedVR')) {
    if (-not (Test-Path -LiteralPath (Join-Path $BinaryRoot "$name.exe") -PathType Leaf)) {
        throw "Missing branded executable: $name.exe"
    }
}
$records = [ordered]@{}
foreach ($name in @('UnrealRevived', 'UnrealRevivedVR')) {
    $binary = Join-Path $BinaryRoot "$name.exe"
    if (-not (Test-Path -LiteralPath $binary -PathType Leaf)) { throw "Missing branded executable: $binary" }
    Copy-Item -LiteralPath $binary -Destination (Join-Path $system "$name.exe") -Force
    $records["$name.exe"] = (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash
    $title = if ($name -eq 'UnrealRevivedVR') { 'Unreal Revived VR' } else { 'Unreal Revived' }
    foreach ($language in Get-ChildItem -LiteralPath (Join-Path $RuntimeRoot 'SystemLocalized') -Directory) {
        $base = Join-Path $language.FullName "Unreal.$($language.Name)"
        # Keep translated state labels where available; otherwise use English.
        if (-not (Test-Path -LiteralPath $base -PathType Leaf)) { $base = $english }
        $lines = (Get-Content -LiteralPath $base) -replace '\bUnreal\b', $title
        Set-Content -LiteralPath (Join-Path $language.FullName "$name.$($language.Name)") -Value $lines -Encoding UTF8
        if ($language.Name -eq 'int') {
            Set-Content -LiteralPath (Join-Path $system "$name.int") -Value $lines -Encoding UTF8
        }
    }
}
$notices = Join-Path $RuntimeRoot 'UnrealRevived'
New-Item -ItemType Directory -Path $notices -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $sdkRoot 'SDKLICENSE.md') -Destination (Join-Path $notices 'BrandedLaunchers-SDKLICENSE.md') -Force
[ordered]@{
    schema = 1
    status = 'Native desktop and VR launch executables'
    sdkHost = 'unreal-gold-227k_15-win64'
    sdkLaunchSourceSha256 = (Get-FileHash -LiteralPath (Join-Path $sdkRoot 'Launch/Src/Launch.cpp')).Hash
    modules = $records
} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $notices 'branded-launchers.json') -Encoding UTF8

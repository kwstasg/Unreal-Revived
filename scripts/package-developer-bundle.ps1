param(
    [string] $RuntimeArchive,

    [string] $SdkArchive,

    [string] $OutputRoot
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$hostManifestPath = Join-Path $repositoryRoot 'manifests\hosts\unreal-gold-227k_15-win64.json'
$permissionsPath = Join-Path $repositoryRoot 'PERMISSIONS.md'
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Integrity.psm1') -Force

if (-not $RuntimeArchive) {
    $RuntimeArchive = Join-Path $repositoryRoot 'local\downloads\OldUnreal-UnrealPatch227k-Windows.zip'
}
if (-not $SdkArchive) {
    $SdkArchive = Join-Path $repositoryRoot 'local\downloads\OldUnreal-UnrealPatch227k-SDK-Windows.zip'
}
if (-not $OutputRoot) {
    $OutputRoot = Join-Path $repositoryRoot 'local\package\developer-bundle'
}

foreach ($requiredPath in @($hostManifestPath, $permissionsPath, $RuntimeArchive, $SdkArchive)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Missing developer bundle input: $requiredPath"
    }
}

$hostManifest = Get-Content -LiteralPath $hostManifestPath -Raw | ConvertFrom-Json
$runtimeHash = Assert-UnrealRevivedFileIntegrity -Path $RuntimeArchive `
    -ExpectedSize $hostManifest.release.runtime.size `
    -ExpectedSha256 $hostManifest.release.runtime.sha256 `
    -Description 'Pinned runtime archive'
$sdkHash = Assert-UnrealRevivedFileIntegrity -Path $SdkArchive `
    -ExpectedSize $hostManifest.release.sdk.size `
    -ExpectedSha256 $hostManifest.release.sdk.sha256 `
    -Description 'Pinned SDK archive'

$outputPath = [IO.Path]::GetFullPath($OutputRoot)
$stageRoot = Join-Path $outputPath 'stage'
$bundleName = 'UnrealRevived-DeveloperBundle-227k_15-v1.zip'
$bundlePath = Join-Path $outputPath $bundleName

if (Test-Path -LiteralPath $stageRoot) {
    Remove-Item -LiteralPath $stageRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $stageRoot, $outputPath -Force | Out-Null

$hostRoot = Join-Path $stageRoot 'host'
$sdkRoot = Join-Path $stageRoot 'sdk'
$recordsRoot = Join-Path $stageRoot 'records'
New-Item -ItemType Directory -Path $hostRoot, $sdkRoot, $recordsRoot -Force | Out-Null

Write-Host 'Extracting verified developer bundle inputs'
& tar.exe -xf ([IO.Path]::GetFullPath($RuntimeArchive)) -C $hostRoot
if ($LASTEXITCODE -ne 0) {
    throw "Could not extract the pinned runtime archive (tar exit code $LASTEXITCODE)."
}
& tar.exe -xf ([IO.Path]::GetFullPath($SdkArchive)) -C $sdkRoot
if ($LASTEXITCODE -ne 0) {
    throw "Could not extract the pinned SDK archive (tar exit code $LASTEXITCODE)."
}
Assert-UnrealRevivedHostModules -HostRoot $hostRoot -HostManifest $hostManifest

foreach ($sdkPath in @('Core\Inc\Core.h', 'Engine\Inc\Engine.h', 'Render\Inc\Render.h', 'Core\Lib\x64\Core.lib', 'Engine\Lib\x64\Engine.lib', 'Render\Lib\x64\Render.lib')) {
    if (-not (Test-Path -LiteralPath (Join-Path $sdkRoot $sdkPath) -PathType Leaf)) {
        throw "Extracted SDK file is missing: $sdkPath"
    }
}

$forbiddenFiles = @(Get-ChildItem -LiteralPath $stageRoot -File -Recurse | Where-Object {
    $_.Name -match '\.(log|dmp|usa)$' -or $_.DirectoryName -match '[\\/](Save|Saved|Screenshots|logs)([\\/]|$)'
})
if ($forbiddenFiles.Count -gt 0) {
    throw "Developer bundle contains forbidden generated or user data: $($forbiddenFiles[0].FullName)"
}

Copy-Item -LiteralPath $hostManifestPath -Destination (Join-Path $recordsRoot 'unreal-gold-227k_15-win64.json')
Copy-Item -LiteralPath $permissionsPath -Destination (Join-Path $recordsRoot 'PERMISSIONS.md')

$gitRevision = (& git -C $repositoryRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Could not determine the source Git revision.'
}

$bundleIdentity = [ordered]@{
    schema = 1
    id = 'unreal-revived-developer-bundle-227k_15-v1'
    product = 'Unreal Revived'
    sourceRevision = $gitRevision
    host = $hostManifest.id
    inputs = [ordered]@{
        runtime = [ordered]@{ size = $hostManifest.release.runtime.size; sha256 = $runtimeHash }
        sdk = [ordered]@{ size = $hostManifest.release.sdk.size; sha256 = $sdkHash }
    }
    contents = [ordered]@{
        hostFiles = @(Get-ChildItem -LiteralPath $hostRoot -File -Recurse).Count
        sdkFiles = @(Get-ChildItem -LiteralPath $sdkRoot -File -Recurse).Count
    }
}
$bundleIdentity | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $stageRoot 'bundle-manifest.json') -Encoding UTF8

if (Test-Path -LiteralPath $bundlePath) {
    Remove-Item -LiteralPath $bundlePath -Force
}
Push-Location $stageRoot
try {
    & tar.exe -a -cf $bundlePath '*'
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create the developer bundle (tar exit code $LASTEXITCODE)."
    }
}
finally {
    Pop-Location
}

$bundleFile = Get-Item -LiteralPath $bundlePath
$bundleHash = (Get-FileHash -LiteralPath $bundlePath -Algorithm SHA256).Hash
Set-Content -LiteralPath "$bundlePath.sha256" -Value "$bundleHash  $bundleName" -Encoding ASCII

$releaseManifest = [ordered]@{
    schema = 1
    id = 'unreal-revived-developer-bundle-227k_15-v1'
    host = $hostManifest.id
    release = [ordered]@{
        asset = $bundleName
        url = $null
        size = $bundleFile.Length
        sha256 = $bundleHash
    }
}
$releaseManifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $outputPath 'developer-bundle-manifest.json') -Encoding UTF8

Write-Host "Developer bundle created: $bundlePath"
Write-Host "Developer bundle size: $($bundleFile.Length) bytes"
Write-Host "Developer bundle SHA-256: $bundleHash"
# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [string] $SourceRuntime,

    [string] $InventoryPath,

    [string] $DestinationRoot,

    [string] $QuarantineRoot
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
if (-not $SourceRuntime) {
    $SourceRuntime = Join-Path $repositoryRoot 'local\game'
}
if (-not $InventoryPath) {
    $InventoryPath = Join-Path $repositoryRoot 'local\logs\content-audit\validation-current\inventory.json'
}
if (-not $DestinationRoot) {
    $DestinationRoot = Join-Path $repositoryRoot 'local\game-content-audit'
}
if (-not $QuarantineRoot) {
    $QuarantineRoot = Join-Path $repositoryRoot 'local\content-audit-quarantine'
}

$sourcePath = [IO.Path]::GetFullPath($SourceRuntime).TrimEnd('\')
$inventoryFile = [IO.Path]::GetFullPath($InventoryPath)
$destinationPath = [IO.Path]::GetFullPath($DestinationRoot).TrimEnd('\')
$quarantinePath = [IO.Path]::GetFullPath($QuarantineRoot).TrimEnd('\')

if ($sourcePath -eq $destinationPath -or $destinationPath.StartsWith("$sourcePath\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The audit runtime must not be the source runtime or a directory inside it.'
}
if ($quarantinePath -eq $sourcePath -or $quarantinePath.StartsWith("$sourcePath\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The quarantine must not be the source runtime or a directory inside it.'
}
if ($destinationPath -eq $quarantinePath -or $destinationPath.StartsWith("$quarantinePath\", [StringComparison]::OrdinalIgnoreCase) -or $quarantinePath.StartsWith("$destinationPath\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The audit runtime and quarantine must be separate sibling trees.'
}

$sourceMarker = Join-Path $sourcePath '.unreal-revived-development.json'
foreach ($requiredFile in @($sourceMarker, (Join-Path $sourcePath 'System64\Unreal.exe'), $inventoryFile)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Missing content-audit input: $requiredFile"
    }
}
foreach ($newRoot in @($destinationPath, $quarantinePath)) {
    if (Test-Path -LiteralPath $newRoot) {
        $existingItems = @(Get-ChildItem -LiteralPath $newRoot -Force -ErrorAction SilentlyContinue)
        if ($existingItems.Count -gt 0) {
            throw "Content-audit output must be absent or empty: $newRoot"
        }
    }
}

$inventory = Get-Content -LiteralPath $inventoryFile -Raw | ConvertFrom-Json
if ([IO.Path]::GetFullPath([string]$inventory.inputs.runtimeRoot).TrimEnd('\') -ne $sourcePath) {
    throw 'The inventory was not generated from SourceRuntime.'
}
$candidates = @($inventory.files | Where-Object category -eq 'candidate')
if ($candidates.Count -eq 0) {
    throw 'The inventory contains no candidate files to quarantine.'
}

foreach ($candidate in $candidates) {
    $relativePath = [string]$candidate.path
    if ([IO.Path]::IsPathRooted($relativePath) -or $relativePath -match '(^|[\\/])\.\.([\\/]|$)') {
        throw "Unsafe candidate path in inventory: $relativePath"
    }
    $sourceFile = Join-Path $sourcePath $relativePath
    if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
        throw "Audited candidate is missing from the source runtime: $relativePath"
    }
    if ((Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash -ne [string]$candidate.sha256) {
        throw "Audited candidate changed before quarantine: $relativePath"
    }
}

New-Item -ItemType Directory -Path $destinationPath, $quarantinePath -Force | Out-Null
Write-Host "Cloning disposable runtime to $destinationPath"
& robocopy.exe $sourcePath $destinationPath /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -ge 8) {
    throw "Cloning the disposable runtime failed with robocopy exit code $LASTEXITCODE."
}

$moves = @()
foreach ($candidate in $candidates) {
    $relativePath = [string]$candidate.path
    $sourceFile = Join-Path $destinationPath $relativePath
    if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
        throw "Audited candidate is missing from the cloned runtime: $relativePath"
    }
    $actualHash = (Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash
    if ($actualHash -ne [string]$candidate.sha256) {
        throw "Audited candidate changed before quarantine: $relativePath"
    }

    $quarantineFile = Join-Path $quarantinePath $relativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $quarantineFile) -Force | Out-Null
    Move-Item -LiteralPath $sourceFile -Destination $quarantineFile
    $moves += [pscustomobject][ordered]@{
        path = $relativePath
        size = [long]$candidate.size
        sha256 = [string]$candidate.sha256
        feature = [string]$candidate.feature
    }
}

$remainingCandidates = @($moves | Where-Object { Test-Path -LiteralPath (Join-Path $destinationPath $_.path) -PathType Leaf })
if ($remainingCandidates.Count -ne 0) {
    throw 'One or more candidates remained in the audit runtime after quarantine.'
}
$missingQuarantine = @($moves | Where-Object { -not (Test-Path -LiteralPath (Join-Path $quarantinePath $_.path) -PathType Leaf) })
if ($missingQuarantine.Count -ne 0) {
    throw 'One or more candidates were not recorded in quarantine.'
}

$moveManifest = [ordered]@{
    schema = 1
    product = 'Unreal Revived'
    purpose = 'content-audit-quarantine'
    createdAtUtc = [DateTime]::UtcNow.ToString('o')
    sourceRuntime = $sourcePath
    auditRuntime = $destinationPath
    files = @($moves)
    totals = [ordered]@{
        files = $moves.Count
        bytes = [long](($moves | Measure-Object -Property size -Sum).Sum)
    }
}
$moveManifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $quarantinePath 'quarantine-manifest.json') -Encoding UTF8

Write-Host "Audit runtime ready: $destinationPath"
Write-Host "Quarantined $($moveManifest.totals.files) files ($($moveManifest.totals.bytes) bytes): $quarantinePath"
# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [Parameter(Mandatory = $true)]
    [string] $SdkRoot,

    [Parameter(Mandatory = $true)]
    [string] $StageRoot,

    [Parameter(Mandatory = $true)]
    [string] $PatchPath
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $SdkRoot 'WinDrv')).TrimEnd('\')
$patchFile = [IO.Path]::GetFullPath($PatchPath)
$requiredPaths = @(
    (Join-Path $sourceRoot 'Inc\WinDrv.h'),
    (Join-Path $sourceRoot 'Src\WinClient.cpp'),
    (Join-Path $sourceRoot 'Src\WinDrv.cpp'),
    (Join-Path $sourceRoot 'Src\WinInput.cpp'),
    (Join-Path $sourceRoot 'Src\WinViewport.cpp'),
    (Join-Path $sourceRoot 'Src\Res\WinDrvRes.rc'),
    (Join-Path $sourceRoot 'Src\Res\WinDrvRes.h'),
    $patchFile
)
foreach ($requiredPath in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Missing XInputWinDrv staging input: $requiredPath"
    }
}

$git = Get-Command git -ErrorAction Stop
$stagePath = [IO.Path]::GetFullPath($StageRoot)
$stagePathRoot = [IO.Path]::GetPathRoot($stagePath).TrimEnd('\')
$normalizedStagePath = $stagePath.TrimEnd('\')
$repositoryPath = [IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\')
if ($normalizedStagePath -eq $stagePathRoot) {
    throw 'StageRoot must not be a filesystem root.'
}
if ($normalizedStagePath -eq $repositoryPath -or
    $repositoryPath.StartsWith("$normalizedStagePath\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'StageRoot must not be the repository root or one of its parent directories.'
}
if ($normalizedStagePath -eq $sourceRoot -or
    $normalizedStagePath.StartsWith("$sourceRoot\", [StringComparison]::OrdinalIgnoreCase) -or
    $sourceRoot.StartsWith("$normalizedStagePath\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'StageRoot must not overlap the pinned WinDrv source tree.'
}
if ($patchFile -eq $normalizedStagePath -or
    $patchFile.StartsWith("$normalizedStagePath\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The XInputWinDrv patch must not be stored inside StageRoot.'
}
if (Test-Path -LiteralPath $stagePath) {
    Remove-Item -LiteralPath $stagePath -Recurse -Force
}
New-Item -ItemType Directory -Path $stagePath -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceRoot 'Inc') -Destination $stagePath -Recurse
Copy-Item -LiteralPath (Join-Path $sourceRoot 'Src') -Destination $stagePath -Recurse

$normalizedPatch = Join-Path $stagePath '227k_15-xinputwindrv.patch'
$patchText = [IO.File]::ReadAllText($patchFile).Replace("`r`n", "`n")
[IO.File]::WriteAllText($normalizedPatch, $patchText, [Text.UTF8Encoding]::new($false))

& $git.Source apply --unidiff-zero --unsafe-paths "--directory=$stagePath" --check $normalizedPatch
if ($LASTEXITCODE -ne 0) {
    throw 'The XInputWinDrv source patch does not apply to the pinned SDK.'
}
& $git.Source apply --unidiff-zero --unsafe-paths "--directory=$stagePath" $normalizedPatch
if ($LASTEXITCODE -ne 0) {
    throw 'Applying the XInputWinDrv source patch failed.'
}
Remove-Item -LiteralPath $normalizedPatch -Force

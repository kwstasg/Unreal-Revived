# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [Parameter(Mandatory = $true)]
    [string] $GameRoot,

    [Parameter(Mandatory = $true)]
    [string] $SdkRoot,

    [string] $IniName = 'D3D12Test.ini'
)

$ErrorActionPreference = 'Stop'

$GameRoot = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot $GameRoot
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force

$sourcePackage = Join-Path ([IO.Path]::GetFullPath($SdkRoot)) 'OldWeapons'
$sourceClasses = Join-Path $sourcePackage 'Classes'
$runtimePackage = Join-Path $GameRoot 'OldWeapons'
$systemDirectory = Join-Path $GameRoot 'System'
$system64Directory = Join-Path $GameRoot 'System64'
$ucc = Join-Path $system64Directory 'UCC.exe'
$sourceIni = Join-Path $system64Directory $IniName
$buildIni = Join-Path $system64Directory 'OldWeaponsBuild.ini'
$outputPackage = Join-Path $system64Directory 'OldWeapons.u'
$backupPackage = Join-Path $system64Directory 'OldWeapons.u.previous'
$localizedRegistration = Join-Path $GameRoot 'SystemLocalized\int\OldWeapons.int'
$runtimeRegistration = Join-Path $systemDirectory 'OldWeapons.int'
$soundPackage = Join-Path $GameRoot 'Sounds\OldWeaponsSounds.uax'
$texturePackage = Join-Path $GameRoot 'Textures\OldWeaponsTex.utx'

foreach ($requiredPath in @($sourceClasses, $systemDirectory, $system64Directory, $ucc, $sourceIni, $localizedRegistration, $soundPackage, $texturePackage)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing Old Weapons build input: $requiredPath"
    }
}
if (Test-Path -LiteralPath $runtimePackage) {
    throw "Old Weapons source staging path already exists: $runtimePackage"
}
if (Test-Path -LiteralPath $buildIni) {
    throw "Old Weapons build profile already exists: $buildIni"
}
if (Test-Path -LiteralPath $backupPackage) {
    throw "Old Weapons package backup already exists: $backupPackage"
}

$hadPreviousPackage = Test-Path -LiteralPath $outputPackage -PathType Leaf
$buildSucceeded = $false
try {
    Copy-Item -LiteralPath $sourcePackage -Destination $runtimePackage -Recurse
    Copy-Item -LiteralPath $sourceIni -Destination $buildIni
    $iniLines = Get-Content -LiteralPath $buildIni
    $iniLines = Add-UnrealRevivedIniValue $iniLines 'Editor.EditorEngine' 'EditPackages' 'OldWeapons'
    Set-Content -LiteralPath $buildIni -Value $iniLines -Encoding ASCII

    if ($hadPreviousPackage) {
        Move-Item -LiteralPath $outputPackage -Destination $backupPackage
    }

    Push-Location $system64Directory
    try {
        & $ucc make -silent 'ini=OldWeaponsBuild.ini'
        if ($LASTEXITCODE -ne 0) {
            throw "UCC failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }

    if (-not (Test-Path -LiteralPath $outputPackage -PathType Leaf)) {
        throw "UCC did not produce $outputPackage"
    }

    Copy-Item -LiteralPath $localizedRegistration -Destination $runtimeRegistration -Force
    $buildSucceeded = $true
}
finally {
    Remove-Item -LiteralPath $runtimePackage -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $buildIni -Force -ErrorAction SilentlyContinue
    if ($buildSucceeded) {
        Remove-Item -LiteralPath $backupPackage -Force -ErrorAction SilentlyContinue
    }
    elseif ($hadPreviousPackage -and (Test-Path -LiteralPath $backupPackage -PathType Leaf)) {
        Remove-Item -LiteralPath $outputPackage -Force -ErrorAction SilentlyContinue
        Move-Item -LiteralPath $backupPackage -Destination $outputPackage
    }
    else {
        Remove-Item -LiteralPath $outputPackage -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Old Weapons deployed to $outputPackage"
Write-Host "Mutator registration deployed to $runtimeRegistration"

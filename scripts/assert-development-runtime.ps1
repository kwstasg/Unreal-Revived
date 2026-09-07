# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [Parameter(Mandatory = $true)]
    [string] $GameRoot
)

$ErrorActionPreference = 'Stop'

$runtimeRoot = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$markerPath = Join-Path $runtimeRoot '.unreal-revived-development.json'
if (-not (Test-Path -LiteralPath (Join-Path $runtimeRoot 'System64\Unreal.exe') -PathType Leaf)) {
    throw "The development runtime is missing System64\Unreal.exe: $runtimeRoot"
}
if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
    throw "Refusing to modify an unmarked game tree: $runtimeRoot. Provision it with scripts\bootstrap-dev-environment.ps1."
}

$marker = Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
if ($marker.product -ne 'Unreal Revived' -or $marker.purpose -ne 'development-runtime') {
    throw "The development marker is invalid: $markerPath"
}

$sourceRoot = [IO.Path]::GetFullPath([string]$marker.originalGameRoot).TrimEnd('\')
if ($sourceRoot -eq $runtimeRoot -or $runtimeRoot.StartsWith("$sourceRoot\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The marked runtime resolves to the original game installation or a directory inside it.'
}

Write-Output $runtimeRoot
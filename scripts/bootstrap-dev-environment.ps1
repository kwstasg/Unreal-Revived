param(
    [string] $OriginalGameRoot,

    [string] $BundlePath,

    [string] $RuntimeArchive,

    [string] $SdkArchive,

    [string] $GameRoot,

    [string] $SdkRoot,

    [string] $BuildRoot,

    [switch] $SkipDownload,

    [switch] $SkipToolchainInstall,

    [switch] $SkipTests,

    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
if (-not $GameRoot) { $GameRoot = Join-Path $repositoryRoot 'local\game' }
if (-not $SdkRoot) { $SdkRoot = Join-Path $repositoryRoot 'local\sdk\227k_15' }
if (-not $BuildRoot) { $BuildRoot = Join-Path $repositoryRoot 'local\build' }

if (-not $OriginalGameRoot) {
    $OriginalGameRoot = & (Join-Path $PSScriptRoot 'find-unreal-gold.ps1')
}

if (-not $SkipToolchainInstall) {
    & (Join-Path $PSScriptRoot 'get-unreal-revived-prerequisites.ps1')
}
elseif (-not (Get-Command cmake.exe -ErrorAction SilentlyContinue)) {
    throw 'CMake is unavailable and -SkipToolchainInstall was specified.'
}

$runtimeArguments = @{
    OriginalGameRoot = $OriginalGameRoot
    GameRoot = $GameRoot
    SdkRoot = $SdkRoot
}
if ($BundlePath) {
    $bundleArguments = @{ BundlePath = $BundlePath }
    if ($SkipDownload) { $bundleArguments.SkipDownload = $true }
    $runtimeArguments.BundlePath = & (Join-Path $PSScriptRoot 'get-unreal-revived-developer-bundle.ps1') @bundleArguments
}
else {
    $assetArguments = @{}
    if ($RuntimeArchive) { $assetArguments.RuntimeArchive = $RuntimeArchive }
    if ($SdkArchive) { $assetArguments.SdkArchive = $SdkArchive }
    if ($SkipDownload) { $assetArguments.SkipDownload = $true }
    $assets = & (Join-Path $PSScriptRoot 'get-oldunreal-227k15-assets.ps1') @assetArguments
    $runtimeArguments.RuntimeArchive = $assets.RuntimeArchive
    $runtimeArguments.SdkArchive = $assets.SdkArchive
}
if ($Force) { $runtimeArguments.Force = $true }
& (Join-Path $PSScriptRoot 'new-disposable-runtime.ps1') @runtimeArguments

$gamePath = [IO.Path]::GetFullPath($GameRoot)
$sdkPath = [IO.Path]::GetFullPath($SdkRoot)
$buildPath = [IO.Path]::GetFullPath($BuildRoot)

& cmake.exe -S $repositoryRoot -B $buildPath -A x64 "-DUE1_GAME_ROOT=$gamePath" "-DUE1_227K_SDK_ROOT=$sdkPath"
if ($LASTEXITCODE -ne 0) {
    throw "CMake configuration failed with exit code $LASTEXITCODE."
}
& cmake.exe --build $buildPath --target deploy-d3d12drv deploy-xinputwindrv deploy-modern-menu --config Release
if ($LASTEXITCODE -ne 0) {
    throw "Unreal Revived development build failed with exit code $LASTEXITCODE."
}

if (-not $SkipTests) {
    $previousGameRoot = $env:UE1_GAME_ROOT
    try {
        $env:UE1_GAME_ROOT = $gamePath
        & (Join-Path $PSScriptRoot 'test-d3d12-runtime.ps1') -Suite Content
    }
    finally {
        $env:UE1_GAME_ROOT = $previousGameRoot
    }
}

& (Join-Path $PSScriptRoot 'install-development-shortcuts.ps1') -GameRoot $gamePath

Write-Host 'Unreal Revived development environment is ready.'
Write-Host "Runtime: $gamePath"
Write-Host "SDK: $sdkPath"
Write-Host "Build: $buildPath"
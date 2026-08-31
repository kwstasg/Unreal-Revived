param(
    [Parameter(Mandatory = $true)]
    [string] $OriginalGameRoot,

    [string] $BundlePath,

    [string] $RuntimeArchive,

    [string] $SdkArchive,

    [string] $GameRoot,

    [string] $SdkRoot,

    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$hostManifestPath = Join-Path $repositoryRoot 'manifests\hosts\unreal-gold-227k_15-win64.json'
$developerManifestPath = Join-Path $repositoryRoot 'manifests\developer\unreal-revived-227k_15-v1.json'
$developmentMarkerName = '.unreal-revived-development.json'
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Integrity.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force

if (-not $GameRoot) {
    $GameRoot = Join-Path $repositoryRoot 'local\game'
}
if (-not $SdkRoot) {
    $SdkRoot = Join-Path $repositoryRoot 'local\sdk\227k_15'
}

$sourceRoot = [IO.Path]::GetFullPath($OriginalGameRoot).TrimEnd('\')
$destinationRoot = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$sdkDestination = [IO.Path]::GetFullPath($SdkRoot).TrimEnd('\')
$hostManifest = Get-Content -LiteralPath $hostManifestPath -Raw | ConvertFrom-Json

if ($BundlePath) {
    $bundleFile = [IO.Path]::GetFullPath($BundlePath)
    $developerManifest = Get-Content -LiteralPath $developerManifestPath -Raw | ConvertFrom-Json
    $bundleHash = Assert-UnrealRevivedFileIntegrity -Path $bundleFile `
        -ExpectedSize $developerManifest.release.size `
        -ExpectedSha256 $developerManifest.release.sha256 `
        -Description 'Developer bundle'
    $sourceRecord = [ordered]@{ type = 'developer-bundle'; sha256 = $bundleHash }
}
else {
    if (-not $RuntimeArchive -or -not $SdkArchive) {
        throw 'Provide either -BundlePath or both -RuntimeArchive and -SdkArchive.'
    }
    $runtimeFile = [IO.Path]::GetFullPath($RuntimeArchive)
    $sdkFile = [IO.Path]::GetFullPath($SdkArchive)
    $runtimeHash = Assert-UnrealRevivedFileIntegrity -Path $runtimeFile `
        -ExpectedSize $hostManifest.release.runtime.size `
        -ExpectedSha256 $hostManifest.release.runtime.sha256 `
        -Description 'Pinned runtime archive'
    $sdkHash = Assert-UnrealRevivedFileIntegrity -Path $sdkFile `
        -ExpectedSize $hostManifest.release.sdk.size `
        -ExpectedSha256 $hostManifest.release.sdk.sha256 `
        -Description 'Pinned SDK archive'
    $sourceRecord = [ordered]@{ type = 'original-archives'; runtimeSha256 = $runtimeHash; sdkSha256 = $sdkHash }
}

if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'System\Unreal.exe') -PathType Leaf)) {
    throw "The selected source is not Unreal Gold: $sourceRoot"
}
if ($sourceRoot -eq $destinationRoot -or $destinationRoot.StartsWith("$sourceRoot\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The disposable runtime must not be the original Steam installation or a directory inside it.'
}

$developmentMarker = Join-Path $destinationRoot $developmentMarkerName
if (Test-Path -LiteralPath $destinationRoot) {
    $existingFiles = @(Get-ChildItem -LiteralPath $destinationRoot -Force -ErrorAction SilentlyContinue)
    if ($existingFiles.Count -gt 0 -and -not (Test-Path -LiteralPath $developmentMarker -PathType Leaf)) {
        throw "The runtime destination is nonempty and has no Unreal Revived development marker: $destinationRoot"
    }
    if ($Force -and (Test-Path -LiteralPath $developmentMarker -PathType Leaf)) {
        Remove-Item -LiteralPath $destinationRoot -Recurse -Force
    }
}

$extractRoot = Join-Path $repositoryRoot 'local\package\bootstrap-extract'
if (Test-Path -LiteralPath $extractRoot) {
    Remove-Item -LiteralPath $extractRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $extractRoot, $destinationRoot, $sdkDestination -Force | Out-Null

try {
    if ($bundleFile) {
        & tar.exe -xf $bundleFile -C $extractRoot
        if ($LASTEXITCODE -ne 0) {
            throw "Could not extract the developer bundle (tar exit code $LASTEXITCODE)."
        }
        if (-not (Test-Path -LiteralPath (Join-Path $extractRoot 'bundle-manifest.json') -PathType Leaf)) {
            throw 'The developer bundle is missing bundle-manifest.json.'
        }
    }
    else {
        $extractedHostRoot = Join-Path $extractRoot 'host'
        $extractedSdkRoot = Join-Path $extractRoot 'sdk'
        New-Item -ItemType Directory -Path $extractedHostRoot, $extractedSdkRoot -Force | Out-Null
        & tar.exe -xf $runtimeFile -C $extractedHostRoot
        if ($LASTEXITCODE -ne 0) {
            throw "Could not extract the pinned runtime archive (tar exit code $LASTEXITCODE)."
        }
        & tar.exe -xf $sdkFile -C $extractedSdkRoot
        if ($LASTEXITCODE -ne 0) {
            throw "Could not extract the pinned SDK archive (tar exit code $LASTEXITCODE)."
        }
    }

    Assert-UnrealRevivedHostModules -HostRoot (Join-Path $extractRoot 'host') -HostManifest $hostManifest

    & robocopy.exe $sourceRoot $destinationRoot /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) {
        throw "Copying original game assets failed with robocopy exit code $LASTEXITCODE."
    }
    & robocopy.exe (Join-Path $extractRoot 'host') $destinationRoot /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) {
        throw "Applying the pinned host failed with robocopy exit code $LASTEXITCODE."
    }
    & robocopy.exe (Join-Path $extractRoot 'sdk') $sdkDestination /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) {
        throw "Installing the pinned SDK failed with robocopy exit code $LASTEXITCODE."
    }

    Assert-UnrealRevivedHostModules -HostRoot $destinationRoot -HostManifest $hostManifest

    $defaultIni = Join-Path $destinationRoot 'System64\Default.ini'
    $defaultUserIni = Join-Path $destinationRoot 'System64\DefUser.ini'
    if (-not (Test-Path -LiteralPath $defaultIni -PathType Leaf) -or -not (Test-Path -LiteralPath $defaultUserIni -PathType Leaf)) {
        throw 'The pinned host did not provide the expected x64 default profiles.'
    }
    $iniLines = Get-Content -LiteralPath $defaultIni
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'FirstRun' 'FirstRun' '227'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'GameRenderDevice' 'D3D12Drv.D3D12RenderDevice'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'WindowedRenderDevice' 'D3D12Drv.D3D12RenderDevice'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'Console' 'UMenu.UnrealConsole'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'D3D12Drv.D3D12RenderDevice' 'AntialiasMode' 'Off'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'D3D12Drv.D3D12RenderDevice' 'UseVSync' 'True'
    Set-Content -LiteralPath (Join-Path $destinationRoot 'System64\D3D12Test.ini') -Value $iniLines -Encoding ASCII
    $userIniLines = @(Get-Content -LiteralPath $defaultUserIni)
    $userIniLines += ''
    Set-Content -LiteralPath (Join-Path $destinationRoot 'System64\D3D12TestUser.ini') `
        -Value $userIniLines -Encoding ASCII

    $marker = [ordered]@{
        schema = 1
        product = 'Unreal Revived'
        purpose = 'development-runtime'
        host = $hostManifest.id
        originalGameRoot = $sourceRoot
        source = $sourceRecord
        provisionedAtUtc = [DateTime]::UtcNow.ToString('o')
    }
    $marker | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $developmentMarker -Encoding UTF8
}
finally {
    Remove-Item -LiteralPath $extractRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Disposable runtime ready: $destinationRoot"
Write-Host "OldUnreal SDK ready: $sdkDestination"
param(
    [string] $RuntimeArchive,

    [string] $SdkArchive,

    [string] $CacheRoot,

    [switch] $SkipDownload
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repositoryRoot 'manifests\hosts\unreal-gold-227k_15-win64.json'
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Integrity.psm1') -Force

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if (-not $CacheRoot) {
    $CacheRoot = Join-Path $repositoryRoot 'local\downloads'
}
New-Item -ItemType Directory -Path $CacheRoot -Force | Out-Null

function Resolve-PinnedAsset {
    param(
        [psobject] $Asset,
        [string] $ExplicitPath
    )

    $path = if ($ExplicitPath) {
        [IO.Path]::GetFullPath($ExplicitPath)
    }
    else {
        Join-Path ([IO.Path]::GetFullPath($CacheRoot)) $Asset.archive
    }

    if (Test-Path -LiteralPath $path -PathType Leaf) {
        try {
            $null = Assert-UnrealRevivedFileIntegrity -Path $path `
                -ExpectedSize $Asset.size -ExpectedSha256 $Asset.sha256 `
                -Description $Asset.archive
            return $path
        }
        catch {
            if ($ExplicitPath -or $SkipDownload) {
                throw
            }
            Remove-Item -LiteralPath $path -Force
        }
    }

    if ($ExplicitPath) {
        throw "Pinned archive not found: $path"
    }
    if ($SkipDownload) {
        throw "The verified archive is not cached at $path."
    }

    $partialPath = "$path.partial"
    Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue
    Write-Host "Downloading $($Asset.archive) from OldUnreal"
    try {
        Invoke-WebRequest -Uri $Asset.url -OutFile $partialPath -UseBasicParsing
        $null = Assert-UnrealRevivedFileIntegrity -Path $partialPath `
            -ExpectedSize $Asset.size -ExpectedSha256 $Asset.sha256 `
            -Description $Asset.archive
        Move-Item -LiteralPath $partialPath -Destination $path -Force
    }
    catch {
        $mirror = @($Asset.mirrors) | Select-Object -First 1
        $message = "Could not acquire $($Asset.archive) from its original source."
        if ($mirror) {
            $message += " Download the recovery mirror and save it as '$path': $mirror"
        }
        throw "$message`n$($_.Exception.Message)"
    }
    finally {
        Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue
    }

    return $path
}

$resolvedRuntime = Resolve-PinnedAsset -Asset $manifest.release.runtime -ExplicitPath $RuntimeArchive
$resolvedSdk = Resolve-PinnedAsset -Asset $manifest.release.sdk -ExplicitPath $SdkArchive

[pscustomobject]@{
    RuntimeArchive = $resolvedRuntime
    SdkArchive = $resolvedSdk
}
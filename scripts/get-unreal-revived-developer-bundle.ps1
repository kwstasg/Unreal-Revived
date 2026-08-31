param(
    [string] $BundlePath,

    [string] $CacheRoot,

    [switch] $SkipDownload
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repositoryRoot 'manifests\developer\unreal-revived-227k_15-v1.json'
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Integrity.psm1') -Force

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if (-not $CacheRoot) {
    $CacheRoot = Join-Path $repositoryRoot 'local\downloads'
}

if ($BundlePath) {
    $resolvedBundle = [IO.Path]::GetFullPath($BundlePath)
    if (-not (Test-Path -LiteralPath $resolvedBundle -PathType Leaf)) {
        throw "Developer bundle not found: $resolvedBundle"
    }
}
else {
    New-Item -ItemType Directory -Path $CacheRoot -Force | Out-Null
    $resolvedBundle = Join-Path ([IO.Path]::GetFullPath($CacheRoot)) $manifest.release.asset
    $cachedBundleValid = $false
    if (Test-Path -LiteralPath $resolvedBundle -PathType Leaf) {
        try {
            $null = Assert-UnrealRevivedFileIntegrity -Path $resolvedBundle `
                -ExpectedSize $manifest.release.size `
                -ExpectedSha256 $manifest.release.sha256 `
                -Description 'Cached developer bundle'
            $cachedBundleValid = $true
        }
        catch {
            if ($SkipDownload) {
                throw
            }
            Remove-Item -LiteralPath $resolvedBundle -Force
        }
    }

    if (-not $cachedBundleValid) {
        if ($SkipDownload) {
            throw "The verified developer bundle is not cached at $resolvedBundle."
        }
        if (-not $manifest.release.url) {
            throw 'No hosted developer bundle URL is configured. Use the default original-archive bootstrap path or pass -BundlePath.'
        }

        $partialPath = "$resolvedBundle.partial"
        Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue
        Write-Host "Downloading $($manifest.release.asset)"
        try {
            Invoke-WebRequest -Uri $manifest.release.url -OutFile $partialPath -UseBasicParsing
            $null = Assert-UnrealRevivedFileIntegrity -Path $partialPath `
                -ExpectedSize $manifest.release.size `
                -ExpectedSha256 $manifest.release.sha256 `
                -Description 'Downloaded developer bundle'
            Move-Item -LiteralPath $partialPath -Destination $resolvedBundle -Force
        }
        finally {
            Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue
        }
    }
}

$null = Assert-UnrealRevivedFileIntegrity -Path $resolvedBundle `
    -ExpectedSize $manifest.release.size `
    -ExpectedSha256 $manifest.release.sha256 `
    -Description 'Developer bundle'

Write-Output $resolvedBundle
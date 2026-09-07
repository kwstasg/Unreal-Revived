# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

function Assert-UnrealRevivedFileIntegrity {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [long] $ExpectedSize,

        [Parameter(Mandatory = $true)]
        [string] $ExpectedSha256,

        [string] $Description = 'File'
    )

    $file = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($file.Length -ne $ExpectedSize) {
        throw "$Description size mismatch. Expected $ExpectedSize bytes, got $($file.Length)."
    }

    $actualHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    if ($actualHash -ne $ExpectedSha256) {
        throw "$Description SHA-256 mismatch. Expected $ExpectedSha256, got $actualHash."
    }

    return $actualHash
}

function Assert-UnrealRevivedHostModules {
    param(
        [Parameter(Mandatory = $true)]
        [string] $HostRoot,

        [Parameter(Mandatory = $true)]
        [psobject] $HostManifest
    )

    foreach ($name in @('Core.dll', 'Engine.dll', 'Render.dll', 'Unreal.exe', 'WinDrv.dll')) {
        $path = Join-Path $HostRoot "System64\$name"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Host module is missing: $name"
        }

        $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        $expectedHash = $HostManifest.modules.$name
        if ($actualHash -ne $expectedHash) {
            throw "Host module SHA-256 mismatch for $name. Expected $expectedHash, got $actualHash."
        }
    }
}

Export-ModuleMember -Function Assert-UnrealRevivedFileIntegrity, Assert-UnrealRevivedHostModules

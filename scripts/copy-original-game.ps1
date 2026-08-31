param(
    [Parameter(Mandatory = $true)]
    [string] $InstallRoot,

    [Parameter(Mandatory = $true)]
    [string] $OriginalGameRoot
)

$ErrorActionPreference = 'Stop'

$sourceRoot = [IO.Path]::GetFullPath($OriginalGameRoot).TrimEnd('\')
$destinationRoot = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')
if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'System\Unreal.exe') -PathType Leaf)) {
    throw "The selected source is not Unreal Gold: $sourceRoot"
}
if ($sourceRoot -eq $destinationRoot -or $destinationRoot.StartsWith("$sourceRoot\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The Unreal Revived destination must not be the original installation or a directory inside it.'
}

$installMarker = Join-Path $destinationRoot '.unreal-revived.json'
if (Test-Path -LiteralPath $destinationRoot) {
    $existingFiles = @(Get-ChildItem -LiteralPath $destinationRoot -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^unins\d+\.(exe|dat)$' })
    if ($existingFiles.Count -gt 0 -and -not (Test-Path -LiteralPath $installMarker -PathType Leaf)) {
        throw "The destination is not empty and is not an existing Unreal Revived installation: $destinationRoot"
    }
}
else {
    New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
}

& robocopy $sourceRoot $destinationRoot /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -ge 8) {
    throw "Copying original game assets failed with robocopy exit code $LASTEXITCODE."
}
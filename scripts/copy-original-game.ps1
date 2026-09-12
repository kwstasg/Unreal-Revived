# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [Parameter(Mandatory = $true)]
    [string] $InstallRoot,

    [Parameter(Mandatory = $true)]
    [string] $OriginalGameRoot,

    [Parameter(Mandatory = $true)]
    [string] $ContentManifest,

    [string] $ErrorLog
)

$ErrorActionPreference = 'Stop'

trap {
    if ($ErrorLog) {
        Set-Content -LiteralPath $ErrorLog -Value $_.Exception.Message -Encoding UTF8
    }
    Write-Error $_ -ErrorAction Continue
    exit 1
}

function Test-RetainedBrandingDirectory {
    param([IO.DirectoryInfo] $Directory)

    if ($Directory.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        return $false
    }
    foreach ($item in Get-ChildItem -LiteralPath $Directory.FullName -Force) {
        if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
            $item.Name -notmatch '^UnrealRevived-Icon-([0-9a-f]{12})\.ico$') {
            return $false
        }
        $expectedPrefix = $Matches[1]
        if (-not (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.StartsWith(
            $expectedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            return $false
        }
    }
    return $true
}

$sourceRoot = [IO.Path]::GetFullPath($OriginalGameRoot).TrimEnd('\')
$destinationRoot = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')
$contentManifestPath = [IO.Path]::GetFullPath($ContentManifest)
if (-not (Test-Path -LiteralPath $contentManifestPath -PathType Leaf)) {
    throw "The install content manifest is missing: $contentManifestPath"
}
$contentPolicy = Get-Content -LiteralPath $contentManifestPath -Raw | ConvertFrom-Json
if ($contentPolicy.schema -ne 1) {
    throw "Unsupported install content manifest schema: $($contentPolicy.schema)"
}
if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'System\Unreal.exe') -PathType Leaf)) {
    throw "The selected source is not Unreal Gold: $sourceRoot"
}
if ($sourceRoot -eq $destinationRoot -or $destinationRoot.StartsWith("$sourceRoot\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The Unreal Revived destination must not be the original installation or a directory inside it.'
}

$installMarker = Join-Path $destinationRoot '.unreal-revived.json'
if (Test-Path -LiteralPath $destinationRoot) {
    $existingFiles = @(Get-ChildItem -LiteralPath $destinationRoot -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^unins\d+\.(exe|dat)$' })
    $unexpectedFiles = @($existingFiles | Where-Object {
        if ($_.Name -eq 'Save' -and $_.PSIsContainer) { return $false }
        # Windows can retain a shortcut icon after uninstall. Accept only our
        # content-addressed icons, verifying their hashes before reusing the folder.
        if ($_.Name -eq 'UnrealRevived' -and $_.PSIsContainer) {
            return -not (Test-RetainedBrandingDirectory $_)
        }
        return $true
    })
    if ($unexpectedFiles.Count -gt 0 -and -not (Test-Path -LiteralPath $installMarker -PathType Leaf)) {
        throw "The destination is not empty and is not an existing Unreal Revived installation: $destinationRoot"
    }
}
else {
    New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
}

$excludedDirectories = @($contentPolicy.exclusions.directories | ForEach-Object { Join-Path $sourceRoot ([string]$_) })
$excludedFiles = @($contentPolicy.exclusions.files | ForEach-Object { Join-Path $sourceRoot ([string]$_).Replace('/', '\') })
foreach ($rule in @($contentPolicy.exclusions.directFileExtensions)) {
    $directory = Join-Path $sourceRoot ([string]$rule.path).Replace('/', '\')
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        continue
    }
    $extensions = @($rule.extensions | ForEach-Object { ([string]$_).ToLowerInvariant() })
    $excludedFiles += @(Get-ChildItem -LiteralPath $directory -File -Force | Where-Object {
        $_.Extension.ToLowerInvariant() -in $extensions
    } | ForEach-Object FullName)
}
$registrationBaseNames = @(
    $contentPolicy.metadataFiltering.rendererRegistrationBaseNames
    $contentPolicy.metadataFiltering.audioRegistrationBaseNames
) | ForEach-Object { [string]$_ }
if ($registrationBaseNames.Count -gt 0) {
    $excludedFiles += @(Get-ChildItem -LiteralPath $sourceRoot -File -Recurse -Filter '*.int' -Force | Where-Object {
        $_.BaseName -in $registrationBaseNames
    } | ForEach-Object FullName)
    $localizedMetadataRoot = Join-Path $sourceRoot 'SystemLocalized'
    if (Test-Path -LiteralPath $localizedMetadataRoot -PathType Container) {
        $excludedFiles += @(Get-ChildItem -LiteralPath $localizedMetadataRoot -File -Recurse -Force | Where-Object {
            $_.BaseName -in $registrationBaseNames
        } | ForEach-Object FullName)
    }
}
foreach ($rule in @($contentPolicy.exclusions.directoryContentsExcept)) {
    $directory = Join-Path $sourceRoot ([string]$rule.path).Replace('/', '\')
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        continue
    }
    $keep = @($rule.keep | ForEach-Object { [string]$_ })
    $excludedFiles += @(Get-ChildItem -LiteralPath $directory -File -Recurse -Force | Where-Object {
        $relativePath = $_.FullName.Substring($directory.Length).TrimStart('\')
        $relativePath -notin $keep
    } | ForEach-Object FullName)
}

$robocopyArguments = @($sourceRoot, $destinationRoot, '/E', '/COPY:DAT', '/DCOPY:DAT', '/R:2', '/W:1', '/NFL', '/NDL', '/NJH', '/NJS', '/NP')
if ($excludedDirectories.Count -gt 0) {
    $robocopyArguments += @('/XD') + $excludedDirectories
}
if ($excludedFiles.Count -gt 0) {
    $robocopyArguments += @('/XF') + $excludedFiles
}
if (Test-Path -LiteralPath (Join-Path $destinationRoot 'Save') -PathType Container) {
    $robocopyArguments += @('/XD', (Join-Path $sourceRoot 'Save'))
}

& robocopy @robocopyArguments
if ($LASTEXITCODE -ge 8) {
    throw "Copying original game assets failed with robocopy exit code $LASTEXITCODE."
}

$englishAudioRoot = Join-Path $destinationRoot 'Sounds\int'
$audioRoot = Join-Path $destinationRoot 'Sounds'
if (Test-Path -LiteralPath $englishAudioRoot -PathType Container) {
    foreach ($audioFile in Get-ChildItem -LiteralPath $englishAudioRoot -File -Filter '*.uax') {
        $audioDestination = Join-Path $audioRoot $audioFile.Name
        if (-not (Test-Path -LiteralPath $audioDestination -PathType Leaf)) {
            Copy-Item -LiteralPath $audioFile.FullName -Destination $audioDestination
        }
    }
}

$startupDescriptionPrefixes = @($contentPolicy.metadataFiltering.startupDescriptionPrefixes | ForEach-Object { [string]$_ })
if ($startupDescriptionPrefixes.Count -gt 0) {
    foreach ($startupFile in Get-ChildItem -LiteralPath $destinationRoot -File -Recurse -Filter 'Startup.*' -Force) {
        $filteredLines = @(Get-Content -LiteralPath $startupFile.FullName | Where-Object {
            $line = $_
            -not ($startupDescriptionPrefixes | Where-Object { $line.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) })
        })
        Set-Content -LiteralPath $startupFile.FullName -Value $filteredLines -Encoding UTF8
    }
}

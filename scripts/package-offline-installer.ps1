param(
    [Parameter(Mandatory = $true)]
    [string] $RendererDll,

    [Parameter(Mandatory = $true)]
    [string] $GameRoot,

    [string] $PatchArchive,

    [string] $StageRoot,

    [switch] $BuildInstaller
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$hostManifestPath = Join-Path $repositoryRoot 'manifests\hosts\unreal-gold-227k_15-win64.json'
$contentManifestPath = Join-Path $repositoryRoot 'manifests\content\unreal-revived-install-content-v1.json'
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Integrity.psm1') -Force
if (-not $PatchArchive) {
    $PatchArchive = Join-Path $repositoryRoot 'local\downloads\OldUnreal-UnrealPatch227k-Windows.zip'
}
if (-not $StageRoot) {
    $StageRoot = Join-Path $repositoryRoot 'local\package\offline-installer'
}

$rendererInt = Join-Path $repositoryRoot 'D3D12Drv\D3D12Drv.int'
$modernMenu = Join-Path $GameRoot 'System64\ModernMenu.u'
$installScript = Join-Path $repositoryRoot 'scripts\install-unreal-revived.ps1'
$copyScript = Join-Path $repositoryRoot 'scripts\copy-original-game.ps1'
$backupScript = Join-Path $repositoryRoot 'scripts\backup-unreal-revived-user-data.ps1'
$brandingRoot = Join-Path $repositoryRoot 'branding'
$brandingLogo = Join-Path $brandingRoot 'Logo.bmp'
$brandingSetupLogo = Join-Path $brandingRoot 'SetupLogo.bmp'
$brandingIcon = Join-Path $brandingRoot 'UnrealRevived.ico'
$installedBrandingIconName = 'UnrealRevived-Icon-v1.ico'
$iniModule = Join-Path $repositoryRoot 'scripts\UnrealRevived.Ini.psm1'
$permissions = Join-Path $repositoryRoot 'PERMISSIONS.md'
$installerDefinition = Join-Path $repositoryRoot 'packaging\UnrealRevived.iss'

foreach ($requiredPath in @($hostManifestPath, $contentManifestPath, $PatchArchive, $RendererDll, $rendererInt, $modernMenu, $installScript, $copyScript, $backupScript, $brandingLogo, $brandingSetupLogo, $brandingIcon, $iniModule, $permissions)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Missing offline package input: $requiredPath"
    }
}

$hostManifest = Get-Content -LiteralPath $hostManifestPath -Raw | ConvertFrom-Json
$archiveHash = Assert-UnrealRevivedFileIntegrity -Path $PatchArchive `
    -ExpectedSize $hostManifest.release.runtime.size `
    -ExpectedSha256 $hostManifest.release.runtime.sha256 `
    -Description 'Pinned patch archive'

$stagePath = [IO.Path]::GetFullPath($StageRoot)
$repositoryPath = [IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\')
if ($stagePath.TrimEnd('\') -eq $repositoryPath) {
    throw 'StageRoot must not be the repository root.'
}

if (Test-Path -LiteralPath $stagePath) {
    Remove-Item -LiteralPath $stagePath -Recurse -Force
}
$payloadRoot = Join-Path $stagePath 'payload'
$patchRoot = Join-Path $stagePath 'patch'
$outputRoot = Join-Path $stagePath 'output'
New-Item -ItemType Directory -Path $payloadRoot, $patchRoot, $outputRoot -Force | Out-Null

Write-Host 'Extracting the verified patch for direct Inno Setup packaging'
Expand-Archive -LiteralPath $PatchArchive -DestinationPath $patchRoot -Force
Assert-UnrealRevivedHostModules -HostRoot $patchRoot -HostManifest $hostManifest
Copy-Item -LiteralPath $brandingLogo -Destination (Join-Path $patchRoot 'Help\Logo.bmp') -Force
Copy-Item -LiteralPath $brandingSetupLogo -Destination (Join-Path $patchRoot 'Help\SetupLogo.bmp') -Force
$stagedBrandingRoot = Join-Path $patchRoot 'UnrealRevived'
New-Item -ItemType Directory -Path $stagedBrandingRoot -Force | Out-Null
Copy-Item -LiteralPath $brandingIcon -Destination (Join-Path $stagedBrandingRoot $installedBrandingIconName) -Force

$contentPolicy = Get-Content -LiteralPath $contentManifestPath -Raw | ConvertFrom-Json
if ($contentPolicy.schema -ne 1) {
    throw "Unsupported install content manifest schema: $($contentPolicy.schema)"
}
foreach ($relativePath in @($contentPolicy.exclusions.directories)) {
    Remove-Item -LiteralPath (Join-Path $patchRoot ([string]$relativePath).Replace('/', '\')) -Recurse -Force -ErrorAction SilentlyContinue
}
foreach ($rule in @($contentPolicy.exclusions.directoryContentsExcept)) {
    $directory = Join-Path $patchRoot ([string]$rule.path).Replace('/', '\')
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        continue
    }
    $keep = @($rule.keep | ForEach-Object { [string]$_ })
    Get-ChildItem -LiteralPath $directory -File -Recurse -Force | Where-Object {
        $relativePath = $_.FullName.Substring($directory.Length).TrimStart('\')
        $relativePath -notin $keep
    } | Remove-Item -Force
}
foreach ($relativePath in @($contentPolicy.exclusions.files)) {
    Remove-Item -LiteralPath (Join-Path $patchRoot ([string]$relativePath).Replace('/', '\')) -Force -ErrorAction SilentlyContinue
}
foreach ($rule in @($contentPolicy.exclusions.directFileExtensions)) {
    $directory = Join-Path $patchRoot ([string]$rule.path).Replace('/', '\')
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        continue
    }
    $extensions = @($rule.extensions | ForEach-Object { ([string]$_).ToLowerInvariant() })
    Get-ChildItem -LiteralPath $directory -File -Force | Where-Object {
        $_.Extension.ToLowerInvariant() -in $extensions
    } | Remove-Item -Force
}
$registrationBaseNames = @(
    $contentPolicy.metadataFiltering.rendererRegistrationBaseNames
    $contentPolicy.metadataFiltering.audioRegistrationBaseNames
) | ForEach-Object { [string]$_ }
if ($registrationBaseNames.Count -gt 0) {
    Get-ChildItem -LiteralPath $patchRoot -File -Recurse -Filter '*.int' -Force | Where-Object {
        $_.BaseName -in $registrationBaseNames
    } | Remove-Item -Force
    $localizedMetadataRoot = Join-Path $patchRoot 'SystemLocalized'
    if (Test-Path -LiteralPath $localizedMetadataRoot -PathType Container) {
        Get-ChildItem -LiteralPath $localizedMetadataRoot -File -Recurse -Force | Where-Object {
            $_.BaseName -in $registrationBaseNames
        } | Remove-Item -Force
    }
}
$startupDescriptionPrefixes = @($contentPolicy.metadataFiltering.startupDescriptionPrefixes | ForEach-Object { [string]$_ })
if ($startupDescriptionPrefixes.Count -gt 0) {
    $d3d12Description = 'D3D12Drv.D3D12RenderDevice="Use Unreal Revived''s native Direct3D 12 renderer. Recommended for modern Windows systems, with high-resolution texture support, HD lightmaps, and MSAA."'
    foreach ($startupFile in Get-ChildItem -LiteralPath $patchRoot -File -Recurse -Filter 'Startup.*' -Force) {
        $filteredLines = @(Get-Content -LiteralPath $startupFile.FullName | Where-Object {
            $line = $_
            -not ($startupDescriptionPrefixes | Where-Object { $line.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }) -and
                -not $line.StartsWith('D3D12Drv.D3D12RenderDevice=', [StringComparison]::OrdinalIgnoreCase)
        })
        if (-not ($filteredLines | Where-Object { $_ -ieq '[Descriptions]' })) {
            throw "Startup localization has no Descriptions section: $($startupFile.FullName)"
        }
        $inDescriptions = $false
        $localizedLines = @($filteredLines | ForEach-Object {
            if ($_ -ieq '[Descriptions]') {
                $inDescriptions = $true
            }
            elseif ($inDescriptions -and $_ -match '^\[.+\]$') {
                $d3d12Description
                $inDescriptions = $false
            }
            $_
        })
        if ($inDescriptions) {
            $localizedLines += $d3d12Description
        }
        Set-Content -LiteralPath $startupFile.FullName -Value $localizedLines -Encoding UTF8
    }
}

Import-Module $iniModule -Force
foreach ($defaultProfile in @('System\Default.ini', 'System64\Default.ini')) {
    $defaultProfilePath = Join-Path $patchRoot $defaultProfile
    $defaultProfileLines = Get-Content -LiteralPath $defaultProfilePath
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'Engine.Engine' 'GameRenderDevice' 'D3D12Drv.D3D12RenderDevice'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'Engine.Engine' 'WindowedRenderDevice' 'D3D12Drv.D3D12RenderDevice'
    Set-Content -LiteralPath $defaultProfilePath -Value $defaultProfileLines -Encoding ASCII
}

$payloadSources = [ordered]@{
    'D3D12Drv.dll' = $RendererDll
    'D3D12Drv.int' = $rendererInt
    'ModernMenu.u' = $modernMenu
    'install-unreal-revived.ps1' = $installScript
    'backup-unreal-revived-user-data.ps1' = $backupScript
    'UnrealRevived.Ini.psm1' = $iniModule
    'PERMISSIONS.md' = $permissions
    'unreal-gold-227k_15-win64.json' = $hostManifestPath
    'unreal-revived-install-content-v1.json' = $contentManifestPath
}

foreach ($entry in $payloadSources.GetEnumerator()) {
    Copy-Item -LiteralPath $entry.Value -Destination (Join-Path $payloadRoot $entry.Key) -Force
}
Copy-Item -LiteralPath $copyScript -Destination (Join-Path $payloadRoot 'copy-original-game.ps1') -Force

$payloadFiles = foreach ($name in $payloadSources.Keys) {
    $path = Join-Path $payloadRoot $name
    [ordered]@{
        path = $name
        size = (Get-Item -LiteralPath $path).Length
        sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    }
}

$gitRevision = (& git -C $repositoryRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Could not determine the source Git revision.'
}
$payloadManifest = [ordered]@{
    schema = 1
    product = 'Unreal Revived'
    sourceRevision = $gitRevision
    patch = $hostManifest.release
    extractedPatchFiles = @(Get-ChildItem -LiteralPath $patchRoot -File -Recurse).Count
    files = @($payloadFiles)
}
$payloadManifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $payloadRoot 'payload-manifest.json') -Encoding UTF8

Write-Host "Offline payload staged at $payloadRoot"
Write-Host "Pinned patch SHA-256 verified: $archiveHash"

if (-not $BuildInstaller) {
    return
}

if (-not (Test-Path -LiteralPath $installerDefinition -PathType Leaf)) {
    throw "Missing Inno Setup definition: $installerDefinition"
}

$iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
if (-not $iscc) {
    $isccCandidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
        'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
        'C:\Program Files\Inno Setup 6\ISCC.exe'
    )
    $isccPath = $isccCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}
else {
    $isccPath = $iscc.Source
}

if (-not $isccPath) {
    throw 'Inno Setup 6 is required to build the installer. Install package JRSoftware.InnoSetup, then rerun the package-offline-installer target.'
}

& $isccPath "/DStageRoot=$stagePath" "/DOutputDir=$outputRoot" $installerDefinition
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup failed with exit code $LASTEXITCODE."
}

$installer = Get-ChildItem -LiteralPath $outputRoot -Filter 'UnrealRevived-Setup-*.exe' | Select-Object -First 1
if (-not $installer) {
    throw 'Inno Setup completed without producing the expected installer.'
}

$installerHash = (Get-FileHash -LiteralPath $installer.FullName -Algorithm SHA256).Hash
Set-Content -LiteralPath "$($installer.FullName).sha256" -Value "$installerHash  $($installer.Name)" -Encoding ASCII
Write-Host "Offline installer created: $($installer.FullName)"
Write-Host "Installer SHA-256: $installerHash"
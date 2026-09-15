# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [Parameter(Mandatory = $true)]
    [string] $RendererDll,

    [Parameter(Mandatory = $true)]
    [string] $LoaderDll,

    [Parameter(Mandatory = $true)]
    [string] $OpenXRNotice,

    [Parameter(Mandatory = $true)]
    [string] $InputDll,

    [Parameter(Mandatory = $true)]
    [string] $GameRoot,

    [string] $PatchArchive,

    [string] $StageRoot,

    [Parameter(Mandatory = $true)]
    [string] $LauncherBinaryRoot,

    [string] $SdkRoot,

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
$oldWeapons = Join-Path $GameRoot 'System64\OldWeapons.u'
$installScript = Join-Path $repositoryRoot 'scripts\install-unreal-revived.ps1'
$copyScript = Join-Path $repositoryRoot 'scripts\copy-original-game.ps1'
$backupScript = Join-Path $repositoryRoot 'scripts\backup-unreal-revived-user-data.ps1'
$brandingRoot = Join-Path $repositoryRoot 'branding'
$brandingLogo = Join-Path $brandingRoot 'Logo.bmp'
$brandingSetupLogo = Join-Path $brandingRoot 'SetupLogo.bmp'
$installerWizardImage = Join-Path $brandingRoot 'InstallerWizard.png'
$brandingIcon = Join-Path $brandingRoot 'UnrealRevived.ico'
$iniModule = Join-Path $repositoryRoot 'scripts\UnrealRevived.Ini.psm1'
$permissions = Join-Path $repositoryRoot 'PERMISSIONS.md'
$installerDefinition = Join-Path $repositoryRoot 'packaging\UnrealRevived.iss'

foreach ($requiredPath in @($hostManifestPath, $contentManifestPath, $PatchArchive, $RendererDll, $LoaderDll, $OpenXRNotice, $InputDll, $rendererInt, $modernMenu, $oldWeapons, $installScript, $copyScript, $backupScript, $brandingLogo, $brandingSetupLogo, $installerWizardImage, $brandingIcon, $iniModule, $permissions)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Missing offline package input: $requiredPath"
    }
}
Import-Module $iniModule -Force

$brandingIconHash = (Get-FileHash -LiteralPath $brandingIcon -Algorithm SHA256).Hash.ToLowerInvariant()
$installedBrandingIconName = "UnrealRevived-Icon-$($brandingIconHash.Substring(0, 12)).ico"

$hostManifest = Get-Content -LiteralPath $hostManifestPath -Raw | ConvertFrom-Json
$archiveHash = Assert-UnrealRevivedFileIntegrity -Path $PatchArchive `
    -ExpectedSize $hostManifest.release.runtime.size `
    -ExpectedSha256 $hostManifest.release.runtime.sha256 `
    -Description 'Pinned patch archive'

$stagePath = [IO.Path]::GetFullPath($StageRoot)
$stagePathRoot = [IO.Path]::GetPathRoot($stagePath).TrimEnd('\')
$normalizedStagePath = $stagePath.TrimEnd('\')
$repositoryPath = [IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\')
if ($normalizedStagePath -eq $stagePathRoot) {
    throw 'StageRoot must not be a filesystem root.'
}
if ($normalizedStagePath -eq $repositoryPath -or
    $repositoryPath.StartsWith("$normalizedStagePath\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'StageRoot must not be the repository root or one of its parent directories.'
}

if (Test-Path -LiteralPath $stagePath) {
    Remove-Item -LiteralPath $stagePath -Recurse -Force
}
$payloadRoot = Join-Path $stagePath 'payload'
$patchRoot = Join-Path $stagePath 'patch'
$outputRoot = Join-Path $stagePath 'output'
New-Item -ItemType Directory -Path $payloadRoot, $patchRoot, $outputRoot -Force | Out-Null
Copy-Item -LiteralPath $installerWizardImage -Destination (Join-Path $payloadRoot 'InstallerWizard.png') -Force

Write-Host 'Extracting the verified patch for direct Inno Setup packaging'
Expand-Archive -LiteralPath $PatchArchive -DestinationPath $patchRoot -Force
Assert-UnrealRevivedHostModules -HostRoot $patchRoot -HostManifest $hostManifest
Copy-Item -LiteralPath $brandingLogo -Destination (Join-Path $patchRoot 'Help\Logo.bmp') -Force
Copy-Item -LiteralPath $brandingSetupLogo -Destination (Join-Path $patchRoot 'Help\SetupLogo.bmp') -Force
$stagedBrandingRoot = Join-Path $patchRoot 'UnrealRevived'
New-Item -ItemType Directory -Path $stagedBrandingRoot -Force | Out-Null
Copy-Item -LiteralPath $brandingIcon -Destination (Join-Path $stagedBrandingRoot $installedBrandingIconName) -Force

& (Join-Path $PSScriptRoot 'install-project-localization.ps1') -GameRoot $patchRoot

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
        $localizedLines = Set-UnrealRevivedStartupLocalization $localizedLines
        Set-Content -LiteralPath $startupFile.FullName -Value $localizedLines -Encoding UTF8
    }
}

foreach ($defaultProfile in @('System\Default.ini', 'System64\Default.ini')) {
    $defaultProfilePath = Join-Path $patchRoot $defaultProfile
    $defaultProfileLines = Get-Content -LiteralPath $defaultProfilePath
    $defaultProfileLines = Remove-UnrealRevivedIniValue $defaultProfileLines 'URL' 'EntryMap' 'EntryIII.unr'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'URL' 'LocalMap' 'Unreal.unr?Game=ModernMenu.ModernIntro'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'URL' 'AltLocalMap' 'Unreal.unr?Game=ModernMenu.ModernIntro'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'FirstRun' 'FirstRun' '227'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'Engine.Engine' 'GameRenderDevice' 'D3D12Drv.D3D12RenderDevice'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'Engine.Engine' 'WindowedRenderDevice' 'D3D12Drv.D3D12RenderDevice'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'Engine.Engine' 'Console' 'ModernMenu.ModernConsole'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'UMenu.UnrealConsole' 'RootWindow' 'ModernMenu.ModernRootWindow'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'UMenu.UMenuMenuBar' 'OptionsUMenuDefault' 'ModernMenu.ModernOptionsMenu'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'UMenu.UMenuMenuBar' 'GameUMenuDefault' 'ModernMenu.ModernGameMenu'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'ModernMenu.ModernOptionsClientWindow' 'RestartIni' 'Unreal.ini'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'ModernMenu.ModernOptionsClientWindow' 'RestartUserIni' 'User.ini'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'Engine.GameInfo' 'bUseRealtimeShadow' 'False'
    $defaultProfileLines = Add-UnrealRevivedIniValue $defaultProfileLines 'Editor.EditorEngine' 'EditPackages' 'ModernMenu'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'WinDrv.WindowsClient' 'UseJoystick' 'True'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'WinDrv.WindowsClient' 'ScaleXYZ' '100.000000'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'WinDrv.WindowsClient' 'ScaleRUV' '100.000000'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'WinDrv.WindowsClient' 'InvertVertical' 'True'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'WinDrv.WindowsClient' 'UseRawHIDInput' 'True'
    $defaultProfileLines = Copy-UnrealRevivedIniSection $defaultProfileLines 'WinDrv.WindowsClient' 'XInputWinDrv.WindowsClient'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'Engine.Engine' 'ViewportManager' 'XInputWinDrv.WindowsClient'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'UseJoystick' 'True'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'UseXInput' 'True'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'XInputFallbackToWinMM' 'True'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'XInputControllerIndex' '-1'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'DeadZoneXYZ' 'True'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'DeadZoneRUV' 'True'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'LeftStickDeadZonePercent' '25.000000'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'RightStickDeadZonePercent' '25.000000'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'ScaleXYZ' '100.000000'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'ScaleRUV' '100.000000'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'InvertVertical' 'True'
    $defaultProfileLines = Set-UnrealRevivedIniValue $defaultProfileLines 'XInputWinDrv.WindowsClient' 'UseRawHIDInput' 'True'
    $defaultProfileLines = Set-UnrealRevivedVideoDefaults $defaultProfileLines
    Set-Content -LiteralPath $defaultProfilePath -Value $defaultProfileLines -Encoding ASCII
}

foreach ($defaultUserProfile in @('System\DefUser.ini', 'System64\DefUser.ini')) {
    $defaultUserProfilePath = Join-Path $patchRoot $defaultUserProfile
    $defaultUserProfileLines = Get-Content -LiteralPath $defaultUserProfilePath
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'MiddleMouse' ''
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'NumPadPeriod' ''
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'GreyPlus' ''
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Shift' ''
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Ctrl' 'Duck'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'C' 'Duck'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy1' 'Jump'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy2' ''
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy3' 'InventoryActivate'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy4' 'InventoryNext'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy5' 'PrevWeapon'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy6' 'NextWeapon'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy7' 'InventoryPrevious'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy8' ''
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy9' 'Duck'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy10' 'RecenterVR'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'F10' 'RecenterVR'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy11' 'Fire'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'Joy12' 'AltFire'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'JoyX' 'Axis aStrafe speed=2'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'JoyY' 'Axis aBaseY speed=2'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'JoyZ' ''
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'JoyR' ''
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'JoyU' 'Axis aturn speed=5.9'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.Input' 'JoyV' 'Axis aLookUp speed=-3'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.PlayerPawn' 'MouseSensitivity' '3.000000'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.PlayerPawn' 'bMouseSmoothing' 'False'
    $defaultUserProfileLines = Set-UnrealRevivedIniValue $defaultUserProfileLines 'Engine.PlayerPawn' 'bInvertMouse' 'False'
    $defaultUserProfileLines = Set-UnrealRevivedUserVideoDefaults $defaultUserProfileLines
    Set-Content -LiteralPath $defaultUserProfilePath -Value $defaultUserProfileLines -Encoding ASCII
}

& (Join-Path $PSScriptRoot 'stage-branded-launchers.ps1') -RuntimeRoot $patchRoot -BinaryRoot $LauncherBinaryRoot -SdkRoot $SdkRoot

$payloadSources = [ordered]@{
    'UnrealRevived.exe' = Join-Path $LauncherBinaryRoot 'UnrealRevived.exe'
    'UnrealRevivedVR.exe' = Join-Path $LauncherBinaryRoot 'UnrealRevivedVR.exe'
    'D3D12Drv.dll' = $RendererDll
    'D3D12Drv.int' = $rendererInt
    'openxr_loader.dll' = $LoaderDll
    'OPENXR-COPYING.adoc' = $OpenXRNotice
    'XInputWinDrv.dll' = $InputDll
    'ModernMenu.u' = $modernMenu
    'OldWeapons.u' = $oldWeapons
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
    sourceDirty = [bool](& git -C $repositoryRoot status --porcelain)
    brandingIconName = $installedBrandingIconName
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

& $isccPath "/DStageRoot=$stagePath" "/DOutputDir=$outputRoot" "/DProductIconName=$installedBrandingIconName" $installerDefinition
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

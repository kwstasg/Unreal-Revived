param(
    [Parameter(Mandatory = $true)]
    [string] $InstallRoot,

    [Parameter(Mandatory = $true)]
    [string] $PayloadRoot,

    [Parameter(Mandatory = $true)]
    [string] $OriginalGameRoot
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force

$payloadManifestPath = Join-Path $PayloadRoot 'payload-manifest.json'
$rendererDll = Join-Path $PayloadRoot 'D3D12Drv.dll'
$rendererInt = Join-Path $PayloadRoot 'D3D12Drv.int'
$inputDll = Join-Path $PayloadRoot 'XInputWinDrv.dll'
$modernMenu = Join-Path $PayloadRoot 'ModernMenu.u'
$hostManifestPath = Join-Path $PayloadRoot 'unreal-gold-227k_15-win64.json'
$backupScript = Join-Path $PayloadRoot 'backup-unreal-revived-user-data.ps1'
$permissions = Join-Path $PayloadRoot 'PERMISSIONS.md'

foreach ($requiredPath in @($payloadManifestPath, $rendererDll, $rendererInt, $inputDll, $modernMenu, $hostManifestPath, $backupScript, $permissions)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Installer payload is incomplete: $requiredPath"
    }
}

$payloadManifest = Get-Content -LiteralPath $payloadManifestPath -Raw | ConvertFrom-Json
foreach ($file in $payloadManifest.files) {
    $path = Join-Path $PayloadRoot $file.path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Installer payload file is missing: $($file.path)"
    }
    $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($actualHash -ne $file.sha256) {
        throw "Installer payload hash mismatch: $($file.path)"
    }
}

$destinationRoot = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')
$installMarker = Join-Path $destinationRoot '.unreal-revived.json'

$systemDirectory = Join-Path $destinationRoot 'System'
$system64Directory = Join-Path $destinationRoot 'System64'
foreach ($requiredDirectory in @($systemDirectory, $system64Directory)) {
    if (-not (Test-Path -LiteralPath $requiredDirectory -PathType Container)) {
        throw "The patched installation is missing $requiredDirectory"
    }
}
if (-not $payloadManifest.brandingIconName) {
    throw 'Installer payload does not identify its bundled Unreal Revived icon.'
}
$revivedIcon = Join-Path $destinationRoot "UnrealRevived\$($payloadManifest.brandingIconName)"
if (-not (Test-Path -LiteralPath $revivedIcon -PathType Leaf)) {
    throw "The bundled Unreal Revived icon is missing: $revivedIcon"
}

Copy-Item -LiteralPath $rendererDll -Destination (Join-Path $system64Directory 'D3D12Drv.dll') -Force
Copy-Item -LiteralPath $rendererInt -Destination (Join-Path $system64Directory 'D3D12Drv.int') -Force
Copy-Item -LiteralPath $inputDll -Destination (Join-Path $system64Directory 'XInputWinDrv.dll') -Force
Copy-Item -LiteralPath $modernMenu -Destination (Join-Path $system64Directory 'ModernMenu.u') -Force

$localizedDirectory = Join-Path $destinationRoot 'SystemLocalized\int'
foreach ($name in @('UnrealShare.int', 'UPak.int')) {
    $source = Join-Path $localizedDirectory $name
    if (Test-Path -LiteralPath $source -PathType Leaf) {
        Copy-Item -LiteralPath $source -Destination (Join-Path $systemDirectory $name) -Force
    }
}
$startupSource = Join-Path $localizedDirectory 'Startup.int'
if (Test-Path -LiteralPath $startupSource -PathType Leaf) {
    Copy-Item -LiteralPath $startupSource -Destination (Join-Path $systemDirectory 'Startup.int') -Force
    Copy-Item -LiteralPath $startupSource -Destination (Join-Path $system64Directory 'Startup.int') -Force
}

$defaultIni = Join-Path $system64Directory 'Default.ini'
$defaultUserIni = Join-Path $system64Directory 'DefUser.ini'
if (-not (Test-Path -LiteralPath $defaultIni -PathType Leaf) -or -not (Test-Path -LiteralPath $defaultUserIni -PathType Leaf)) {
    throw 'The bundled patch did not provide the expected x64 default profiles.'
}

$iniLines = Get-Content -LiteralPath $defaultIni
$iniLines = Remove-UnrealRevivedIniValue $iniLines 'URL' 'EntryMap' 'EntryIII.unr'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'FirstRun' 'FirstRun' '227'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'GameRenderDevice' 'D3D12Drv.D3D12RenderDevice'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'WindowedRenderDevice' 'D3D12Drv.D3D12RenderDevice'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'Console' 'ModernMenu.ModernConsole'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'UMenu.UnrealConsole' 'RootWindow' 'ModernMenu.ModernRootWindow'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'UMenu.UMenuMenuBar' 'OptionsUMenuDefault' 'ModernMenu.ModernOptionsMenu'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernOptionsClientWindow' 'RestartIni' 'UnrealRevived.ini'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernOptionsClientWindow' 'RestartUserIni' 'UnrealRevivedUser.ini'
$iniLines = Add-UnrealRevivedIniValue $iniLines 'Editor.EditorEngine' 'EditPackages' 'ModernMenu'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'FullscreenViewportX' '1920'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'FullscreenViewportY' '1080'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'StartupFullscreen' 'True'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'StartupBorderless' 'False'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'TextureDetail' 'High'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'SkinDetail' 'High'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'Brightness' '0.550000'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'MinDesiredFrameRate' '60.000000'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'Decals' 'True'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'NoDynamicLights' 'False'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'LightMapLOD' '8'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'WinDrv.WindowsClient' 'SkyBoxFogMode' 'FOGDETAIL_High'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'UMenu.UMenuRootWindow' 'LookAndFeelClass' 'UMenu.UMenuMetalLookAndFeel'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernRootWindow' 'ConfiguredGUIScale' '1.500000'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernRootWindow' 'AutoGUIScale' 'False'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernVideoClientWindow' 'bShowFPS' 'False'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernVideoClientWindow' 'SavedContrastPercent' '100'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.LevelInfo' 'bDisableSpeclarLight' 'False'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.PlayerPawn' 'NetSpeed' '50000'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'D3D12Drv.D3D12RenderDevice' 'AntialiasMode' 'MSAA_4x'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'D3D12Drv.D3D12RenderDevice' 'Bloom' 'True'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'D3D12Drv.D3D12RenderDevice' 'BloomAmount' '165'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'D3D12Drv.D3D12RenderDevice' 'Contrast' '128'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'D3D12Drv.D3D12RenderDevice' 'Saturation' '280'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'D3D12Drv.D3D12RenderDevice' 'UseVSync' 'False'
$iniLines = Copy-UnrealRevivedIniSection $iniLines 'WinDrv.WindowsClient' 'XInputWinDrv.WindowsClient'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'ViewportManager' 'XInputWinDrv.WindowsClient'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'UseJoystick' 'True'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'UseXInput' 'True'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'XInputFallbackToWinMM' 'True'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'XInputControllerIndex' '-1'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'DeadZoneXYZ' 'True'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'DeadZoneRUV' 'True'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'ScaleXYZ' '85.000000'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'ScaleRUV' '85.000000'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'InvertVertical' 'True'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'UseRawHIDInput' 'True'
Set-Content -LiteralPath (Join-Path $system64Directory 'UnrealRevived.ini') -Value $iniLines -Encoding ASCII
$userIniLines = Get-Content -LiteralPath $defaultUserIni
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'F11' 'ToggleFPSStatistics'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy1' 'Jump'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy2' 'Duck'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy3' 'InventoryActivate'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy4' 'InventoryNext'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy5' 'PrevWeapon'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy6' 'NextWeapon'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy7' 'InventoryPrevious'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy8' ''
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy9' 'Duck'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy10' ''
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy11' 'Fire'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy12' 'AltFire'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyX' ''
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyY' ''
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyZ' 'Axis aStrafe speed=2'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyR' 'Axis aForward speed=2'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyU' 'Axis aturn speed=5.9'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyV' 'Axis aLookUp speed=-3'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'NetSpeed' '50000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'LanSpeed' '20000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'MainFOV' '90.000000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'bNoFlash' 'False'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'bAlwaysMouseLook' 'True'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'MouseSensitivity' '3.000000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'bMouseSmoothing' 'True'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'bInvertMouse' 'True'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.GameInfo' 'bCastShadow' 'True'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.GameInfo' 'bDecoShadows' 'True'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.GameInfo' 'bUseRealtimeShadow' 'True'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PawnShadow' 'ShadowDetailRes' '1024'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.ObjectShadow' 'OcclusionDistance' '0.000000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.HUD' 'HudMode' '0'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.HUD' 'Crosshair' '0'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.HUD' 'HudScaler' '1.500000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.HUD' 'CrosshairScale' '1.500000'
Set-Content -LiteralPath $defaultUserIni -Value $userIniLines -Encoding ASCII
Set-Content -LiteralPath (Join-Path $system64Directory 'UnrealRevivedUser.ini') -Value $userIniLines -Encoding ASCII

$installedModules = @{}
$hostManifest = Get-Content -LiteralPath $hostManifestPath -Raw | ConvertFrom-Json
foreach ($name in @('Core.dll', 'Engine.dll', 'Render.dll', 'Unreal.exe', 'WinDrv.dll')) {
    $path = Join-Path $system64Directory $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Patched x64 module is missing: $name"
    }
    $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    $expectedHash = $hostManifest.modules.$name
    if ($actualHash -ne $expectedHash) {
        throw "Patched x64 module hash mismatch for $name. Expected $expectedHash, got $actualHash."
    }
    $installedModules[$name] = $actualHash
}
$installedModules['XInputWinDrv.dll'] = (Get-FileHash -LiteralPath (Join-Path $system64Directory 'XInputWinDrv.dll') -Algorithm SHA256).Hash

$revivedDirectory = Join-Path $destinationRoot 'UnrealRevived'
New-Item -ItemType Directory -Path $revivedDirectory -Force | Out-Null
foreach ($name in @('backup-unreal-revived-user-data.ps1', 'PERMISSIONS.md', 'payload-manifest.json', 'unreal-gold-227k_15-win64.json')) {
    Copy-Item -LiteralPath (Join-Path $PayloadRoot $name) -Destination (Join-Path $revivedDirectory $name) -Force
}

$installRecord = [ordered]@{
    schema = 1
    installedAtUtc = [DateTime]::UtcNow.ToString('o')
    originalGameSource = [IO.Path]::GetFullPath($OriginalGameRoot).TrimEnd('\')
    patchArchiveSha256 = $payloadManifest.patch.archiveSha256
    payload = $payloadManifest
    modules = $installedModules
}
$installRecord | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $installMarker -Encoding UTF8

Write-Host "Unreal Revived installed successfully at $destinationRoot"
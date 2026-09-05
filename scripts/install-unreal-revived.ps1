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

$canonicalIni = Join-Path $system64Directory 'Unreal.ini'
$canonicalUserIni = Join-Path $system64Directory 'User.ini'

$defaultIniLines = Get-Content -LiteralPath $defaultIni
$defaultIniLines = Remove-UnrealRevivedIniValue $defaultIniLines 'URL' 'EntryMap' 'EntryIII.unr'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'URL' 'LocalMap' 'Unreal.unr?Game=ModernMenu.ModernIntro'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'URL' 'AltLocalMap' 'Unreal.unr?Game=ModernMenu.ModernIntro'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'FirstRun' 'FirstRun' '227'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'Engine.Engine' 'GameRenderDevice' 'D3D12Drv.D3D12RenderDevice'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'Engine.Engine' 'WindowedRenderDevice' 'D3D12Drv.D3D12RenderDevice'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'Engine.Engine' 'Console' 'ModernMenu.ModernConsole'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'UMenu.UnrealConsole' 'RootWindow' 'ModernMenu.ModernRootWindow'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'UMenu.UMenuMenuBar' 'OptionsUMenuDefault' 'ModernMenu.ModernOptionsMenu'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'ModernMenu.ModernOptionsClientWindow' 'RestartIni' 'Unreal.ini'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'ModernMenu.ModernOptionsClientWindow' 'RestartUserIni' 'User.ini'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'ModernMenu.ModernHUDConfigCW' 'bShowGameBehindMenus' 'True'
$defaultIniLines = Add-UnrealRevivedIniValue $defaultIniLines 'Editor.EditorEngine' 'EditPackages' 'ModernMenu'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'FullscreenViewportX' '1920'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'FullscreenViewportY' '1080'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'StartupFullscreen' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'StartupBorderless' 'False'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'TextureDetail' 'High'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'SkinDetail' 'High'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'Brightness' '0.550000'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'MinDesiredFrameRate' '60.000000'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'Decals' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'NoDynamicLights' 'False'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'LightMapLOD' '8'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'SkyBoxFogMode' 'FOGDETAIL_High'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'UseJoystick' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'ScaleXYZ' '100.000000'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'ScaleRUV' '100.000000'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'InvertVertical' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'WinDrv.WindowsClient' 'UseRawHIDInput' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'UMenu.UMenuRootWindow' 'LookAndFeelClass' 'UMenu.UMenuMetalLookAndFeel'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'ModernMenu.ModernRootWindow' 'ConfiguredGUIScale' '1.500000'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'ModernMenu.ModernRootWindow' 'AutoGUIScale' 'False'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'ModernMenu.ModernVideoClientWindow' 'bShowFPS' 'False'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'ModernMenu.ModernVideoClientWindow' 'SavedContrastPercent' '100'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'Engine.LevelInfo' 'bDisableSpeclarLight' 'False'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'Engine.PlayerPawn' 'NetSpeed' '50000'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'Engine.GameInfo' 'bUseRealtimeShadow' 'False'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'D3D12Drv.D3D12RenderDevice' 'AntialiasMode' 'MSAA_4x'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'D3D12Drv.D3D12RenderDevice' 'Bloom' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'D3D12Drv.D3D12RenderDevice' 'BloomAmount' '165'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'D3D12Drv.D3D12RenderDevice' 'Contrast' '128'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'D3D12Drv.D3D12RenderDevice' 'Saturation' '280'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'D3D12Drv.D3D12RenderDevice' 'MaxAnisotropy' '8'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'D3D12Drv.D3D12RenderDevice' 'UseVSync' 'False'
$defaultIniLines = Copy-UnrealRevivedIniSection $defaultIniLines 'WinDrv.WindowsClient' 'XInputWinDrv.WindowsClient'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'Engine.Engine' 'ViewportManager' 'XInputWinDrv.WindowsClient'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'UseJoystick' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'UseXInput' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'XInputFallbackToWinMM' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'XInputControllerIndex' '-1'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'DeadZoneXYZ' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'DeadZoneRUV' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'LeftStickDeadZonePercent' '25.000000'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'RightStickDeadZonePercent' '25.000000'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'ScaleXYZ' '100.000000'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'ScaleRUV' '100.000000'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'InvertVertical' 'True'
$defaultIniLines = Set-UnrealRevivedIniValue $defaultIniLines 'XInputWinDrv.WindowsClient' 'UseRawHIDInput' 'True'
$defaultIniLines = Set-UnrealRevivedVideoDefaults $defaultIniLines
Set-Content -LiteralPath $defaultIni -Value $defaultIniLines -Encoding ASCII

if ((Test-Path -LiteralPath $canonicalIni -PathType Leaf) -and (Select-String -LiteralPath $canonicalIni -Pattern '^\[Engine\.Engine\]$' -Quiet)) {
    $iniLines = Get-Content -LiteralPath $canonicalIni
    $iniLines = Remove-UnrealRevivedIniValue $iniLines 'URL' 'EntryMap' 'EntryIII.unr'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'URL' 'LocalMap' 'Unreal.unr?Game=ModernMenu.ModernIntro'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'URL' 'AltLocalMap' 'Unreal.unr?Game=ModernMenu.ModernIntro'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'FirstRun' 'FirstRun' '227'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'GameRenderDevice' 'D3D12Drv.D3D12RenderDevice'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'WindowedRenderDevice' 'D3D12Drv.D3D12RenderDevice'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'Console' 'ModernMenu.ModernConsole'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'ViewportManager' 'XInputWinDrv.WindowsClient'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'UMenu.UnrealConsole' 'RootWindow' 'ModernMenu.ModernRootWindow'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'UMenu.UMenuMenuBar' 'OptionsUMenuDefault' 'ModernMenu.ModernOptionsMenu'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernOptionsClientWindow' 'RestartIni' 'Unreal.ini'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernOptionsClientWindow' 'RestartUserIni' 'User.ini'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.GameInfo' 'bUseRealtimeShadow' 'False'
    $iniLines = Add-UnrealRevivedIniValue $iniLines 'Editor.EditorEngine' 'EditPackages' 'ModernMenu'
    if (-not ($iniLines -contains '[XInputWinDrv.WindowsClient]')) {
        $iniLines = Copy-UnrealRevivedIniSection $iniLines 'WinDrv.WindowsClient' 'XInputWinDrv.WindowsClient'
    }
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'UseJoystick' 'True'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'UseXInput' 'True'
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'XInputWinDrv.WindowsClient' 'XInputFallbackToWinMM' 'True'
}
else {
    $iniLines = $defaultIniLines
}
Set-Content -LiteralPath $canonicalIni -Value $iniLines -Encoding ASCII
$userIniLines = Get-Content -LiteralPath $defaultUserIni
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'F11' 'ToggleFPSStatistics'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'MiddleMouse' ''
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'NumPadPeriod' ''
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'GreyPlus' ''
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Shift' ''
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Ctrl' 'Duck'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'C' 'Duck'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy1' 'Jump'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'Joy2' ''
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
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyX' 'Axis aStrafe speed=2'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyY' 'Axis aBaseY speed=2'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyZ' ''
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyR' ''
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyU' 'Axis aturn speed=5.9'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'JoyV' 'Axis aLookUp speed=-3'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'NetSpeed' '50000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'LanSpeed' '20000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'MainFOV' '90.000000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'bNoFlash' 'False'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'bAlwaysMouseLook' 'True'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'MouseSensitivity' '3.000000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'bMouseSmoothing' 'False'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PlayerPawn' 'bInvertMouse' 'False'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.GameInfo' 'bCastShadow' 'True'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.GameInfo' 'bDecoShadows' 'True'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.GameInfo' 'bUseRealtimeShadow' 'False'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.PawnShadow' 'ShadowDetailRes' '1024'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.ObjectShadow' 'OcclusionDistance' '0.000000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.HUD' 'HudMode' '0'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.HUD' 'Crosshair' '0'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.HUD' 'HudScaler' '1.500000'
$userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.HUD' 'CrosshairScale' '1.500000'
$userIniLines = Set-UnrealRevivedUserVideoDefaults $userIniLines
Set-Content -LiteralPath $defaultUserIni -Value $userIniLines -Encoding ASCII
if (-not (Test-Path -LiteralPath $canonicalUserIni -PathType Leaf)) {
    Set-Content -LiteralPath $canonicalUserIni -Value $userIniLines -Encoding ASCII
}

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

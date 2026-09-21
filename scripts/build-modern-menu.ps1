# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [Parameter(Mandatory = $true)]
    [string] $GameRoot,

    [string] $IniName = 'D3D12Test.ini',

    [string] $UserIniName = 'D3D12TestUser.ini',

    [switch] $Production
)

$ErrorActionPreference = 'Stop'

$GameRoot = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot $GameRoot
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourcePackageDirectory = Join-Path $repositoryRoot 'UnrealScript\ModernMenu'
$sourceDirectory = Join-Path $sourcePackageDirectory 'Classes'
$brandingDirectory = Join-Path $repositoryRoot 'branding'
$menuTextureDirectory = Join-Path $repositoryRoot 'branding\MenuTiles'
$introNvidiaTexture = Join-Path $brandingDirectory 'NvidiaIntroLogoRuntime.png'
$introRevivedTexture = Join-Path $brandingDirectory 'UnrealRevivedLogo.png'
$campaignLogoTexture = Join-Path $brandingDirectory 'UnrealRevivedCampaignLogoRuntime.png'
$aboutLogoTexture = Join-Path $brandingDirectory 'UnrealRevivedAboutLogoRuntime.png'
$brandingLogo = Join-Path $brandingDirectory 'Logo.bmp'
$brandingSetupLogo = Join-Path $brandingDirectory 'SetupLogo.bmp'
$systemDirectory = Join-Path $GameRoot 'System'
$system64Directory = Join-Path $GameRoot 'System64'
$helpDirectory = Join-Path $GameRoot 'Help'
$ucc = Join-Path $system64Directory 'UCC.exe'
$iniPath = Join-Path $system64Directory $IniName
$userIniPath = Join-Path $system64Directory $UserIniName
$editorIniPath = Join-Path $system64Directory 'Unreal.ini'
$runtimePackageDirectory = Join-Path $GameRoot 'ModernMenu'
$outputPackage = Join-Path $system64Directory 'ModernMenu.u'

foreach ($requiredPath in @($sourcePackageDirectory, $sourceDirectory, $menuTextureDirectory, $introNvidiaTexture, $introRevivedTexture, $campaignLogoTexture, $aboutLogoTexture, $brandingLogo, $brandingSetupLogo, $systemDirectory, $system64Directory, $helpDirectory, $ucc, $iniPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing ModernMenu build input: $requiredPath"
    }
}

$iniLines = Get-Content -LiteralPath $iniPath
$iniLines = Remove-UnrealRevivedIniValue $iniLines 'URL' 'EntryMap' 'EntryIII.unr'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'Engine.Engine' 'Console' 'ModernMenu.ModernConsole'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'UMenu.UnrealConsole' 'RootWindow' 'ModernMenu.ModernRootWindow'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'UMenu.UMenuMenuBar' 'OptionsUMenuDefault' 'ModernMenu.ModernOptionsMenu'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'UMenu.UMenuMenuBar' 'GameUMenuDefault' 'ModernMenu.ModernGameMenu'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernOptionsClientWindow' 'RestartIni' $IniName
$iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernOptionsClientWindow' 'RestartUserIni' $UserIniName
if (-not ($iniLines -match '^bShowFPS=')) {
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernVideoClientWindow' 'bShowFPS' 'False'
}
if (-not ($iniLines -match '^bShowGameBehindMenus=')) {
    $iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernHUDConfigCW' 'bShowGameBehindMenus' 'True'
}
$iniLines = Set-UnrealRevivedVideoDefaults $iniLines
$iniLines = Add-UnrealRevivedIniValue $iniLines 'Editor.EditorEngine' 'EditPackages' 'ModernMenu'
Set-Content -LiteralPath $iniPath -Value $iniLines -Encoding ASCII

if (Test-Path -LiteralPath $userIniPath -PathType Leaf) {
    $userIniLines = Get-Content -LiteralPath $userIniPath
    $userIniLines = Set-UnrealRevivedIniValue $userIniLines 'Engine.Input' 'F11' 'ToggleFPSStatistics'
    $userIniLines = Set-UnrealRevivedUserVideoDefaults $userIniLines
    Set-Content -LiteralPath $userIniPath -Value $userIniLines -Encoding ASCII
}

if (Test-Path -LiteralPath $editorIniPath -PathType Leaf) {
    $editorIniLines = Get-Content -LiteralPath $editorIniPath
    $editorIniLines = Set-UnrealRevivedIniValue $editorIniLines 'UMenu.UnrealConsole' 'RootWindow' 'ModernMenu.ModernRootWindow'
    $editorIniLines = Set-UnrealRevivedIniValue $editorIniLines 'UMenu.UMenuMenuBar' 'OptionsUMenuDefault' 'ModernMenu.ModernOptionsMenu'
    $editorIniLines = Set-UnrealRevivedIniValue $editorIniLines 'UMenu.UMenuMenuBar' 'GameUMenuDefault' 'ModernMenu.ModernGameMenu'
    $editorIniLines = Add-UnrealRevivedIniValue $editorIniLines 'Editor.EditorEngine' 'EditPackages' 'ModernMenu'
    Set-Content -LiteralPath $editorIniPath -Value $editorIniLines -Encoding ASCII
}

Remove-Item -LiteralPath $runtimePackageDirectory -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath $sourcePackageDirectory -Destination $runtimePackageDirectory -Recurse
if ($Production) {
    Get-ChildItem -LiteralPath (Join-Path $runtimePackageDirectory 'Classes') -Filter '*Test*.uc' -File |
        Remove-Item -Force
}
Copy-Item -LiteralPath $menuTextureDirectory -Destination (Join-Path $runtimePackageDirectory 'Textures') -Recurse
Copy-Item -LiteralPath $introNvidiaTexture -Destination (Join-Path $runtimePackageDirectory 'Textures\NvidiaIntroLogoRuntime.png') -Force
# Unreal requires power-of-two imports. Pack the complete source into the
# texture; ModernIntroHud restores its original 2168:725 aspect when drawing.
Add-Type -AssemblyName System.Drawing
$introSource = [Drawing.Image]::FromFile($introRevivedTexture)
$introTexture = New-Object Drawing.Bitmap(1024, 512, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$introGraphics = [Drawing.Graphics]::FromImage($introTexture)
try {
    $introGraphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $introGraphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $introGraphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $introGraphics.DrawImage($introSource, 0, 0, 1024, 512)
    $introTexture.Save((Join-Path $runtimePackageDirectory 'Textures\UnrealRevivedLogo.png'), [Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $introGraphics.Dispose()
    $introTexture.Dispose()
    $introSource.Dispose()
}
Copy-Item -LiteralPath $campaignLogoTexture -Destination (Join-Path $runtimePackageDirectory 'Textures\UnrealRevivedCampaignLogoRuntime.png') -Force
Copy-Item -LiteralPath $aboutLogoTexture -Destination (Join-Path $runtimePackageDirectory 'Textures\UnrealRevivedAboutLogoRuntime.png') -Force

$stagedPackages = [Collections.Generic.List[string]]::new()
try {
    foreach ($package in Get-ChildItem -LiteralPath $systemDirectory -Filter '*.u') {
        $destination = Join-Path $system64Directory $package.Name
        if (-not (Test-Path -LiteralPath $destination)) {
            Copy-Item -LiteralPath $package.FullName -Destination $destination
            $stagedPackages.Add($destination)
        }
    }

    Remove-Item -LiteralPath $outputPackage -Force -ErrorAction SilentlyContinue
    Push-Location $system64Directory
    try {
        & $ucc make -silent "ini=$IniName"
        if ($LASTEXITCODE -ne 0) {
            throw "UCC failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}
finally {
    foreach ($package in $stagedPackages) {
        Remove-Item -LiteralPath $package -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $outputPackage)) {
    throw "UCC did not produce $outputPackage"
}

if ($Production) {
    $packageContents = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($outputPackage))
    foreach ($fixture in Get-ChildItem -LiteralPath $sourceDirectory -Filter '*Test*.uc' -File) {
        if ($packageContents.Contains($fixture.BaseName)) {
            throw "Production package contains test fixture: $($fixture.BaseName)"
        }
    }
    Write-Host 'Production ModernMenu verified: no test fixture names in compiled package'
}

Copy-Item -LiteralPath $brandingLogo -Destination (Join-Path $helpDirectory 'Logo.bmp') -Force
# Seed optional weapon tuning once; never overwrite the user's calibration.
$weaponTuningPath = Join-Path $system64Directory 'ModernVRWeapons.ini'
if (-not (Test-Path -LiteralPath $weaponTuningPath)) {
    Copy-Item -LiteralPath (Join-Path $sourcePackageDirectory 'Config\ModernVRWeapons.ini') -Destination $weaponTuningPath
}
Copy-Item -LiteralPath $brandingSetupLogo -Destination (Join-Path $helpDirectory 'SetupLogo.bmp') -Force
& (Join-Path $PSScriptRoot 'install-project-localization.ps1') -GameRoot $GameRoot
& (Join-Path $PSScriptRoot 'install-development-shortcuts.ps1') -GameRoot $GameRoot

Write-Host "ModernMenu deployed to $outputPackage"

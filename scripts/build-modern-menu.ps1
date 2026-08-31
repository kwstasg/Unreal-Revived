param(
    [Parameter(Mandatory = $true)]
    [string] $GameRoot,

    [string] $IniName = 'D3D12Test.ini',

    [string] $UserIniName = 'D3D12TestUser.ini'
)

$ErrorActionPreference = 'Stop'

$null = & (Join-Path $PSScriptRoot 'assert-development-runtime.ps1') -GameRoot $GameRoot
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourcePackageDirectory = Join-Path $repositoryRoot 'UnrealScript\ModernMenu'
$sourceDirectory = Join-Path $sourcePackageDirectory 'Classes'
$brandingDirectory = Join-Path $repositoryRoot 'branding'
$menuTextureDirectory = Join-Path $repositoryRoot 'branding\MenuTiles'
$brandingLogo = Join-Path $brandingDirectory 'Logo.bmp'
$brandingSetupLogo = Join-Path $brandingDirectory 'SetupLogo.bmp'
$systemDirectory = Join-Path $GameRoot 'System'
$system64Directory = Join-Path $GameRoot 'System64'
$helpDirectory = Join-Path $GameRoot 'Help'
$ucc = Join-Path $system64Directory 'UCC.exe'
$iniPath = Join-Path $system64Directory $IniName
$runtimePackageDirectory = Join-Path $GameRoot 'ModernMenu'
$outputPackage = Join-Path $system64Directory 'ModernMenu.u'

foreach ($requiredPath in @($sourcePackageDirectory, $sourceDirectory, $menuTextureDirectory, $brandingLogo, $brandingSetupLogo, $systemDirectory, $system64Directory, $helpDirectory, $ucc, $iniPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing ModernMenu build input: $requiredPath"
    }
}

$iniLines = Get-Content -LiteralPath $iniPath
$iniLines = Set-UnrealRevivedIniValue $iniLines 'UMenu.UnrealConsole' 'RootWindow' 'ModernMenu.ModernRootWindow'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'UMenu.UMenuMenuBar' 'OptionsUMenuDefault' 'ModernMenu.ModernOptionsMenu'
$iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernOptionsClientWindow' 'RestartIni' $IniName
$iniLines = Set-UnrealRevivedIniValue $iniLines 'ModernMenu.ModernOptionsClientWindow' 'RestartUserIni' $UserIniName
$iniLines = Add-UnrealRevivedIniValue $iniLines 'Editor.EditorEngine' 'EditPackages' 'ModernMenu'
Set-Content -LiteralPath $iniPath -Value $iniLines -Encoding ASCII

Remove-Item -LiteralPath $runtimePackageDirectory -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath $sourcePackageDirectory -Destination $runtimePackageDirectory -Recurse
Copy-Item -LiteralPath $menuTextureDirectory -Destination (Join-Path $runtimePackageDirectory 'Textures') -Recurse

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

Copy-Item -LiteralPath $brandingLogo -Destination (Join-Path $helpDirectory 'Logo.bmp') -Force
Copy-Item -LiteralPath $brandingSetupLogo -Destination (Join-Path $helpDirectory 'SetupLogo.bmp') -Force
& (Join-Path $PSScriptRoot 'install-development-shortcuts.ps1') -GameRoot $GameRoot

Write-Host "ModernMenu deployed to $outputPackage"
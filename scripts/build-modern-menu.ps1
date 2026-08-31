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
$sourceDirectory = Join-Path $repositoryRoot 'UnrealScript\ModernMenu\Classes'
$systemDirectory = Join-Path $GameRoot 'System'
$system64Directory = Join-Path $GameRoot 'System64'
$ucc = Join-Path $system64Directory 'UCC.exe'
$iniPath = Join-Path $system64Directory $IniName
$runtimeSourceDirectory = Join-Path $GameRoot 'ModernMenu\Classes'
$outputPackage = Join-Path $system64Directory 'ModernMenu.u'

foreach ($requiredPath in @($sourceDirectory, $systemDirectory, $system64Directory, $ucc, $iniPath)) {
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

New-Item -ItemType Directory -Path $runtimeSourceDirectory -Force | Out-Null
Remove-Item -LiteralPath $runtimeSourceDirectory -Recurse -Force
Copy-Item -LiteralPath $sourceDirectory -Destination $runtimeSourceDirectory -Recurse

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

Write-Host "ModernMenu deployed to $outputPackage"
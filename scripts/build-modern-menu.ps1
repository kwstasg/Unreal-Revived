param(
    [Parameter(Mandatory = $true)]
    [string] $GameRoot,

    [string] $IniName = 'D3D12Test.ini'
)

$ErrorActionPreference = 'Stop'

function Set-IniValue {
    param(
        [string[]] $Lines,
        [string] $Section,
        [string] $Key,
        [string] $Value
    )

    $result = [Collections.Generic.List[string]]::new()
    $inSection = $false
    $sectionFound = $false
    $keyWritten = $false

    foreach ($line in $Lines) {
        if ($line -match '^\[(.+)\]$') {
            if ($inSection -and -not $keyWritten) {
                $result.Add("$Key=$Value")
                $keyWritten = $true
            }

            $inSection = $Matches[1] -eq $Section
            $sectionFound = $sectionFound -or $inSection
        }

        if ($inSection -and $line -match "^$([regex]::Escape($Key))=") {
            if (-not $keyWritten) {
                $result.Add("$Key=$Value")
                $keyWritten = $true
            }
            continue
        }

        $result.Add($line)
    }

    if (-not $sectionFound) {
        $result.Add('')
        $result.Add("[$Section]")
        $result.Add("$Key=$Value")
    }
    elseif ($inSection -and -not $keyWritten) {
        $result.Add("$Key=$Value")
    }

    return $result.ToArray()
}

function Add-IniValue {
    param(
        [string[]] $Lines,
        [string] $Section,
        [string] $Key,
        [string] $Value
    )

    $result = [Collections.Generic.List[string]]::new()
    $inSection = $false
    $sectionFound = $false
    $valueFound = $false

    foreach ($line in $Lines) {
        if ($line -match '^\[(.+)\]$') {
            if ($inSection -and -not $valueFound) {
                $result.Add("$Key=$Value")
                $valueFound = $true
            }

            $inSection = $Matches[1] -eq $Section
            $sectionFound = $sectionFound -or $inSection
        }

        if ($inSection -and $line -eq "$Key=$Value") {
            $valueFound = $true
        }

        $result.Add($line)
    }

    if (-not $sectionFound) {
        $result.Add('')
        $result.Add("[$Section]")
        $result.Add("$Key=$Value")
    }
    elseif ($inSection -and -not $valueFound) {
        $result.Add("$Key=$Value")
    }

    return $result.ToArray()
}

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
$iniLines = Set-IniValue $iniLines 'UMenu.UnrealConsole' 'RootWindow' 'ModernMenu.ModernRootWindow'
$iniLines = Set-IniValue $iniLines 'UMenu.UMenuMenuBar' 'OptionsUMenuDefault' 'ModernMenu.ModernOptionsMenu'
$iniLines = Add-IniValue $iniLines 'Editor.EditorEngine' 'EditPackages' 'ModernMenu'
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

    Remove-Item -LiteralPath $outputPackage -Force -ErrorAction Stop
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
param(
    [Parameter(Mandatory = $true)]
    [string] $GameRoot
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repositoryRoot 'Localization'
$destinationRoot = Join-Path ([IO.Path]::GetFullPath($GameRoot)) 'SystemLocalized'

function Get-PublicMetadataLines {
    param([string] $Path)

    $result = [Collections.Generic.List[string]]::new()
    $inPublic = $false
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\[(.+)\]$') {
            if ($inPublic) {
                break
            }
            $inPublic = $Matches[1] -ieq 'Public'
        }
        elseif ($inPublic -and $line -ne '' -and -not $line.StartsWith(';')) {
            $result.Add($line)
        }
    }
    return $result.ToArray()
}

function Get-LocalizationEntries {
    param([string] $Path)

    $section = ''
    $occurrences = @{}
    $entries = [ordered]@{}
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*\[([^]]+)\]\s*$') {
            $section = $Matches[1]
        }
        elseif ($line -match '^([^;\s][^=]*?)=(.*)$') {
            $name = $Matches[1].Trim()
            $baseKey = "$section`0$name"
            if (-not $occurrences.ContainsKey($baseKey)) {
                $occurrences[$baseKey] = 0
            }
            $entryKey = "$baseKey`0$($occurrences[$baseKey])"
            $occurrences[$baseKey]++
            $entries[$entryKey] = $Matches[2]
        }
    }
    return $entries
}

function Get-FormatTokens {
    param([string] $Value)

    return @([regex]::Matches($Value, '%(?:[-+0-9.]*[A-Za-z]+|%)') | ForEach-Object Value | Sort-Object)
}

$completeGreekCampaignFiles = @(
    'Abyss', 'Bluff', 'Ceremony', 'Chizra', 'Crashsite', 'Crashsite1', 'Crashsite2',
    'Dark', 'DasaCellars', 'DasaPass', 'DCrater', 'Dig', 'Dug', 'DuskFalls',
    'Eldora', 'End', 'Endgame', 'ExtremeBeg', 'ExtremeCore', 'ExtremeDark',
    'ExtremeDGen', 'ExtremeEnd', 'ExtremeGen', 'ExtremeLab', 'Foundry', 'Gateway',
    'Glacena', 'Glathriel1', 'Glathriel2', 'Harobed', 'Inter1', 'Inter2', 'Inter3',
    'Inter4', 'Inter5', 'Inter6', 'Inter7', 'Inter8', 'Inter9', 'Inter10', 'Inter11',
    'Inter12', 'Inter13', 'Inter14', 'InterCrashsite', 'InterIntro', 'Intro1', 'Intro2',
    'IsvDeck1', 'IsvKran4', 'IsvKran32', 'Nagomi', 'NagomiSun', 'NaliC', 'Nalic2',
    'NaliLord', 'Nevec', 'Noork', 'Nyleve', 'Passage', 'QueenEnd', 'Ruins',
    'SpireLand', 'SpireVillage', 'Terraniux', 'TheSunspire', 'Toxic', 'Trench',
    'Velora', 'Vortex2'
)

if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw "Project localization source is missing: $sourceRoot"
}

foreach ($languageDirectory in Get-ChildItem -LiteralPath $sourceRoot -Directory) {
    $coreFile = Join-Path $languageDirectory.FullName "Core.$($languageDirectory.Name)"
    if (-not (Test-Path -LiteralPath $coreFile -PathType Leaf)) {
        throw "Language '$($languageDirectory.Name)' has no Core registration file: $coreFile"
    }
    $coreBytes = [IO.File]::ReadAllBytes($coreFile)
    if ($coreBytes.Length -lt 3 -or $coreBytes[0] -ne 0xEF -or $coreBytes[1] -ne 0xBB -or $coreBytes[2] -ne 0xBF) {
        throw "Localization files containing non-ASCII text must be UTF-8 with BOM: $coreFile"
    }
    foreach ($localizedFile in Get-ChildItem -LiteralPath $languageDirectory.FullName -File) {
        $localizedBytes = [IO.File]::ReadAllBytes($localizedFile.FullName)
        if ($localizedBytes.Length -lt 3 -or $localizedBytes[0] -ne 0xEF -or $localizedBytes[1] -ne 0xBB -or $localizedBytes[2] -ne 0xBF) {
            throw "Localization files containing non-ASCII text must be UTF-8 with BOM: $($localizedFile.FullName)"
        }
        $englishFile = Join-Path $destinationRoot "int\$($localizedFile.BaseName).int"
        if (-not (Test-Path -LiteralPath $englishFile -PathType Leaf)) {
            continue
        }
        $englishEntries = Get-LocalizationEntries $englishFile
        $localizedEntries = Get-LocalizationEntries $localizedFile.FullName
        foreach ($entryKey in $localizedEntries.Keys) {
            if (-not $englishEntries.Contains($entryKey)) {
                throw "Localization key '$entryKey' has no English counterpart: $($localizedFile.FullName)"
            }
            $englishTokens = @(Get-FormatTokens $englishEntries[$entryKey])
            $localizedTokens = @(Get-FormatTokens $localizedEntries[$entryKey])
            if (Compare-Object $englishTokens $localizedTokens) {
                throw "Localization key '$entryKey' changes format placeholders: $($localizedFile.FullName)"
            }
        }
        if ($languageDirectory.Name -ieq 'elt' -and $localizedFile.BaseName -in $completeGreekCampaignFiles) {
            $missingEntries = @($englishEntries.Keys | Where-Object { -not $localizedEntries.Contains($_) })
            if ($missingEntries.Count -gt 0) {
                throw "Complete Greek campaign file omits $($missingEntries.Count) English key(s): $($localizedFile.FullName)"
            }
        }
        $englishPublic = @(Get-PublicMetadataLines $englishFile)
        if ($englishPublic.Count -eq 0) {
            continue
        }
        $localizedPublic = @(Get-PublicMetadataLines $localizedFile.FullName)
        $missingPublic = @($englishPublic | Where-Object { $_ -notin $localizedPublic })
        if ($missingPublic.Count -gt 0) {
            throw "Localization file omits required [Public] metadata from $englishFile`: $($localizedFile.FullName)"
        }
    }
    $destinationLanguage = Join-Path $destinationRoot $languageDirectory.Name
    New-Item -ItemType Directory -Path $destinationLanguage -Force | Out-Null
    Get-ChildItem -LiteralPath $languageDirectory.FullName -File | Copy-Item -Destination $destinationLanguage -Force

    foreach ($metadataName in @('UnrealShare', 'UPak')) {
        $metadataSource = Join-Path $languageDirectory.FullName "$metadataName.$($languageDirectory.Name)"
        if (Test-Path -LiteralPath $metadataSource -PathType Leaf) {
            Copy-Item -LiteralPath $metadataSource -Destination (Join-Path ([IO.Path]::GetFullPath($GameRoot)) "System\$metadataName.$($languageDirectory.Name)") -Force
        }
    }
}

# The original installer normally promotes the selected language's voiced
# intermission packages into Sounds/. Runtime language switching has no such
# installer step, so retain English voice audio as the fallback for languages
# (including Greek) that currently provide translated text only.
$englishAudioRoot = Join-Path ([IO.Path]::GetFullPath($GameRoot)) 'Sounds\int'
$audioRoot = Join-Path ([IO.Path]::GetFullPath($GameRoot)) 'Sounds'
if (Test-Path -LiteralPath $englishAudioRoot -PathType Container) {
    foreach ($audioFile in Get-ChildItem -LiteralPath $englishAudioRoot -File -Filter '*.uax') {
        $audioDestination = Join-Path $audioRoot $audioFile.Name
        if (-not (Test-Path -LiteralPath $audioDestination -PathType Leaf)) {
            Copy-Item -LiteralPath $audioFile.FullName -Destination $audioDestination
        }
    }
}

Write-Host "Installed project localization into $destinationRoot"

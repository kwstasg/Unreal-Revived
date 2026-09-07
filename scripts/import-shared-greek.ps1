# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [string]$GameRoot = (Join-Path $PSScriptRoot '..\local\game'),
    [string]$ReferenceRoot = (Join-Path $PSScriptRoot '..\local\reference\UnrealTournament-Localization'),
    [string]$DestinationRoot = (Join-Path $PSScriptRoot '..\Localization\elt'),
    [switch]$AllowChangedEnglish,
    [switch]$ReportChangedEnglish
)

$ErrorActionPreference = 'Stop'
$utf8Bom = [System.Text.UTF8Encoding]::new($true)
$packages = @('Core', 'Engine', 'UWindow', 'UMenu', 'UnrealI', 'UnrealShare')

function Read-IniEntries {
    param([Parameter(Mandatory)][string]$Path)

    $section = ''
    $occurrences = @{}
    $entries = @{}

    foreach ($line in [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Path))) {
        if ($line -match '^\s*\[([^]]+)\]\s*$') {
            $section = $Matches[1]
            continue
        }
        if ($line -notmatch '^([^;\s][^=]*?)=(.*)$') {
            continue
        }

        $name = $Matches[1].Trim()
        $value = $Matches[2]
        $baseKey = "$section`0$name"
        if (-not $occurrences.ContainsKey($baseKey)) {
            $occurrences[$baseKey] = 0
        }
        $occurrence = $occurrences[$baseKey]
        $occurrences[$baseKey]++
        $entries["$baseKey`0$occurrence"] = $value
    }

    return $entries
}

function Write-MergedFile {
    param(
        [Parameter(Mandatory)][string]$EnglishPath,
        [Parameter(Mandatory)][string]$ExistingGreekPath,
        [Parameter(Mandatory)][string]$ReferenceEnglishPath,
        [Parameter(Mandatory)][string]$ReferenceGreekPath,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $existingGreek = Read-IniEntries -Path $ExistingGreekPath
    $referenceEnglish = Read-IniEntries -Path $ReferenceEnglishPath
    $referenceGreek = Read-IniEntries -Path $ReferenceGreekPath
    $section = ''
    $occurrences = @{}
    $imported = 0
    $retained = 0
    $changed = 0
    $missing = 0
    $output = [System.Collections.Generic.List[string]]::new()
    $output.Add('; Unreal Revived')
    $output.Add('; Greek Translation Author: Kwstasg - Kostas Giannakakis')
    $output.Add('; Project: https://github.com/kwstasg/Unreal-Revived')
    $output.Add('')

    foreach ($line in [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $EnglishPath))) {
        if ($line -match '^\s*\[([^]]+)\]\s*$') {
            $section = $Matches[1]
            $output.Add($line)
            continue
        }
        if ($line -notmatch '^([^;\s][^=]*?)=(.*)$') {
            $output.Add($line)
            continue
        }

        $name = $Matches[1].Trim()
        $englishValue = $Matches[2]
        $baseKey = "$section`0$name"
        if (-not $occurrences.ContainsKey($baseKey)) {
            $occurrences[$baseKey] = 0
        }
        $occurrence = $occurrences[$baseKey]
        $occurrences[$baseKey]++
        $entryKey = "$baseKey`0$occurrence"

        if ($section -eq 'Public') {
            if ($existingGreek.ContainsKey($entryKey)) {
                $output.Add("$name=$($existingGreek[$entryKey])")
            } else {
                $output.Add($line)
            }
            continue
        }

        if ($existingGreek.ContainsKey($entryKey) -and $existingGreek[$entryKey] -ne $englishValue) {
            $output.Add("$name=$($existingGreek[$entryKey])")
            $retained++
        } elseif (
            $referenceEnglish.ContainsKey($entryKey) -and
            $referenceGreek.ContainsKey($entryKey) -and
            $referenceEnglish[$entryKey] -eq $englishValue -and
            $referenceGreek[$entryKey] -ne $englishValue
        ) {
            $output.Add("$name=$($referenceGreek[$entryKey])")
            $imported++
        } elseif (
            $referenceEnglish.ContainsKey($entryKey) -and
            $referenceGreek.ContainsKey($entryKey) -and
            $referenceGreek[$entryKey] -ne $referenceEnglish[$entryKey]
        ) {
            if ($ReportChangedEnglish) {
                Write-Host "[$([System.IO.Path]::GetFileNameWithoutExtension($OutputPath))][$section] $name"
                Write-Host "  Unreal: $englishValue"
                Write-Host "  UT:     $($referenceEnglish[$entryKey])"
                Write-Host "  Greek:  $($referenceGreek[$entryKey])"
            }
            if ($AllowChangedEnglish) {
                $output.Add("$name=$($referenceGreek[$entryKey])")
                $changed++
            } else {
                $output.Add($line)
                $missing++
            }
        } else {
            $output.Add($line)
            $missing++
        }
    }

    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $OutputPath)) | Out-Null
    [System.IO.File]::WriteAllText($OutputPath, (($output -join "`r`n") + "`r`n"), $utf8Bom)
    [pscustomobject]@{ Package = [System.IO.Path]::GetFileNameWithoutExtension($OutputPath); Imported = $imported; Retained = $retained; Changed = $changed; Missing = $missing }
}

$results = foreach ($package in $packages) {
    $paths = @{
        EnglishPath = Join-Path $GameRoot "SystemLocalized\int\$package.int"
        ExistingGreekPath = Join-Path $DestinationRoot "$package.elt"
        ReferenceEnglishPath = Join-Path $ReferenceRoot "int\$package.int"
        ReferenceGreekPath = Join-Path $ReferenceRoot "elt\$package.elt"
        OutputPath = Join-Path $DestinationRoot "$package.elt"
    }
    foreach ($path in $paths.Values) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required localization file is missing: $path"
        }
    }
    Write-MergedFile @paths
}

$results | Format-Table -AutoSize

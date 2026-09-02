function Set-UnrealRevivedIniValue {
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

function Add-UnrealRevivedIniValue {
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

function Remove-UnrealRevivedIniValue {
    param(
        [string[]] $Lines,
        [string] $Section,
        [string] $Key,
        [string] $Value
    )

    $result = [Collections.Generic.List[string]]::new()
    $inSection = $false

    foreach ($line in $Lines) {
        if ($line -match '^\[(.+)\]$') {
            $inSection = $Matches[1] -eq $Section
        }
        if ($inSection -and $line -eq "$Key=$Value") {
            continue
        }
        $result.Add($line)
    }
    return $result.ToArray()
}

function Copy-UnrealRevivedIniSection {
    param(
        [string[]] $Lines,
        [string] $SourceSection,
        [string] $DestinationSection
    )

    if ($SourceSection -eq $DestinationSection) {
        throw 'SourceSection and DestinationSection must be different.'
    }

    $sourceLines = [Collections.Generic.List[string]]::new()
    $inSource = $false
    $sourceFound = $false
    foreach ($line in $Lines) {
        if ($line -match '^\[(.+)\]$') {
            if ($inSource) {
                break
            }
            $inSource = $Matches[1] -eq $SourceSection
            $sourceFound = $sourceFound -or $inSource
            continue
        }
        if ($inSource) {
            $sourceLines.Add($line)
        }
    }
    if (-not $sourceFound) {
        throw "Could not find source INI section [$SourceSection]."
    }

    $result = [Collections.Generic.List[string]]::new()
    $inDestination = $false
    foreach ($line in $Lines) {
        if ($line -match '^\[(.+)\]$') {
            $inDestination = $Matches[1] -eq $DestinationSection
            if ($inDestination) {
                continue
            }
        }
        if (-not $inDestination) {
            $result.Add($line)
        }
    }

    if ($result.Count -gt 0 -and $result[$result.Count - 1] -ne '') {
        $result.Add('')
    }
    $result.Add("[$DestinationSection]")
    $result.AddRange($sourceLines)
    return $result.ToArray()
}

Export-ModuleMember -Function Set-UnrealRevivedIniValue, Add-UnrealRevivedIniValue, Remove-UnrealRevivedIniValue, Copy-UnrealRevivedIniSection
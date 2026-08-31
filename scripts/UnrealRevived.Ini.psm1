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

Export-ModuleMember -Function Set-UnrealRevivedIniValue, Add-UnrealRevivedIniValue
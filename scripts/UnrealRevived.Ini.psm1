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

function Set-UnrealRevivedVideoDefaults {
    param([string[]] $Lines)

    $result = $Lines
    foreach ($clientSection in @('WinDrv.WindowsClient', 'XInputWinDrv.WindowsClient')) {
        $result = Set-UnrealRevivedIniValue $result $clientSection 'FullscreenViewportX' '1920'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'FullscreenViewportY' '1080'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'StartupFullscreen' 'True'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'StartupBorderless' 'False'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'TextureDetail' 'High'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'SkinDetail' 'High'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'Brightness' '0.600000'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'MinDesiredFrameRate' '60.000000'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'Decals' 'True'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'NoDynamicLights' 'False'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'FlatShading' 'False'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'SkyBoxFogMode' 'FOGDETAIL_High'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'LightMapLOD' '8'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'UseHDTextures' 'True'
        $result = Set-UnrealRevivedIniValue $result $clientSection 'UseNoSmoothWorld' 'False'
    }

    $result = Set-UnrealRevivedIniValue $result 'UMenu.UMenuRootWindow' 'LookAndFeelClass' 'UMenu.UMenuMetalLookAndFeel'
    $result = Set-UnrealRevivedIniValue $result 'ModernMenu.ModernRootWindow' 'LookAndFeelClass' 'UMenu.UMenuMetalLookAndFeel'
    $result = Set-UnrealRevivedIniValue $result 'ModernMenu.ModernRootWindow' 'ConfiguredGUIScale' '1.500000'
    $result = Set-UnrealRevivedIniValue $result 'ModernMenu.ModernRootWindow' 'AutoGUIScale' 'False'
    $result = Set-UnrealRevivedIniValue $result 'ModernMenu.ModernVideoClientWindow' 'bShowFPS' 'True'
    $result = Set-UnrealRevivedIniValue $result 'ModernMenu.ModernVideoClientWindow' 'SavedContrastPercent' '100'
    $result = Set-UnrealRevivedIniValue $result 'Engine.LevelInfo' 'bDisableSpeclarLight' 'False'
    $result = Set-UnrealRevivedIniValue $result 'Engine.GameInfo' 'bCastShadow' 'True'
    $result = Set-UnrealRevivedIniValue $result 'Engine.GameInfo' 'bDecoShadows' 'True'
    $result = Set-UnrealRevivedIniValue $result 'Engine.GameInfo' 'bUseRealtimeShadow' 'False'

    $result = Set-UnrealRevivedIniValue $result 'D3D12Drv.D3D12RenderDevice' 'UseVSync' 'False'
    $result = Set-UnrealRevivedIniValue $result 'D3D12Drv.D3D12RenderDevice' 'UsePrecache' 'True'
    $result = Set-UnrealRevivedIniValue $result 'D3D12Drv.D3D12RenderDevice' 'AntialiasMode' 'MSAA_4x'
    $result = Set-UnrealRevivedIniValue $result 'D3D12Drv.D3D12RenderDevice' 'MaxAnisotropy' '4'
    $result = Set-UnrealRevivedIniValue $result 'D3D12Drv.D3D12RenderDevice' 'Bloom' 'True'
    $result = Set-UnrealRevivedIniValue $result 'D3D12Drv.D3D12RenderDevice' 'BloomAmount' '154'
    $result = Set-UnrealRevivedIniValue $result 'D3D12Drv.D3D12RenderDevice' 'Contrast' '128'
    $result = Set-UnrealRevivedIniValue $result 'D3D12Drv.D3D12RenderDevice' 'Saturation' '281'

    $result = Set-UnrealRevivedIniValue $result 'OpenGLDrv.OpenGLRenderDevice' 'UseVSync' 'Off'
    $result = Set-UnrealRevivedIniValue $result 'OpenGLDrv.OpenGLRenderDevice' 'UsePrecache' 'True'
    $result = Set-UnrealRevivedIniValue $result 'OpenGLDrv.OpenGLRenderDevice' 'UseTrilinear' 'False'
    $result = Set-UnrealRevivedIniValue $result 'OpenGLDrv.OpenGLRenderDevice' 'NoFiltering' 'False'
    $result = Set-UnrealRevivedIniValue $result 'OpenGLDrv.OpenGLRenderDevice' 'MaxAnisotropy' '4'
    $result = Set-UnrealRevivedIniValue $result 'OpenGLDrv.OpenGLRenderDevice' 'UseAA' 'True'
    $result = Set-UnrealRevivedIniValue $result 'OpenGLDrv.OpenGLRenderDevice' 'AntiAliasingMode' 'MSAA'
    $result = Set-UnrealRevivedIniValue $result 'OpenGLDrv.OpenGLRenderDevice' 'NumAASamples' '4'

    $result = Set-UnrealRevivedIniValue $result 'XOpenGLDrv.XOpenGLRenderDevice' 'UseVSync' 'Off'
    $result = Set-UnrealRevivedIniValue $result 'XOpenGLDrv.XOpenGLRenderDevice' 'UsePrecache' 'True'
    $result = Set-UnrealRevivedIniValue $result 'XOpenGLDrv.XOpenGLRenderDevice' 'UseTrilinear' 'False'
    $result = Set-UnrealRevivedIniValue $result 'XOpenGLDrv.XOpenGLRenderDevice' 'NoFiltering' 'False'
    $result = Set-UnrealRevivedIniValue $result 'XOpenGLDrv.XOpenGLRenderDevice' 'MaxAnisotropy' '4'
    $result = Set-UnrealRevivedIniValue $result 'XOpenGLDrv.XOpenGLRenderDevice' 'UseAA' 'True'
    $result = Set-UnrealRevivedIniValue $result 'XOpenGLDrv.XOpenGLRenderDevice' 'NumAASamples' '4'
    return $result
}

function Set-UnrealRevivedUserVideoDefaults {
    param([string[]] $Lines)

    $result = Set-UnrealRevivedIniValue $Lines 'Engine.PlayerPawn' 'MainFOV' '90.000000'
    $result = Set-UnrealRevivedIniValue $result 'Engine.PlayerPawn' 'bNoFlash' 'False'
    $result = Set-UnrealRevivedIniValue $result 'Engine.GameInfo' 'bCastShadow' 'True'
    $result = Set-UnrealRevivedIniValue $result 'Engine.GameInfo' 'bDecoShadows' 'True'
    $result = Set-UnrealRevivedIniValue $result 'Engine.GameInfo' 'bUseRealtimeShadow' 'False'
    $result = Set-UnrealRevivedIniValue $result 'Engine.PawnShadow' 'ShadowDetailRes' '256'
    $result = Set-UnrealRevivedIniValue $result 'Engine.ObjectShadow' 'OcclusionDistance' '8.000000'
    return $result
}

Export-ModuleMember -Function Set-UnrealRevivedIniValue, Add-UnrealRevivedIniValue, Remove-UnrealRevivedIniValue, Copy-UnrealRevivedIniSection, Set-UnrealRevivedVideoDefaults, Set-UnrealRevivedUserVideoDefaults

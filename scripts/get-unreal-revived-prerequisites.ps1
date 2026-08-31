param()

$ErrorActionPreference = 'Stop'

function Find-InnoSetupCompiler {
    $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    return @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
        'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
        'C:\Program Files\Inno Setup 6\ISCC.exe'
    ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}

function Find-VisualStudioCpp {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere -PathType Leaf)) {
        return $null
    }

    $installationPath = (& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $installationPath) {
        return $null
    }
    return $installationPath
}

$requirements = @(
    [ordered]@{ Name = 'Git'; Id = 'Git.Git'; Present = [bool](Get-Command git.exe -ErrorAction SilentlyContinue); Override = $null },
    [ordered]@{ Name = 'CMake'; Id = 'Kitware.CMake'; Present = [bool](Get-Command cmake.exe -ErrorAction SilentlyContinue); Override = $null },
    [ordered]@{ Name = 'Visual Studio 2022 C++ tools'; Id = 'Microsoft.VisualStudio.2022.BuildTools'; Present = [bool](Find-VisualStudioCpp); Override = '--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended' },
    [ordered]@{ Name = 'Inno Setup 6'; Id = 'JRSoftware.InnoSetup'; Present = [bool](Find-InnoSetupCompiler); Override = $null }
)

$missing = @($requirements | Where-Object { -not $_.Present })
if ($missing.Count -gt 0) {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw "Missing prerequisites ($($missing.Name -join ', ')) and winget is unavailable. Install App Installer, then rerun bootstrap."
    }

    foreach ($requirement in $missing) {
        Write-Host "Installing $($requirement.Name)"
        $arguments = @('install', '--id', $requirement.Id, '--exact', '--source', 'winget', '--accept-package-agreements', '--accept-source-agreements', '--silent')
        if ($requirement.Override) {
            $arguments += @('--override', $requirement.Override)
        }
        & $winget.Source @arguments
        if ($LASTEXITCODE -ne 0) {
            throw "winget could not install $($requirement.Name) (exit code $LASTEXITCODE)."
        }
    }
}

foreach ($path in @('C:\Program Files\CMake\bin', 'C:\Program Files\Git\cmd')) {
    if ((Test-Path -LiteralPath $path -PathType Container) -and $env:PATH -notlike "*$path*") {
        $env:PATH = "$path;$env:PATH"
    }
}

$unavailable = @()
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { $unavailable += 'Git' }
if (-not (Get-Command cmake.exe -ErrorAction SilentlyContinue)) { $unavailable += 'CMake' }
if (-not (Find-VisualStudioCpp)) { $unavailable += 'Visual Studio 2022 C++ tools' }
if (-not (Find-InnoSetupCompiler)) { $unavailable += 'Inno Setup 6' }
if ($unavailable.Count -gt 0) {
    throw "Prerequisite installation completed but these tools are still unavailable: $($unavailable -join ', '). Start a new terminal and rerun bootstrap."
}

Write-Host 'Unreal Revived development prerequisites are ready.'
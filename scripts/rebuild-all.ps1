# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

[CmdletBinding()]
param(
    [switch] $ShowOutput
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logRoot = Join-Path $repositoryRoot "local\logs\rebuild\$timestamp"
$logPath = Join-Path $logRoot 'rebuild.log'

function Invoke-LoggedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Label,

        [Parameter(Mandatory = $true)]
        [string] $FilePath,

        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $displayArguments = @($Arguments | ForEach-Object {
        if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ }
    })
    Add-Content -LiteralPath $logPath -Value "`r`n=== $Label ===`r`n$FilePath $($displayArguments -join ' ')"
    Write-Host "[$Label] Running..."

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if ($ShowOutput) {
            & $FilePath @Arguments 2>&1 | Tee-Object -LiteralPath $logPath -Append
        }
        else {
            & $FilePath @Arguments 2>&1 | Out-File -LiteralPath $logPath -Append -Encoding utf8
        }
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
        $stopwatch.Stop()
    }

    if ($exitCode -ne 0) {
        Write-Host "[$Label] Failed after $($stopwatch.Elapsed.ToString('hh\:mm\:ss'))." -ForegroundColor Red
        Write-Host "Last log lines from $logPath"
        Get-Content -LiteralPath $logPath -Tail 40
        throw "$Label failed with exit code $exitCode."
    }

    Write-Host "[$Label] Complete in $($stopwatch.Elapsed.ToString('hh\:mm\:ss'))." -ForegroundColor Green
}

New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
Push-Location $repositoryRoot
try {
    $requiredPaths = @(
        'PERMISSIONS.md'
        'local/game/.unreal-revived-development.json'
        'local/game/System64/Unreal.exe'
        'local/sdk/227k_15/Core/Inc/Core.h'
        'local/downloads/OldUnreal-UnrealPatch227k-Windows.zip'
        'local/downloads/OldUnreal-UnrealPatch227k-SDK-Windows.zip'
    )

    foreach ($requiredPath in $requiredPaths) {
        if (-not (Test-Path -LiteralPath $requiredPath)) {
            throw "Missing full-rebuild prerequisite: $requiredPath"
        }
    }

    if (Get-Process -Name Unreal -ErrorAction SilentlyContinue) {
        throw 'Unreal.exe must be closed before rebuilding.'
    }

    & git ls-files --error-unmatch -- PERMISSIONS.md 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'PERMISSIONS.md must be tracked before a full rebuild.'
    }

    Write-Host "Detailed output: $logPath"
    Write-Host 'This rebuild does not reset or clean source files.'

    if (Test-Path -LiteralPath 'local/build') {
        Write-Host '[Clean generated build tree] Running...'
        Remove-Item -LiteralPath 'local/build' -Recurse -Force
        Write-Host '[Clean generated build tree] Complete.' -ForegroundColor Green
    }

    Invoke-LoggedCommand -Label 'Configure CMake' -FilePath 'cmake' -Arguments @(
        '-S', '.', '-B', 'local/build', '-A', 'x64'
    )
    Invoke-LoggedCommand -Label 'Build native components' -FilePath 'cmake' -Arguments @(
        '--build', 'local/build', '--config', 'Release', '--parallel'
    )

    foreach ($target in @('deploy-d3d12drv', 'deploy-xinputwindrv', 'deploy-modern-menu')) {
        Invoke-LoggedCommand -Label "Deploy $target" -FilePath 'cmake' -Arguments @(
            '--build', 'local/build', '--target', $target, '--config', 'Release'
        )
    }

    Invoke-LoggedCommand -Label 'Build offline installer' -FilePath 'cmake' -Arguments @(
        '--build', 'local/build', '--target', 'package-offline-installer', '--config', 'Release'
    )
    Invoke-LoggedCommand -Label 'Build developer bundle' -FilePath 'powershell' -Arguments @(
        '-NoProfile', '-File', 'scripts/package-developer-bundle.ps1'
    )

    $artifacts = @(
        'local/build/D3D12Drv/Release/D3D12Drv.dll'
        'local/build/XInputWinDrv/Release/XInputWinDrv.dll'
        'local/game/System64/ModernMenu.u'
        'local/package/offline-installer/output/UnrealRevived-Setup-0.5.0.exe'
        'local/package/developer-bundle/UnrealRevived-DeveloperBundle-227k_15-v1.zip'
    )

    Write-Host '[Verify artifacts]'
    foreach ($artifact in $artifacts) {
        if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) {
            throw "Missing rebuilt artifact: $artifact"
        }
        $item = Get-Item -LiteralPath $artifact
        $hash = Get-FileHash -LiteralPath $artifact -Algorithm SHA256
        Write-Host ("  {0} | {1} bytes | {2}" -f $artifact, $item.Length, $hash.Hash)
    }

    Invoke-LoggedCommand -Label 'Repository guard' -FilePath 'powershell' -Arguments @(
        '-NoProfile', '-File', 'scripts/check-repository.ps1'
    )
    Invoke-LoggedCommand -Label 'Record Git status' -FilePath 'git' -Arguments @(
        'status', '--short', '--branch'
    )

    Write-Host 'Full Unreal Revived rebuild completed successfully.' -ForegroundColor Green
    Write-Host "Detailed output: $logPath"
}
finally {
    Pop-Location
}

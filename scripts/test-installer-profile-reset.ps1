# Exercise the real profile writer in a new disposable directory; no Setup or registry changes.
param([Parameter(Mandatory=$true)][string] $StageRoot)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$stage = [IO.Path]::GetFullPath($StageRoot)
$testBase = [IO.Path]::GetFullPath((Join-Path $repo 'local/tests'))
$root = [IO.Path]::GetFullPath((Join-Path $testBase ('profile-reset-' + [Guid]::NewGuid().ToString('N'))))
if (-not $root.StartsWith($testBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid test path' }
if (Test-Path -LiteralPath $root) { throw 'Test directory already exists' }
$system = Join-Path $root 'System64'
$payload = Join-Path $stage 'payload'
$manifest = Get-Content (Join-Path $payload 'payload-manifest.json') -Raw | ConvertFrom-Json
try {
    foreach ($directory in @('System','System64','UnrealRevived','Save')) {
        New-Item -ItemType Directory -Path (Join-Path $root $directory) | Out-Null
    }
    foreach ($name in @('Core.dll','Engine.dll','Render.dll','Unreal.exe','WinDrv.dll','Default.ini','DefUser.ini')) {
        Copy-Item -LiteralPath (Join-Path $stage "patch/System64/$name") -Destination $system
    }
    Copy-Item -LiteralPath (Join-Path $stage "patch/UnrealRevived/$($manifest.brandingIconName)") -Destination (Join-Path $root 'UnrealRevived')
    $save = Join-Path $root 'Save/retained-save.txt'
    Set-Content -LiteralPath $save -Value 'retained save sentinel' -Encoding ASCII
    $saveHash = (Get-FileHash $save).Hash
    & (Join-Path $PSScriptRoot 'install-unreal-revived.ps1') -InstallRoot $root -PayloadRoot $payload -OriginalGameRoot $root
    $profiles = @('Unreal.ini','UnrealVR.ini','User.ini','ModernVRWeapons.ini')
    $defaults = @{}
    foreach ($name in $profiles) {
        $path = Join-Path $system $name
        $defaults[$name] = (Get-FileHash $path).Hash
        Add-Content -LiteralPath $path -Value "`r`n[RetiredSetting]`r`nMarker=OldValue" -Encoding ASCII
    }
    & (Join-Path $PSScriptRoot 'install-unreal-revived.ps1') -InstallRoot $root -PayloadRoot $payload -OriginalGameRoot $root
    foreach ($name in $profiles) {
        if ((Get-FileHash (Join-Path $system $name)).Hash -ne $defaults[$name]) {
            throw "Installer did not reset $name to the fresh defaults"
        }
    }
    if ((Get-FileHash $save).Hash -ne $saveHash) { throw 'Installer changed retained saves' }
    Write-Host "PASS: four profiles reset to fresh defaults; save unchanged."
}
finally {
    if (Test-Path -LiteralPath $root) {
        $resolved = (Resolve-Path -LiteralPath $root).Path
        if (-not $resolved.StartsWith($testBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe cleanup path' }
        if (@(Get-ChildItem -LiteralPath $resolved -Recurse -Force -Attributes ReparsePoint).Count -gt 0) { throw 'Unexpected link in test directory' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

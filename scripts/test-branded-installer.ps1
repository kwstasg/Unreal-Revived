# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

# Compile the same Inno definition with /DValidationBuild first. Never runs the
# production installer or touches its registration, shortcuts or installation.
param(
    [Parameter(Mandatory = $true)][string] $Installer,
    [Parameter(Mandatory = $true)][string] $StageRoot,
    [Parameter(Mandatory = $true)][string] $TestRoot,
    [Parameter(Mandatory = $true)][string] $OriginalGameRoot
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$localRoot = [IO.Path]::GetFullPath((Join-Path $repo 'local')).TrimEnd('\') + '\'
$TestRoot = [IO.Path]::GetFullPath($TestRoot).TrimEnd('\')
$Installer = [IO.Path]::GetFullPath($Installer)
$StageRoot = [IO.Path]::GetFullPath($StageRoot)
if (-not $TestRoot.StartsWith($localRoot, [StringComparison]::OrdinalIgnoreCase) -or
    (Test-Path -LiteralPath $TestRoot)) { throw 'TestRoot must be a NEW disposable directory under local/.' }
if ((Get-Item -LiteralPath $Installer).VersionInfo.ProductName.Trim() -ne 'Unreal Revived Validation') {
    throw 'Refusing to run an installer without the isolated validation identity.'
}
$testKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{2ECFF5AD-A39A-469F-906C-6D842DF3D310}_is1'
if (Test-Path $testKey) { throw 'An existing validation installation must be reviewed before another lifecycle test.' }
New-Item -ItemType Directory -Path $TestRoot | Out-Null
$installed = Join-Path $TestRoot 'installed'
$system = Join-Path $installed 'System64'
$documents = [Environment]::GetFolderPath('MyDocuments')
$backupsBefore = @(Get-ChildItem -LiteralPath $documents -Directory -Filter 'Unreal Revived Backup *' | ForEach-Object FullName)
$token = [Guid]::NewGuid().ToString()

function Run-Installer {
    param([string] $Label)
    $arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /DIR="{0}" /OriginalGameRoot="{1}" /TASKS="desktopicon,vrdesktopicon" /LOG="{2}"' -f $installed,$OriginalGameRoot,(Join-Path $TestRoot "$Label.log")
    $process = Start-Process -FilePath $Installer -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(180000)) { throw 'Validation installer did not finish; review the isolated process before continuing.' }
    if ($process.ExitCode -ne 0) { throw "Validation installer failed: $($process.ExitCode) ($Label)" }
    $registration = Get-ItemProperty $testKey
    if ($registration.InstallLocation.TrimEnd('\') -ne $installed) { throw 'Validation registration points outside the test installation.' }
    $manifest = Get-Content -LiteralPath (Join-Path $StageRoot 'payload/payload-manifest.json') -Raw | ConvertFrom-Json
    foreach ($name in @('UnrealRevived.exe','UnrealRevivedVR.exe','D3D12Drv.dll','XInputWinDrv.dll','openxr_loader.dll','ModernMenu.u','OldWeapons.u')) {
        $expected = ($manifest.files | Where-Object path -eq $name).sha256
        if ((Get-FileHash -LiteralPath (Join-Path $system $name)).Hash -ne $expected) { throw "Installed hash mismatch: $name" }
    }
    Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Integrity.psm1') -Force
    $hostManifest = Get-Content -LiteralPath (Join-Path $StageRoot 'payload/unreal-gold-227k_15-win64.json') -Raw | ConvertFrom-Json
    Assert-UnrealRevivedHostModules -HostRoot $installed -HostManifest $hostManifest
    foreach ($name in @('UnrealRevived','UnrealRevivedVR')) {
        if (-not (Test-Path -LiteralPath (Join-Path $system "$name.int"))) { throw "Missing $name localization" }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $installed 'UnrealRevived/BrandedLaunchers-SDKLICENSE.md'))) { throw 'Missing SDK notice' }
    $shell = New-Object -ComObject WScript.Shell
    foreach ($folder in @([Environment]::GetFolderPath('Desktop'),[Environment]::GetFolderPath('Programs'))) {
        foreach ($mode in @('',' VR')) {
            $shortcut = $shell.CreateShortcut((Join-Path $folder "Unreal Revived Validation$mode.lnk"))
            $exe = if ($mode) { 'UnrealRevivedVR.exe' } else { 'UnrealRevived.exe' }
            if ($shortcut.TargetPath -ne (Join-Path $system $exe) -or $shortcut.Arguments -ne '' -or $shortcut.WorkingDirectory -ne $system) {
                throw "Incorrect shortcut: $folder / $mode"
            }
            if ($shortcut.IconLocation -notlike "$installed\UnrealRevived\UnrealRevived-Icon-*.ico,*") { throw 'Incorrect shortcut icon' }
        }
    }
    Write-Host "PASS: $Label installation, payload hashes, original host hashes, titles/notice and four shortcuts"
}

function Run-Uninstaller {
    param([switch] $RemoveSaves)
    $uninstaller = Join-Path $installed 'unins000.exe'
    if ((Get-ItemProperty $testKey).InstallLocation.TrimEnd('\') -ne $installed) { throw 'Unsafe validation uninstall location' }
    $arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'
    if ($RemoveSaves) { $arguments += ' /REMOVESAVES' }
    $process = Start-Process -FilePath $uninstaller -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(120000) -or $process.ExitCode -ne 0) { throw 'Validation uninstall failed' }
    # Inno's temporary uninstaller can still be restoring retained saves after
    # the original process exits and removes its registration. Wait for the
    # expected filesystem result before inspecting it or starting Setup again.
    $deadline = (Get-Date).AddSeconds(30)
    do {
        $saveExists = Test-Path -LiteralPath (Join-Path $installed 'Save/validation-save.txt')
        $finished = -not (Test-Path -LiteralPath (Join-Path $system 'UnrealRevived.exe')) -and
            -not (Test-Path -LiteralPath $uninstaller) -and ($saveExists -ne [bool]$RemoveSaves)
        if ($finished) { break }
        Start-Sleep -Milliseconds 250
    } while ((Get-Date) -lt $deadline)
    if (-not $finished) { throw 'Uninstaller did not finish restoring/removing validation data' }
    if (Test-Path $testKey) { throw 'Validation registration survived uninstall' }
}

Run-Installer 'fresh'
& (Join-Path $PSScriptRoot 'test-branded-launchers.ps1') -RuntimeRoot $installed

# Exercise profile migration directly without changing the intentional Setup
# rerun -> uninstall dialog. The installer engine must retain existing values.
Import-Module (Join-Path $PSScriptRoot 'UnrealRevived.Ini.psm1') -Force
foreach ($profile in @('Unreal.ini','UnrealVR.ini')) {
    $path = Join-Path $system $profile
    $lines = Get-Content -LiteralPath $path
    $width = if ($profile -eq 'UnrealVR.ini') { '1440' } else { '1600' }
    $lines = Set-UnrealRevivedIniValue $lines 'XInputWinDrv.WindowsClient' 'WindowedViewportX' $width
    Set-Content -LiteralPath $path -Value $lines -Encoding ASCII
}
New-Item -ItemType Directory -Path (Join-Path $installed 'Save') -Force | Out-Null
Set-Content -LiteralPath (Join-Path $installed 'Save/validation-save.txt') -Value $token -Encoding ASCII
$savedHashes = @{}
foreach ($name in @('Unreal.ini','UnrealVR.ini','User.ini')) { $savedHashes[$name] = (Get-FileHash -LiteralPath (Join-Path $system $name)).Hash }
& (Join-Path $PSScriptRoot 'install-unreal-revived.ps1') -InstallRoot $installed -PayloadRoot (Join-Path $StageRoot 'payload') -OriginalGameRoot $OriginalGameRoot
foreach ($name in $savedHashes.Keys) {
    if ((Get-FileHash -LiteralPath (Join-Path $system $name)).Hash -ne $savedHashes[$name]) { throw "Profile migration changed $name" }
}
Write-Host 'PASS: installer profile migration preserves changed desktop/VR settings and controls byte-for-byte'
Run-Uninstaller
if ((Get-Content -LiteralPath (Join-Path $installed 'Save/validation-save.txt') -Raw).Trim() -ne $token) { throw 'Uninstall lost retained save' }
$testBackups = @(Get-ChildItem -LiteralPath $documents -Directory -Filter 'Unreal Revived Backup *' | Where-Object { $_.FullName -notin $backupsBefore })
$backup = @($testBackups | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'Save/validation-save.txt') })
if ($backup.Count -ne 1) { throw 'Cannot identify the validation user-data backup' }
foreach ($name in $savedHashes.Keys) {
    if ((Get-FileHash -LiteralPath (Join-Path $backup[0].FullName "System64/$name")).Hash -ne $savedHashes[$name]) { throw "Uninstall backup changed $name" }
}
Write-Host 'PASS: uninstall retains saves and backs up all three profiles exactly'
Run-Installer 'reinstall'
if ((Get-Content -LiteralPath (Join-Path $installed 'Save/validation-save.txt') -Raw).Trim() -ne $token) { throw 'Reinstall lost retained save' }
Write-Host 'PASS: reinstall with retained saves and existing icon leftovers'
Run-Uninstaller -RemoveSaves
foreach ($folder in @([Environment]::GetFolderPath('Desktop'),[Environment]::GetFolderPath('Programs'))) {
    foreach ($mode in @('',' VR')) {
        if (Test-Path -LiteralPath (Join-Path $folder "Unreal Revived Validation$mode.lnk")) { throw 'Validation shortcut survived uninstall' }
    }
}
# Delete only newly created backups carrying this test's unique save token.
foreach ($backupDirectory in Get-ChildItem -LiteralPath $documents -Directory -Filter 'Unreal Revived Backup *') {
    $sentinel = Join-Path $backupDirectory.FullName 'Save/validation-save.txt'
    if ($backupDirectory.FullName -notin $backupsBefore -and (Test-Path -LiteralPath $sentinel) -and
        (Get-Content -LiteralPath $sentinel -Raw).Trim() -eq $token -and
        $backupDirectory.Parent.FullName -eq $documents -and
        -not ($backupDirectory.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        Remove-Item -LiteralPath $backupDirectory.FullName -Recurse -Force
    }
}
Write-Host 'PASS: lifecycle complete; validation registration, shortcuts and test backups cleaned up'

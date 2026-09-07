# Clean full rebuild

Use this guide to discard all uncommitted source changes and rebuild every
Unreal Revived development and distribution artifact. Run all commands from
the repository root in PowerShell.

## Quiet non-destructive rebuild

When the source tree already contains the code that should be built, use the
wrapper instead of the destructive cleanup steps below:

```powershell
powershell -NoProfile -File scripts/rebuild-all.ps1
```

The wrapper verifies prerequisites, removes only the ignored `local/build/`
tree, runs the same configure, build, deployment, packaging, artifact, and
repository checks documented below, and leaves tracked and untracked source
files untouched. Detailed command output is written to a timestamped
`local/logs/rebuild/<timestamp>/rebuild.log`; the console shows only stage
status and timing. Add `-ShowOutput` to stream the full output while retaining
the log.

Use the destructive procedure below only when source changes must also be
discarded.

> [!WARNING]
> The cleanup commands permanently delete tracked edits and untracked files.
> They preserve ignored inputs under `local/`, except for `local/build/`, which
> is deliberately removed. Commit or back up anything that must be retained.

## 1. Check prerequisites

Close `Unreal.exe`, then confirm that the disposable runtime, SDK, pinned
archives, and packaging record exist:

```powershell
git ls-files --error-unmatch -- PERMISSIONS.md | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'PERMISSIONS.md must be tracked before a clean full rebuild.'
}

$requiredPaths = @(
    'PERMISSIONS.md'
    'local/game/.unreal-revived-development.json'
    'local/game/System64/Unreal.exe'
    'local/sdk/227k_15/Core/Inc/Core.h'
    'local/downloads/OldUnreal-UnrealPatch227k-Windows.zip'
    'local/downloads/OldUnreal-UnrealPatch227k-SDK-Windows.zip'
)

foreach ($path in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing full-rebuild prerequisite: $path"
    }
}
```

The packaging record must be committed because `git clean -fd` removes an
untracked copy before the packaging steps run.

If the runtime, SDK, or archives are missing, create them first:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1 -SkipTests
```

## 2. Discard uncommitted changes

```powershell
git reset --hard HEAD
git clean -fd

if (Test-Path -LiteralPath 'local/build') {
    Remove-Item -LiteralPath 'local/build' -Recurse -Force
}

git status --short --branch
```

The status output should contain only the branch line. `git clean -fd` does
not remove ignored runtime, SDK, download, package, or log directories.

## 3. Configure and compile native components

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --config Release --parallel
```

This builds the Release `D3D12Drv.dll`, `XInputWinDrv.dll`, and pinned static
SDL3 dependency from a fresh CMake build tree.

## 4. Deploy all development components

```powershell
cmake --build local/build --target deploy-d3d12drv --config Release
cmake --build local/build --target deploy-xinputwindrv --config Release
cmake --build local/build --target deploy-modern-menu --config Release
```

These commands deploy the renderer and input driver, compile `ModernMenu.u`,
update the development profiles, and refresh the shortcuts under `local/game/`.
Deployment is restricted to the marked disposable runtime.

## 5. Build the offline installer

```powershell
cmake --build local/build --target package-offline-installer --config Release
```

This target recreates the complete staging payload, recompiles ModernMenu,
builds the Inno Setup executable, and writes its SHA-256 sidecar. Running the
separate `stage-offline-package` target is unnecessary because this target
already replaces and rebuilds the same staging tree.

Outputs:

```text
local/package/offline-installer/payload/
local/package/offline-installer/output/UnrealRevived-Setup-0.4.0.exe
local/package/offline-installer/output/UnrealRevived-Setup-0.4.0.exe.sha256
```

## 6. Build the developer bundle

```powershell
powershell -NoProfile -File scripts/package-developer-bundle.ps1
```

Outputs:

```text
local/package/developer-bundle/UnrealRevived-DeveloperBundle-227k_15-v1.zip
local/package/developer-bundle/UnrealRevived-DeveloperBundle-227k_15-v1.zip.sha256
local/package/developer-bundle/developer-bundle-manifest.json
```

## 7. Verify the rebuild

```powershell
$artifacts = @(
    'local/build/D3D12Drv/Release/D3D12Drv.dll'
    'local/build/XInputWinDrv/Release/XInputWinDrv.dll'
    'local/game/System64/ModernMenu.u'
    'local/package/offline-installer/output/UnrealRevived-Setup-0.4.0.exe'
    'local/package/developer-bundle/UnrealRevived-DeveloperBundle-227k_15-v1.zip'
)

foreach ($artifact in $artifacts) {
    Get-Item -LiteralPath $artifact | Select-Object FullName, Length, LastWriteTime
    Get-FileHash -LiteralPath $artifact -Algorithm SHA256
}

powershell -NoProfile -File scripts/check-repository.ps1
git status --short --branch
```

The safety check must pass, and Git should still be clean. This workflow builds
and packages everything but does not run runtime tests. Follow
[`testing.md`](testing.md) when runtime validation is required.

For target behavior, prerequisites, path overrides, and packaging policy, see
[`building.md`](building.md). For individual commands, see
[`commands.md`](commands.md).

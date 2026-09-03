# Command reference

Run these commands from the Unreal Revived repository root in PowerShell.
Generated runtimes, builds, logs, downloads, and packages stay under the
ignored `local/` directory.

## Requirements

- Windows x64 and an installed copy of Unreal Gold.
- Visual Studio 2022 C++ tools and CMake 3.24 or newer.
- Inno Setup 6 when building the offline installer.
- No running `Unreal.exe` when deploying or running automated tests.

The default paths are `local/sdk/227k_15`, `local/game`, and
`local/downloads/OldUnreal-UnrealPatch227k-Windows.zip`. Override them with
`UE1_227K_SDK_ROOT`, `UE1_GAME_ROOT`, and
`OLDUNREAL_227K15_PATCH_ARCHIVE` before configuring CMake.

## Create the development environment

The bootstrap is the normal first command for a new checkout. It installs or
finds prerequisites, downloads and verifies the pinned OldUnreal inputs,
creates the disposable game and SDK, configures and builds the project, runs
smoke tests, and creates development shortcuts.

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1
```

Reuse already downloaded archives and skip runtime tests when only recreating
the development environment:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1 -SkipDownload -SkipTests
```

`-Force` recreates an existing marked development runtime. It never authorizes
modifying an unmarked directory or the original Steam installation.

## Configure and compile

Configure the Visual Studio x64 build directory:

```powershell
cmake -S . -B local/build -A x64
```

Compile the native renderer and input driver:

```powershell
cmake --build local/build --config Release
```

Compile and deploy individual components to `local/game`:

```powershell
cmake --build local/build --target deploy-d3d12drv --config Release
cmake --build local/build --target deploy-xinputwindrv --config Release
cmake --build local/build --target deploy-modern-menu --config Release
```

These targets are created when the configured game root already contains
`System64\Unreal.exe`; run bootstrap before configuring a new checkout.
The ModernMenu target compiles `ModernMenu.u`, updates the development INIs,
and refreshes the normal and recovery shortcuts. Deploy targets require the
development marker created by bootstrap.

## Launch the development game

Use the generated `local/game/Unreal Revived.lnk`, or run:

```powershell
Set-Location local/game/System64
.\Unreal.exe Unreal.unr?Game=ModernMenu.ModernIntro ini=D3D12Test.ini userini=D3D12TestUser.ini
Set-Location ../../..
```

The explicit map token must precede `ini=` for this host. The installed product
is different: its canonical INIs allow bare `System64\Unreal.exe` startup.

Launch the development recovery profile:

```powershell
powershell -NoProfile -File scripts/launch-development-recovery.ps1 -GameRoot local/game
```

## Build the installer

Stage the filtered patch and installer payload without compiling Setup:

```powershell
cmake --build local/build --target stage-offline-package --config Release
```

Rebuild the complete offline installer:

```powershell
cmake --build local/build --target package-offline-installer --config Release
```

Output is written to `local/package/offline-installer/output/` with a SHA-256
sidecar. Packaging replaces the existing ignored staging directory and can take
several minutes because it verifies and extracts the pinned patch archive.

Build the separate developer bundle:

```powershell
powershell -NoProfile -File scripts/package-developer-bundle.ps1
```

## Test and inspect

Run all automated runtime suites:

```powershell
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite All
```

Useful focused checks:

```powershell
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite Input -RunSeconds 3
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite Content -ScreenshotMode Compare
powershell -NoProfile -File scripts/test-supported-renderers.ps1 -RunSeconds 8
```

Run the required repository safety check before packaging or committing:

```powershell
powershell -NoProfile -File scripts/check-repository.ps1
```

Create a read-only content inventory under a timestamped directory in
`local/logs/content-audit/`:

```powershell
powershell -NoProfile -File scripts/audit-game-content.ps1
```

## Rebuild options

Recompile everything while asking the selected build system to clean targets
first:

```powershell
cmake --build local/build --config Release --clean-first
```

Rerun CMake configuration after changing SDK/runtime paths or build files:

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
```

To recreate the entire disposable runtime, rerun bootstrap with `-Force`. This
replaces the marked `local/game` development copy, so preserve any local saves
or settings you need first.

## Branding commands

Regenerate the tracked branding assets from their configured sources:

```powershell
powershell -NoProfile -File scripts/build-unreal-revived-branding.ps1
```

`-DeriveBranding` requires `-MenuBackgroundSource` and rewrites tracked banners
and the icon as well as the menu artwork. Review those changes before keeping
them:

```powershell
powershell -NoProfile -File scripts/build-unreal-revived-branding.ps1 -MenuBackgroundSource <path-to-16x9-image> -DeriveBranding
```

See [building.md](building.md) for setup and packaging details and
[testing.md](testing.md) for validation expectations.
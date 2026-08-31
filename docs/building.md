# Building

## Supported target

The current target is OldUnreal 227k_15 on Windows x64. CMake is the canonical
build system. The checked-in Visual Studio project is inherited reference
material and is not the supported build entry point.

## Prerequisites

- Windows x64
- Unreal Gold installed through Steam
- winget, unless the development tools are already installed

The bootstrap installs Git, CMake, Visual Studio 2022 Build Tools with the C++
workload, and Inno Setup 6 when they are missing. Original Steam game assets
are never downloaded or distributed; they are copied into the ignored,
disposable runtime. The authorized OldUnreal host and SDK are supplied by the
pinned original OldUnreal release downloads. Verified copies are cached under
`local/downloads/`; the host manifest records MEGA recovery mirrors.

## One-command setup

From a fresh clone:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1
```

Steam App ID 13250 is discovered across registered Steam libraries. Override
discovery or use a previously generated local bundle with:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1 `
   -OriginalGameRoot 'D:\SteamLibrary\steamapps\common\Unreal Gold' `
   -BundlePath 'E:\UnrealRevived-DeveloperBundle-227k_15-v1.zip' `
   -SkipDownload
```

Use `-SkipToolchainInstall` only when the prerequisites are already available,
`-SkipTests` to omit runtime smoke tests, and `-Force` to recreate an existing
marked development runtime. `-Force` never permits deletion of an unmarked
directory.

## Archive acquisition and recovery

Bootstrap acquires each pinned archive in this order:

1. Reuse a matching file from `local/downloads/`.
2. Download it from the original OldUnreal `v227k_15` release.
3. If the original source is unavailable, report the owner-controlled MEGA
    recovery link and required cache filename.

| Archive | Original source | Recovery mirror |
| --- | --- | --- |
| `OldUnreal-UnrealPatch227k-Windows.zip` | [OldUnreal release](https://github.com/OldUnreal/Unreal-testing/releases/download/v227k_15/OldUnreal-UnrealPatch227k-Windows.zip) | [MEGA](https://mega.nz/file/dE41QYbA#uiyeYtIkmubYh0LPHTpMuS3InMcuTW4QDUKV3Wd_hCk) |
| `OldUnreal-UnrealPatch227k-SDK-Windows.zip` | [OldUnreal release](https://github.com/OldUnreal/Unreal-testing/releases/download/v227k_15/OldUnreal-UnrealPatch227k-SDK-Windows.zip) | [MEGA](https://mega.nz/file/1JBUGJAT#WHDv2Tqj_BwElg3I2ZoAViSHbW3mQig_7muB67m6XCk) |

MEGA share links require browser-side decryption, so fallback is intentionally
manual. Save both files under `local/downloads/` with the exact names above and
rerun bootstrap. Size and SHA-256 verification is mandatory regardless of
source.

Archives stored elsewhere can be supplied explicitly:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1 `
   -RuntimeArchive 'E:\OldUnreal-UnrealPatch227k-Windows.zip' `
   -SdkArchive 'E:\OldUnreal-UnrealPatch227k-SDK-Windows.zip' `
   -SkipDownload
```

The SDK root must contain these files:

```text
Core/Inc/Core.h
Engine/Inc/Engine.h
Render/Inc/Render.h
Core/Lib/x64/Core.lib
Engine/Lib/x64/Engine.lib
Render/Lib/x64/Render.lib
```

## Path configuration

CMake resolves each path from an environment variable first, then falls back to
the ignored local directory:

| Variable | Default |
| --- | --- |
| `UE1_227K_SDK_ROOT` | `local/sdk/227k_15` |
| `UE1_GAME_ROOT` | `local/game` |
| `OLDUNREAL_227K15_PATCH_ARCHIVE` | `local/downloads/OldUnreal-UnrealPatch227k-Windows.zip` |

Example for the current PowerShell session:

```powershell
$env:UE1_227K_SDK_ROOT = 'D:\SDKs\OldUnreal-227k_15'
$env:UE1_GAME_ROOT = 'D:\Games\UnrealGold-227k_15-test'
```

## Configure and build

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
```

The renderer is built as `D3D12Drv.dll` with C++17 and links against the 227
Core, Engine, and Render import libraries plus the Windows Direct3D 12, DXGI,
and shader compiler libraries.

## Deploy

When `<game-root>/System64/Unreal.exe` exists, CMake exposes the deployment
target:

```powershell
cmake --build local/build --target deploy-d3d12drv --config Release
cmake --build local/build --target deploy-modern-menu --config Release
```

The target performs these operations in the disposable game installation:

1. Copies `D3D12Drv.dll` and `D3D12Drv.int` to `System64/`.
2. Copies the localized `UnrealShare.int` and `UPak.int` files from
   `SystemLocalized/int/` to `System/`.
3. Copies the complete localized `Startup.int` to both `System/` and
   `System64/` so early recovery dialogs can resolve their text before normal
   localization paths are available.

The second operation is required because 227's `IntDescIterator` discovers the
single-player campaign registrations beside the game packages in `System/`.
Without it, the New Game campaign combo is empty even though localization paths
include `SystemLocalized/`.

The `Startup.int` copies replace the truncated legacy file in `System/` and put
the same resource beside the x64 executable. Without the `System64/` copy, the
recovery dialog displays localization keys instead of labels.

Deployment and runtime-test scripts require
`.unreal-revived-development.json`. The bootstrap creates this marker only in
the physical disposable copy. Unmarked trees and the original Steam
installation are rejected.

The `deploy-modern-menu` target compiles the standalone `ModernMenu.u` package
with the disposable runtime's x64 `UCC.exe`. It deploys the package to
`System64/` and updates `D3D12Test.ini` to load the custom root window and menu
package. It does not rebuild or replace OldUnreal's network-sensitive core
packages.

## Build the developer bundle

Place both pinned upstream archives under `local/downloads/`, then run:

```powershell
powershell -NoProfile -File scripts/package-developer-bundle.ps1
```

The optional bundle script verifies archive sizes and SHA-256 values, extracts
and validates the host and SDK, rejects generated/user data, and writes the
bundle, checksum sidecar, and generated artifact manifest under
`local/package/developer-bundle/`. The tracked manifest pins its size and
SHA-256 for optional `-BundlePath` use; no hosted bundle URL is configured or
required by the default bootstrap.

## Build the offline installer

Place the pinned `OldUnreal-UnrealPatch227k-Windows.zip` archive at the default
path above or set `OLDUNREAL_227K15_PATCH_ARCHIVE`, then run:

```powershell
cmake --build local/build --target package-offline-installer --config Release
```

The target verifies the archive against the host manifest, extracts its 2,010
files under the ignored staging directory, verifies the pinned x64 modules,
builds the renderer and ModernMenu, stages a hash manifest, and invokes Inno
Setup. The ZIP itself is not embedded. The generated single-file installer and
its SHA-256 sidecar are written under
`local/package/offline-installer/output/`.

The Unreal Revived installer detects Steam App ID 13250 across registered Steam
libraries and preselects that installation on an **Original Game** page. The
user can browse to another Unreal Gold installation containing
`System\Unreal.exe`; the selected source is validated and shown again on the
Ready page. The installer copies the user-owned game into the default
side-by-side directory `C:\Games\Unreal Revived`, overlays the bundled 227k_15
patch, and installs the renderer and menu without requesting administrator
elevation. Standard Windows permissions allow the current user to create the
top-level `C:\Games` directory; a custom destination must also be user-writable.

The selected original game is copied by a hidden helper before Inno's file
phase. Inno then installs the already extracted patch tree directly with its
native progress UI; there is no runtime ZIP extraction. Final hash verification
and profile generation also run hidden, so no console window opens. The
installer never writes into the original source. It launches with dedicated
`UnrealRevived.ini` and `UnrealRevivedUser.ini` profiles. Uninstall backs up
saves and those profiles to a timestamped `Unreal Revived Backup` directory
under Documents before removing the side-by-side installation.

Rerunning the same installer detects the registered Unreal Revived App ID and
opens a maintenance prompt. **Yes** runs the existing uninstaller, preserves
the configured user-data backup, and closes Setup. **No** continues into the
normal wizard to repair or update the installation. **Cancel** exits without
making changes. Both machine-wide and earlier per-user registrations are
detected.

## Repository safety

Run the repository guard before committing:

```powershell
powershell -NoProfile -File scripts/check-repository.ps1
```

The check rejects tracked or unignored game assets, SDK files, binaries, logs,
saves, and build output.

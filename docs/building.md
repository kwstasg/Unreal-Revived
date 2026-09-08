# Building

## Supported target

The current target is OldUnreal 227k_15 on Windows x64. CMake is the canonical
build system. The checked-in Visual Studio project is inherited reference
material and is not the supported build entry point.

## Prerequisites

- Windows x64
- Unreal Gold installed through OldUnreal's official full-game installer or
  another installation containing `System\Unreal.exe`
- winget, unless the development tools are already installed

The bootstrap installs Git, CMake, Visual Studio 2022 Build Tools with the C++
workload, and Inno Setup 6 when they are missing. If Unreal Gold is not already
available, install it first from [OldUnreal's official full-game installer
page](https://www.oldunreal.com/downloads/unreal/full-game-installers/). Original
game assets are never downloaded by the bootstrap or distributed by Unreal
Revived; they are copied from the detected installation into the ignored,
disposable runtime. The authorized OldUnreal host and SDK are supplied by the
pinned original OldUnreal release downloads. Verified copies are cached under
`local/downloads/`.

## One-command setup

From a fresh clone:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1
```

The standard OldUnreal location `C:\Unreal` is checked first, followed by a
legacy Steam App ID 13250 installation for existing owners. When neither is
found, the bootstrap stops before installing developer tools, with the
OldUnreal installer URL and instructions to rerun it.
Override discovery for any other location or use a previously generated local
bundle with:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1 `
   -OriginalGameRoot 'D:\Games\Unreal Gold' `
   -BundlePath 'E:\UnrealRevived-DeveloperBundle-227k_15-v1.zip' `
   -SkipDownload
```

Use `-SkipToolchainInstall` only when the prerequisites are already available,
`-SkipTests` to omit runtime smoke tests, and `-Force` to recreate an existing
marked development runtime. `-Force` never permits deletion of an unmarked
directory.

## Archive acquisition and offline use

Bootstrap acquires each pinned archive in this order:

1. Reuse a matching file from `local/downloads/`.
2. Download it from the original OldUnreal `v227k_15` release.

| Archive | Original source |
| --- | --- |
| `OldUnreal-UnrealPatch227k-Windows.zip` | [OldUnreal release](https://github.com/OldUnreal/Unreal-testing/releases/download/v227k_15/OldUnreal-UnrealPatch227k-Windows.zip) |
| `OldUnreal-UnrealPatch227k-SDK-Windows.zip` | [OldUnreal release](https://github.com/OldUnreal/Unreal-testing/releases/download/v227k_15/OldUnreal-UnrealPatch227k-SDK-Windows.zip) |

Size and SHA-256 verification is mandatory for cached and explicit inputs.

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
Window/Inc/Window.h
WinDrv/Inc/WinDrv.h
WinDrv/Src/WinClient.cpp
WinDrv/Src/WinDrv.cpp
WinDrv/Src/WinInput.cpp
WinDrv/Src/WinViewport.cpp
WinDrv/Src/Res/WinDrvRes.rc
Core/Lib/x64/Core.lib
Engine/Lib/x64/Engine.lib
Render/Lib/x64/Render.lib
Window/Lib/x64/Window.lib
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

For a destructive start-to-finish rebuild of all development and distribution
artifacts, follow the [clean full rebuild guide](rebuild-everything.md). The
commands below describe the individual build stages.

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
```

The renderer is built as `D3D12Drv.dll` with C++17 and links against the 227
Core, Engine, and Render import libraries plus the Windows Direct3D 12, DXGI,
and shader compiler libraries. CMake also builds the hash-pinned Khronos
OpenXR 1.1.61 loader as a standalone DLL. D3D12Drv resolves that DLL only after
an explicit VR request, so it is not an import-time dependency.

The `XInputWinDrv.dll` package is built from a generated copy of the
pinned SDK's WinDrv source. Configure runs `scripts/stage-xinput-windrv.ps1`,
which copies the source under `local/build/XInputWinDrv/staged/` and applies the
tracked `XInputWinDrv/patches/227k_15-xinputwindrv.patch`. The ignored SDK is
never edited. The patch gives the copied classes a side-by-side package identity
and connects the tracked `XInputController` implementation to WinDrv's client
lifecycle and viewport input poll. Fresh generated profiles select the package;
existing profiles and the pinned `WinDrv.dll` remain unchanged.

CMake downloads the pinned SDL 3.4.16 source archive, verifies its SHA-256,
and links its static Gamepad implementation into `XInputWinDrv.dll`. SDL is the
primary normalized controller backend; the existing dynamically loaded system
XInput path remains as a fallback. The pin and redistribution basis are recorded
in `manifests/provenance/sdl3-3.4.16.json`. Configuring a fresh build therefore
requires network access unless CMake's FetchContent cache already contains the
verified archive.

The same FetchContent policy pins the Khronos OpenXR SDK 1.1.61 archive by
SHA-256. Its unmodified dynamic loader is deployed and packaged beside
`Unreal.exe`; upstream licensing and provenance are retained. Normal
flat-screen launches leave the loader unloaded.

## Deploy

When `<game-root>/System64/Unreal.exe` exists, CMake exposes the deployment
targets:

```powershell
cmake --build local/build --target deploy-d3d12drv --config Release
cmake --build local/build --target deploy-xinputwindrv --config Release
cmake --build local/build --target deploy-modern-menu --config Release
```

The targets perform these operations in the disposable game installation:

1. Copies `D3D12Drv.dll`, `D3D12Drv.int`, and `openxr_loader.dll` to
   `System64/`.
2. Copies the localized `UnrealShare.int` and `UPak.int` files from
   `SystemLocalized/int/` to `System/`.
3. Copies the complete localized `Startup.int` to both `System/` and
   `System64/` so early recovery dialogs can resolve their text before normal
   localization paths are available.
4. Copies the side-by-side `XInputWinDrv.dll` package to `System64/` without
   replacing the pinned `WinDrv.dll`.
5. Compiles `ModernMenu.u`, overlays project localization, installs runtime
   branding, updates the development profiles, and recreates the development
   shortcuts.

The second operation is required because 227's `IntDescIterator` discovers the
single-player campaign registrations beside the game packages in `System/`.
Without it, the New Game campaign combo is empty even though localization paths
include `SystemLocalized/`.

The `Startup.int` copies replace the truncated legacy file in `System/` and put
the same resource beside the x64 executable. Without the `System64/` copy, the
recovery dialog displays localization keys instead of labels.

Deployment and runtime-test scripts require
`.unreal-revived-development.json`. The bootstrap creates this marker only in
the physical disposable copy. Unmarked trees and the original game installation
are rejected.

After a successful build and optional content test, bootstrap creates
`Unreal Revived.lnk` and `Unreal Revived Recovery.lnk` in the disposable game
root. Both shortcuts resolve the current runtime and repository paths at
creation time. Rerun bootstrap after moving the checkout so those absolute
shortcut paths are refreshed.

The `deploy-modern-menu` target compiles the standalone `ModernMenu.u` package
with the disposable runtime's x64 `UCC.exe`. It deploys the package to
`System64/` and updates `D3D12Test.ini` to load the custom root window and menu
package. It also refreshes the tracked setup logos under `Help/` and recreates
the development shortcuts with a hash-derived copy of the tracked icon. It
does not rebuild or replace OldUnreal's network-sensitive core packages.

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

The tracked `manifests/content/unreal-revived-install-content-v1.json` policy is
applied to both the original-game copy and extracted patch before packaging.
It omits historical DirectX redistributables, manuals, patch release notes,
setup artwork, copied logs, source user profiles, and linker cache state.
`Help/Logo.bmp` and `Help/SetupLogo.bmp` are retained because runtime tracing
and host source confirm the x64 executable loads them during startup and
first-time configuration. Both campaigns, multiplayer and dedicated-server
content, web administration, all localizations, D3D12, XOpenGL recovery, editor
runtime packages, and the x64 dedicated-server path remain installed.

Validated obsolete D3D7, D3D9, Glide, software, Metal, and ICBINDx11 renderer
binaries and companion assets are also omitted from both `System` and
`System64`. D3D12 is the primary renderer; XOpenGL and standard OpenGL remain
available for recovery. Obsolete renderer registration files and localized
recovery descriptions are filtered as well, so Video Preferences and recovery
advertise only Direct3D 12, OpenGL, and XOpenGL.

The supported host is x64, so direct `.dll` and `.exe` files under `System`
are omitted after PE inspection confirmed all 42 are x86. The `System`
directory itself remains essential: the x64 engine loads its architecture-
independent `.u` packages and localization registrations from there. End-user
UnrealEd/setup executables, editor resource directories, editor splash/config
files, and the original install manifest are also omitted. `System64/UCC.exe`,
`Editor.dll`, and `ScriptedAIEd.dll` remain because UCC is the supported
dedicated-server entry point and normal gameplay maps can load `Editor.dll`.
The disposable development runtime may still contain `System64/UnrealEd.exe`
from the pinned host. ModernMenu deployment configures its local `Unreal.ini`
so bare editor launches retain visible editor viewports instead of drawing the
game's full-screen branded menu background. This is a development convenience;
UnrealEd remains excluded from the distributed product.

ALAudio is the sole distributed audio engine. It uses the bundled OpenAL Soft
and retains `OpenAL32.dll`, `libxmp.dll`, `sndfile.dll`, `mpg123.dll`, and
`libmp3lame.dll`. Deprecated Galaxy and experimental SwFMOD registrations,
localized descriptions, binaries, and the FMOD Ex library are omitted.

Packaging replaces both retained logo bitmaps with the original project-owned
artwork tracked under `branding/`. It also installs the tracked seven-frame,
16-through-256-pixel `UnrealRevived.ico` for shortcuts and uninstall metadata.
The installed icon filename includes a prefix of its SHA-256 hash so Windows
Explorer cannot reuse a stale cached image after artwork changes. Setup offers
the desktop shortcut as a user-selectable task on each installation and offers
to launch the game from the Completed page.
Setup retains the portrait wordmark artwork on its Welcome and Completed pages,
shows the standard Setup icon in page headers, adds a current feature list to
the Welcome page, and keeps a clickable GitHub link beside
the Unreal Revived name in the bottom bar on every page. The branded uninstall
confirmation uses the portrait artwork.
The logo, installer, runtime, and icon derivatives can be regenerated
deterministically with
`scripts/build-unreal-revived-branding.ps1 -BrandingOnly`. Regenerating the
menu background requires an explicit authored source as described below;
running the generator without options creates placeholder menu artwork.
Packaging copies the tracked files directly and does not read original-game
artwork. Both generic defaults and the dedicated launch profile select D3D12,
and every localized first-time configuration page carries the D3D12
recommendation text.

The same generator imports tracked 16:9 source artwork into a 3840x2160 in-game
menu master and twelve 256x256 tiles under `branding/MenuTiles`. It resamples
the complete image once
into the package's encoded canvas before extracting tiles, which avoids seams
from independently resampled edges. Building ModernMenu stages and imports the
tiles into `ModernMenu.u`; `ModernRootWindow` displays them in place of the
OldUnreal Edition desktop whenever the menu hides the game world. The runtime
restores the source's native 16:9 proportions and uses centered cover scaling
for other viewport ratios, so replacement artwork is never stretched.

To import user-authored artwork, supply a 16:9 PNG, BMP, or JPEG to
`scripts/build-unreal-revived-branding.ps1 -MenuBackgroundSource <path>`. Add
`-DeriveBranding` to derive transparent logo outputs and dark-backed BMP
compatibility copies from `UnrealRevivedLogo.png`, installer artwork from
`UnrealRevivedLogo.jpg`, and the seven-frame ICO from `icon..png`. Without that
switch, only the canonical menu bitmap and twelve tiles change. The tracked
952x295 and 343x84 BMP banners are generated compatibility assets because the
legacy runtime controls cannot render PNG or BMP alpha. Wider viewports crop
the top and bottom; narrower viewports crop the sides.

The validated source snapshot omitted 305 audited paths totaling 134,784,646
bytes, although generated files and source-install differences can change the
exact installed reduction. Original game files are read only and are never
removed.

The Unreal Revived installer detects the standard `C:\Unreal` location first.
For existing owners, it can also detect legacy Steam App ID 13250 installations
across registered libraries. It preselects the first valid installation on an
**Original Game** page. If no source is found,
**Install via OldUnreal** opens OldUnreal's official full-game installer page;
after it finishes, **Detect Again** checks the known source locations again. The
user can always browse to another Unreal Gold installation
containing `System\Unreal.exe`; the selected source is validated and shown again
on the Ready page. The installer copies the source game into the default
side-by-side directory `C:\Games\Unreal Revived`, overlays the bundled 227k_15
patch, and installs the renderer, input driver, ModernMenu, localization, and
branding without requesting administrator elevation. Standard Windows
permissions allow the current user to create the
top-level `C:\Games` directory; a custom destination must also be user-writable.

The selected original game is copied by a hidden helper before Inno's file
phase. Inno then installs the already extracted patch tree directly with its
native progress UI; there is no runtime ZIP extraction. Final hash verification
and profile generation also run hidden, so no console window opens. The
installer never writes into the original source. It launches with canonical
`Unreal.ini` and `User.ini` profiles, allowing its `System64\Unreal.exe`
and installed shortcuts to start with no arguments. Uninstall backs up saves
and canonical profiles to a timestamped `Unreal Revived Backup` directory
under Documents before removing the side-by-side installation. Windows
Installed Apps and a direct launch of the uninstaller both reach one branded
uninstall confirmation with the project portrait, a clickable GitHub link, and
a default-checked **Keep save games** option. A direct launch relaunches the
uninstaller with `/SILENT` so Inno's redundant native confirmation does not
appear. Running Setup over an already-installed copy opens that same single
branded options dialog instead of displaying a separate maintenance
confirmation first. The dialog explicitly states that uninstall removes only Unreal
Revived and does not change the source Unreal Gold installation or OldUnreal
downloads. When checked, the `Save` directory is retained under the installation path for a future reinstall.
Explicit `/VERYSILENT` uninstall also keeps saves without prompting. Unchecking
the option removes the installation copy after the Documents backup is created.
Reinstall accepts a retained `Save` directory and excludes the original game's
save folder from the copy so newer retained saves are not overwritten.

For deterministic silent validation, pass the source explicitly in addition to
the destination:

```powershell
.\UnrealRevived-Setup-0.6.0.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART `
  /DIR="C:\Games\Unreal Revived" /OriginalGameRoot="C:\Unreal"
```

Interactive installs continue to detect or request the source through the
**Original Game** page. The explicit parameter is primarily for unattended
testing and still receives the same source and destination validation.

Rerunning the same installer detects the registered Unreal Revived App ID and
opens the existing installation's branded uninstall options directly. Choosing
**Uninstall** performs removal and closes Setup; choosing **Cancel** exits
without changes. Both machine-wide and earlier per-user registrations are
detected.

## Repository safety

Run the repository guard before committing:

```powershell
powershell -NoProfile -File scripts/check-repository.ps1
```

The check rejects tracked or unignored game assets, SDK files, binaries, logs,
saves, and build output.

<p align="center">
  <img src="branding/UnrealRevivedLogo.png" alt="Unreal Revived" width="800">
</p>

# Unreal Revived + VR

## Download the latest release

**[Download the latest Unreal Revived release](https://github.com/kwstasg/Unreal-Revived/releases/latest)**

**Fully playable on a normal desktop or in VR.** One installation
provides separate **Unreal Revived** desktop and **Unreal Revived VR** shortcuts.
A headset is optional and is never required for normal desktop play.

Unreal Revived is a modernization package for playing the original **Unreal
Gold** on current Windows PCs. It preserves the original game content and gameplay 
while adding native DirectX 12 rendering, modern display handling, refreshed
menus, improved controls, and broad gamepad support for devices such as Xbox
Series controllers, DualShock 4, DualSense, and other
[SDL-mapped controllers](docs/controllers.md).

**Play Unreal Revived in VR.** OpenXR stereo rendering and head tracking put
you inside the original world, with gaze-aligned gamepad movement, smooth
right-stick turning, and the full HUD and menus on a stable spatial panel.
Adjust panel distance and size, and recenter instantly with right-stick click
or F10. Both bindings are customizable.

Choose **Unreal Revived VR** to play in VR, or **Unreal Revived** for normal
desktop play. Setup offers independent desktop shortcut for each.
VR requires a configured OpenXR runtime and a connected headset.

Unreal Revived adds its own DirectX 12 renderer, ModernMenu interface,
SDL3-based controller backend, tested defaults, branding, and side-by-side
installation workflow on top of that foundation.

**Unreal Revived does not provide any original Unreal Gold game files.** It
does not include the original maps, textures, music, sounds, or other game
assets, and it cannot be used as a standalone game. Setup can use an existing
installation or guide you to OldUnreal's official full-game installer when no
source is detected. You also need a
Windows x64 PC, a DirectX 12-capable graphics system, and enough free space
for a separate copy. The installer reads your original files to create an
independent Unreal Revived installation and never modifies the source game.

## Installation

### Quick start

1. Download and start [Unreal Revived Setup from the latest release](https://github.com/kwstasg/Unreal-Revived/releases/latest), then confirm the detected Unreal Gold source.

2. If no source is detected, use **Install via OldUnreal**, complete OldUnreal Setup, return, and select **Detect Again**. If you installed OldUnreal in a custom folder, select **Browse** and choose that folder manually.

3. Keep `C:\Games\Unreal Revived` or choose another destination outside the original game folder, then complete Setup.

OldUnreal is available from the
[official installer page](https://www.oldunreal.com/downloads/unreal/full-game-installers/)
or the [direct Windows download](https://github.com/OldUnreal/FullGameInstallers/releases/download/windows-game-installers/Unreal_Gold.exe).

The offline installer creates an independent installation under
`C:\Games\Unreal Revived` by default. It reads the original Unreal Gold files
from the location selected by the player and does not write to that source
directory. The bundled, pinned OldUnreal patch and Unreal Revived components
are then applied only to the new installation. No original Unreal Gold game
files are included with Unreal Revived; every required original asset is copied
locally from the player's own installation.

Setup checks the standard `C:\Unreal` location first. It can also detect a
legacy Steam installation for players who already own the game. If no source is
available, **Install via OldUnreal** opens OldUnreal's official full-game
installer page. After that installer finishes, **Detect Again** finds the new
installation; the player can also browse to any folder containing
`System\Unreal.exe`.

In current source builds, Setup opens the branded uninstall dialog first when
it finds a current Unreal Revived installation; canceling leaves the
installation unchanged. Uninstall is configured to keep save games by default
and to back up saves and active profiles before removal. It removes only Unreal
Revived and never removes or changes the source Unreal Gold installation or
OldUnreal downloads. DirectX 12 is the normal renderer; OpenGL and XOpenGL
remain available as recovery choices. ALAudio with bundled OpenAL Soft is the
supported audio path.

## Game features and improvements

Current source builds offer separate **Unreal Revived** and **Unreal Revived VR**
shortcuts, with independent desktop-icon choices during Setup. Choose the normal
shortcut for flat-screen play or the VR shortcut for a connected OpenXR headset.
VR Preferences contains panel distance, scale and Recenter VR View. This feature
is in current source/local builds; no new GitHub release has been published yet.

This table describes the current repository source. The attached release may
lag source changes as noted under [availability](#availability-and-requirements).

| Area | What players get |
| --- | --- |
| Modern rendering | Native DirectX 12 rendering at resolutions up to 4K, with corrected HD lightmaps, high-quality textures, alpha blending, and configurable VSync. |
| Post-processing effects | Adjustable bloom, chromatic aberration, vignette, animated film grain, and CRT scanlines. Effects are applied to the 3D world while keeping the HUD and menus clean. |
| 4K and modern displays | Widescreen and high-resolution rendering, including validated 2560x1440 and 3840x2160 logical 4K modes, high-refresh support, monitor-aware borderless presentation, letterboxing, and correctly mapped menu input. Physical 4K display output still requires validation on 4K hardware. |
| Image quality | Off, 2x, 4x, and 8x MSAA modes with capability-based fallback, plus in-menu brightness, contrast, saturation, and detail controls. |
| Refreshed interface | Branded menus, focused Video, Input, Bindings, and HUD controls, an optional live game view behind menus, and persistent F11-toggled FPS statistics. |
| Gamepad support | SDL3 support for Xbox, DualShock, DualSense, and other mapped controllers, with adjustable dead zones, sensitivity, and fallback input paths; Xbox reconnect handling is validated. |
| Seated OpenXR VR | Stereo head tracking, gaze-aligned gamepad walking/strafing, smooth right-stick turning, and the existing HUD/menus on a stable shared panel. Separate normal and VR shortcuts, live panel distance/scale, and recenter controls. Validated on Oculus Rift CV1; broader runtime and gameplay coverage is ongoing. |
| Flexible controls | Up to three keyboard, mouse, or controller assignments per action, visible bindings, practical defaults, and reset controls. |
| Greek localization | Selectable Greek interface and in-game text for both Unreal and Return to Na Pali, including menus, HUD messages, level information, and translator logs. See the [localization guide](docs/localization.md). |
| Complete game content | Both Unreal and Return to Na Pali campaigns, multiplayer and dedicated-server support, all bundled languages, saves, and recovery renderers. |
| Easier installation | A separate offline installation that leaves the original game untouched, detects an existing copy before reinstalling, and is configured to retain and back up saves during uninstall. |
| Modern audio | ALAudio with bundled OpenAL Soft replaces deprecated and experimental legacy audio paths. |
| Recovery options | OpenGL and XOpenGL renderers, stock WinDrv input, a recovery shortcut, and automated regression coverage provide fallback paths and release confidence. |

See the [detailed game feature guide](docs/features.md) for the complete
organized feature list and a description of each improvement.


## Availability and requirements

The flat-screen DirectX 12 path is implemented and actively validated on
Windows x64. A prebuilt installer is attached to the
[latest GitHub release](https://github.com/kwstasg/Unreal-Revived/releases/latest),
and the repository can reproduce it from pinned, verified inputs. The latest
release may lag changes in the current source tree.

Players need:

- A Windows x64 PC.
- An existing Unreal Gold installation containing the original game assets,
  or an internet connection to obtain one through OldUnreal's official installer.
- A DirectX 12-capable graphics system for the primary renderer.
- Enough free space for a separate side-by-side copy of the game.

The installer can use `C:\Unreal` or another selected installation as its
source. That source is not used to launch or manage the new copy afterward. The
repository workflow below is intended for developers and technically
experienced testers who want to build the project themselves. See [current
validation status](docs/current-state.md) for the precise supported boundary.

## For developers

### Developer quick start

1. Install Unreal Gold through OldUnreal if no existing installation is available.

2. Clone the Unreal Revived repository and enter its root directory.

3. Run the developer bootstrap.

```powershell
git clone https://github.com/kwstasg/Unreal-Revived.git
Set-Location Unreal-Revived
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1
```

Use the [official OldUnreal installer page](https://www.oldunreal.com/downloads/unreal/full-game-installers/)
or the [direct Windows download](https://github.com/OldUnreal/FullGameInstallers/releases/download/windows-game-installers/Unreal_Gold.exe).
An existing installation from another source is also supported.

### Project status

The repository provides source code, automated development setup, runtime
tests, and tooling for building a fully offline installer.

| Area | Current state |
| --- | --- |
| Host runtime | OldUnreal 227k_15 on Windows x64 |
| Renderer | Native `D3D12Drv.D3D12RenderDevice` |
| Input | Native `XInputWinDrv.WindowsClient` with an SDL3 gamepad backend |
| Build | CMake, Visual Studio 2022, C++17 |
| ModernMenu | Implemented as a separate UnrealScript package |
| Offline installer | Implemented and built locally with Inno Setup |

### Development requirements

- Windows x64.
- Unreal Gold installed through OldUnreal's official full-game installer or
  another installation containing `System\Unreal.exe`.
- winget, or the required development tools already installed.
- Enough disk space for a full disposable copy of the game, the 227k_15 SDK,
  and build output.

Bootstrap checks the supported standard source locations. If it cannot find the
game, it stops before installing tools and provides the official OldUnreal
installer URL plus instructions to rerun bootstrap or pass
`-OriginalGameRoot`.
For an installation in another directory, run:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1 `
   -OriginalGameRoot 'D:\Games\Unreal Gold'
```

The bootstrap performs the complete setup:

1. Detects Unreal Gold in a supported standard location.
2. Installs missing CMake, Visual Studio C++ tools, and Inno Setup through
   winget.
3. Downloads the pinned runtime and SDK from the original OldUnreal release.
4. Verifies exact archive sizes and SHA-256 hashes.
5. Creates a full disposable game copy under `local/game/`.
6. Applies the verified 227k_15 host and installs the SDK under
   `local/sdk/227k_15/`.
7. Configures and builds the D3D12 renderer, SDL3 input driver, and ModernMenu.
8. Runs the automated D3D12 content smoke suite.
9. Creates normal and recovery shortcuts in `local/game/`.

Generated game files, downloads, SDK files, logs, and build output stay under
the ignored `local/` directory.

See the [command reference](docs/commands.md) for the common configure, build,
deploy, launch, test, recovery, and installer commands.

#### Launch the development runtime

After bootstrap completes:

```powershell
Set-Location local/game/System64
.\Unreal.exe Unreal.unr?Game=ModernMenu.ModernIntro ini=D3D12Test.ini userini=D3D12TestUser.ini
```

The leading `Unreal.unr` argument is required by this host when selecting the
custom profiles.

Bootstrap also creates `Unreal Revived.lnk` and
`Unreal Revived Recovery.lnk` in `local/game/`. The first launches the same
D3D12 profiles shown above. The second starts OldUnreal's recovery mode and
refuses to run while that disposable runtime is already open.

### Downloads and offline use

The original OldUnreal `v227k_15` release is the source for the
runtime and SDK archives. Verified downloads are cached in `local/downloads/`.

Previously downloaded archives can be supplied from local or removable storage.
Every input must pass the same immutable size and SHA-256 checks before use.
See [archive acquisition and offline use](docs/building.md#archive-acquisition-and-offline-use)
for filenames and `-RuntimeArchive`/`-SdkArchive` examples.

### OldUnreal references

- [OldUnreal official website](https://www.oldunreal.com/)
- [OldUnreal full-game installers](https://www.oldunreal.com/downloads/unreal/full-game-installers/)
- [Windows Unreal Gold installer](https://github.com/OldUnreal/FullGameInstallers/releases/download/windows-game-installers/Unreal_Gold.exe)
- [OldUnreal GitHub organization](https://github.com/OldUnreal)
- [OldUnreal 227 testing repository](https://github.com/OldUnreal/Unreal-testing)
- [Unreal v227k_15 release](https://github.com/OldUnreal/Unreal-testing/releases/tag/v227k_15)
- [Pinned v227k_15 commit](https://github.com/OldUnreal/Unreal-testing/commit/2ea5408e2aa7c955eb087a6f8d2fcce318747d2f)
- [OldUnreal-UnrealPatch227k-Windows.zip](https://github.com/OldUnreal/Unreal-testing/releases/download/v227k_15/OldUnreal-UnrealPatch227k-Windows.zip)
- [OldUnreal-UnrealPatch227k-SDK-Windows.zip](https://github.com/OldUnreal/Unreal-testing/releases/download/v227k_15/OldUnreal-UnrealPatch227k-SDK-Windows.zip)
- [OldUnreal public source](https://github.com/OldUnreal/Unreal-PubSrc)
- [OldUnreal 227 localization project](https://github.com/OldUnreal/Unreal-Localization)
- [OldUnreal 227k_15 license and third-party notices](https://github.com/OldUnreal/Unreal-testing/blob/v227k_15/LICENSE.md)

### Clean full rebuild

Once bootstrap has created the local runtime, SDK, and archive cache, follow
the [clean full rebuild guide](docs/rebuild-everything.md) to discard local
source changes and rebuild the renderer, input driver, ModernMenu, installer
staging payload, offline installer, and developer bundle in one sequence.

See the [building guide](docs/building.md) for target behavior, packaging
policy, path overrides, and installer details.

### Test changes

Run all automated runtime suites:

```powershell
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite All
```

Before committing or packaging, run the mandatory repository guard:

```powershell
powershell -NoProfile -File scripts/check-repository.ps1
```

The guard rejects game assets, SDK artifacts, binaries, logs, saves, and build
output that could otherwise enter source control.

### Repository map

| Path | Purpose |
| --- | --- |
| `D3D12Drv/` | Direct3D 12 renderer and OldUnreal 227 adapter |
| `XInputWinDrv/` | SDL3 gamepad backend and generated WinDrv package delta |
| `UnrealScript/ModernMenu/` | In-game options and menu integration |
| `scripts/` | Bootstrap, build, packaging, and validation automation |
| `packaging/` | Inno Setup offline installer definition |
| `manifests/` | Pinned host, archive, module, and optional bundle identities |
| `cmake/` | Deployment and packaging target declarations |
| `docs/` | Architecture, configuration, build, testing, and progress detail |
| `local/` | Ignored machine-local inputs and generated output |

Seated OpenXR VR is implemented in current source builds. RTX support and a
Vulkan driver remain roadmap components.
The renderer now has strict opt-in OpenXR mode selection, a bundled pinned
Khronos loader, diagnostics for the active runtime and HMD, and a guarded
Direct3D 12 stereo session. The frame loop now presents the completed UE1 game
through independently culled eye cameras using runtime IPD, asymmetric FOV,
recommended eye swapchains, and seated head pose. Orientation is composed onto
UE1's authoritative calculated camera before culling, preserving scripted
camera direction. Live Oculus Rift CV1 validation confirms fused depth,
correct yaw/pitch/roll, distortion-free rotation, stable spatial UI, and
gaze-aligned gamepad walking/strafing with right-stick turning. Gaze aim hooks
are present; broader weapon/runtime compatibility, swimming/flying controls and
head-collision fading remain ongoing work. See the
[seated PC VR plan](docs/pc-vr-seated.md) for validated scope and remaining work.

### Documentation

- [Current state](docs/current-state.md): supported boundary, verified commands,
  invariants, and next priorities.
- [Game features](docs/features.md): detailed end-user features and
  improvements organized by category.
- [Supported controllers](docs/controllers.md): validated devices, SDL-mapped
  compatibility, controls, transports, and fallback paths.
- [Building](docs/building.md): prerequisites, paths, source recovery,
  deployment, and packaging.
- [Clean full rebuild](docs/rebuild-everything.md): destructive cleanup and
   complete development and distribution artifact rebuild.
- [Renderer port](docs/renderer-227k.md): OldUnreal 227k_15 compatibility work.
- [Configuration](docs/configuration.md): launch syntax and renderer settings.
- [Testing](docs/testing.md): automated and manual validation procedures.
- [Localization](docs/localization.md): project-owned languages and the Greek translation workflow.
- [Engineering progress](docs/progress.md): completed milestones and evidence.
- [Project layout](docs/project-layout.md): implemented and planned components.
- [Roadmap](docs/roadmap.md): ordered future milestones for seated PC VR, RTX
  support, and a Vulkan driver.
- [Seated PC VR plan](docs/pc-vr-seated.md): scope and acceptance criteria for
  the first future milestone.
- [Permissions](PERMISSIONS.md): authorized pinned payload and exclusions.

### Roadmap

The three main future additions, in planned order, are:

1. Add optional [seated PC VR through OpenXR](docs/pc-vr-seated.md), while
   preserving flat-screen D3D12 as the default.
2. Add RTX support after the seated PC VR milestone.
3. Add a native Vulkan driver after RTX support.

See the [full roadmap](docs/roadmap.md) for scope and current status. Continue
flat-screen D3D12 regression coverage and release automation alongside these
milestones.

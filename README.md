# Unreal Revived

Unreal Revived is a modernization package for playing the original **Unreal
Gold** on current Windows PCs. It preserves the original game content and gameplay 
while adding native Direct3D 12 rendering, modern display handling, refreshed
menus, improved controls, and broad gamepad support for devices such as Xbox
Series controllers, DualShock 4, DualSense, and other
[SDL-mapped controllers](docs/controllers.md).

The project is built on the maintained **OldUnreal 227k_15 Windows x64**
runtime. Unreal Revived adds its own D3D12 renderer, ModernMenu interface,
SDL3-based controller backend, tested defaults, branding, and side-by-side
installation workflow on top of that foundation.

**Unreal Revived does not provide any original Unreal Gold game files.** It
does not include the original maps, textures, music, sounds, or other game
assets, and it cannot be used as a standalone game. To use it, you must supply
those files from your own existing Unreal Gold installation. You also need a
Windows x64 PC, a Direct3D 12-capable graphics system, and enough free space
for a separate copy. The installer reads your original files to create an
independent Unreal Revived installation and never modifies the source game.

## Game features and improvements

| Area | What players get |
| --- | --- |
| Modern rendering | Native Direct3D 12 rendering with corrected HD lightmaps, high-quality textures, alpha blending, bloom, and configurable VSync. |
| Modern displays | Widescreen and high-resolution rendering, high-refresh support, monitor-aware borderless presentation, letterboxing, and correctly mapped menu input. |
| Image quality | Off, 2x, 4x, and 8x MSAA modes with capability-based fallback, plus in-menu brightness, contrast, saturation, and detail controls. |
| Refreshed interface | Branded menus, focused Video, Input, Bindings, and HUD controls, an optional live game view behind menus, and persistent F11-toggled FPS statistics. |
| Gamepad support | SDL3 support for Xbox, DualShock, DualSense, and other mapped controllers, with adjustable dead zones, sensitivity, and fallback input paths; Xbox reconnect handling is validated. |
| Flexible controls | Up to three keyboard, mouse, or controller assignments per action, visible bindings, practical defaults, and reset controls. |
| Complete game content | Both Unreal and Return to Na Pali campaigns, multiplayer and dedicated-server support, all bundled languages, saves, and recovery renderers. |
| Safer installation | A separate offline installation that leaves the original game untouched, supports repair and update, and is configured to retain and back up saves during uninstall. |
| Modern audio | ALAudio with bundled OpenAL Soft replaces deprecated and experimental legacy audio paths. |
| Recovery options | OpenGL and XOpenGL renderers, stock WinDrv input, a recovery shortcut, and automated regression coverage provide fallback paths and release confidence. |

See the [detailed game feature guide](docs/features.md) for the complete
organized feature list and a description of each improvement.

Xbox Series and DualShock 4 controllers have been manually validated over USB
and Bluetooth without Steam Input or DS4Windows. Standard movement, looking,
menus, face and shoulder buttons, triggers, D-pad input, disconnect/reconnect,
and transport switching work through the SDL3 backend. DualSense and other
SDL-mapped controllers are supported by the backend but have not yet received
the same device-specific manual validation. See the
[supported controller guide](docs/controllers.md) for the compatibility table,
validated controls, and fallback paths.

## The original game, modernized

Unreal Revived is intended for people who want to play both **Unreal** and
**Return to Na Pali** on a current Windows PC while keeping the original game
intact. It combines the maintained OldUnreal 227k_15 runtime with a native
Direct3D 12 renderer, modern display handling, refreshed menus, and normalized
gamepad support.

The result remains the original Unreal Gold experience: both campaigns,
multiplayer and dedicated-server support, all bundled languages, saves,
and standard OpenGL/XOpenGL recovery paths are retained. Unreal Revived changes
the host, renderer, input, menus, setup, and defaults; it does not replace the
original maps, music, sounds, or other game assets.

## Safe side-by-side installation

The offline installer creates an independent installation under
`C:\Games\Unreal Revived` by default. It reads the original Unreal Gold files
from the location selected by the player and does not write to that source
directory. The bundled, pinned OldUnreal patch and Unreal Revived components
are then applied only to the new installation. No original Unreal Gold game
files are included with Unreal Revived; every required original asset is copied
locally from the player's own installation.

Setup can repair or update an existing Unreal Revived installation. Uninstall
is configured to keep save games by default and to back up saves and active
profiles before removal. Direct3D 12 is the normal renderer; OpenGL and XOpenGL
remain available as recovery choices. ALAudio with bundled OpenAL Soft is the
supported audio path.

## Availability and requirements

The flat-screen Direct3D 12 path is implemented and actively validated on
Windows x64. There is not yet a public prebuilt Unreal Revived installer linked
from this README; the repository can build it from pinned, verified inputs.

Players need:

- A Windows x64 PC.
- An existing Unreal Gold installation containing the original game assets.
- A Direct3D 12-capable graphics system for the primary renderer.
- Enough free space for a separate side-by-side copy of the game.

The installer can use a Steam installation as its source, but Steam is not used
to launch or manage the new copy afterward. Until a public prebuilt installer
is published, the repository workflow below is intended for developers and
technically experienced testers. See [current validation
status](docs/current-state.md) for the precise supported boundary.

## For developers

### Project status

The repository provides source code, automated development setup, runtime
tests, and tooling for building a fully offline installer.

| Area | Current state |
| --- | --- |
| Host runtime | OldUnreal 227k_15 on Windows x64 |
| Renderer | Native `D3D12Drv.D3D12RenderDevice` |
| Build | CMake, Visual Studio 2022, C++17 |
| ModernMenu | Implemented as a separate UnrealScript package |
| Offline installer | Implemented and built locally with Inno Setup |

### Quick start for development

#### Requirements

- Windows x64.
- Unreal Gold installed through Steam.
- winget, or the required development tools already installed.
- Enough disk space for a full disposable copy of the game, the 227k_15 SDK,
  and build output.

Clone the repository and run the bootstrap from its root:

```powershell
git clone https://github.com/kwstasg/Unreal-Revived.git
Set-Location Unreal-Revived
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1
```

The bootstrap performs the complete setup:

1. Detects Unreal Gold across registered Steam libraries.
2. Installs missing CMake, Visual Studio C++ tools, and Inno Setup through
   winget.
3. Downloads the pinned runtime and SDK from the original OldUnreal release.
4. Verifies exact archive sizes and SHA-256 hashes.
5. Creates a full disposable game copy under `local/game/`.
6. Applies the verified 227k_15 host and installs the SDK under
   `local/sdk/227k_15/`.
7. Configures and builds the D3D12 renderer and ModernMenu.
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
- [OldUnreal GitHub organization](https://github.com/OldUnreal)
- [OldUnreal 227 testing repository](https://github.com/OldUnreal/Unreal-testing)
- [Unreal v227k_15 release](https://github.com/OldUnreal/Unreal-testing/releases/tag/v227k_15)
- [Pinned v227k_15 commit](https://github.com/OldUnreal/Unreal-testing/commit/2ea5408e2aa7c955eb087a6f8d2fcce318747d2f)
- [OldUnreal-UnrealPatch227k-Windows.zip](https://github.com/OldUnreal/Unreal-testing/releases/download/v227k_15/OldUnreal-UnrealPatch227k-Windows.zip)
- [OldUnreal-UnrealPatch227k-SDK-Windows.zip](https://github.com/OldUnreal/Unreal-testing/releases/download/v227k_15/OldUnreal-UnrealPatch227k-SDK-Windows.zip)
- [OldUnreal public source](https://github.com/OldUnreal/Unreal-PubSrc)
- [OldUnreal 227 localization project](https://github.com/OldUnreal/Unreal-Localization)
- [OldUnreal 227k_15 license and third-party notices](https://github.com/OldUnreal/Unreal-testing/blob/v227k_15/LICENSE.md)

### Build and deploy manually

Bootstrap is the recommended entry point. Once the local runtime and SDK exist,
the underlying commands are:

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
cmake --build local/build --target deploy-d3d12drv --config Release
cmake --build local/build --target deploy-modern-menu --config Release
cmake --build local/build --target deploy-xinputwindrv --config Release
```

Deployment requires the `.unreal-revived-development.json` marker generated by
bootstrap. Unmarked game trees and the original Steam installation are
rejected, including when `-Force` is used.

### Build the offline installer

After bootstrap:

```powershell
cmake --build local/build --target package-offline-installer --config Release
```

The generated installer and checksum are written to
`local/package/offline-installer/output/`. The installer:

- asks for or detects the original Unreal Gold directory;
- defaults to `C:\Games\Unreal Revived`;
- copies the original assets into that side-by-side destination;
- installs the verified 227k_15 host, D3D12 renderer, and ModernMenu;
- runs without an unnecessary administrator request or visible PowerShell
  window;
- offers uninstall, repair/update, or cancel when rerun; and
- offers a default-checked **Keep save games** uninstall option while backing
  up saves and canonical profiles either way.

The installer does not write to the selected original game directory.

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

OpenXR, VR bridge, hook, launcher, and evidence directories are retained as
roadmap or compatibility surfaces. Their presence does not imply those features
are implemented.

### Documentation

- [Current state](docs/current-state.md): supported boundary, verified commands,
  invariants, and next priorities.
- [Game features](docs/features.md): detailed end-user features and
  improvements organized by category.
- [Supported controllers](docs/controllers.md): validated devices, SDL-mapped
  compatibility, controls, transports, and fallback paths.
- [Building](docs/building.md): prerequisites, paths, source recovery,
  deployment, and packaging.
- [Renderer port](docs/renderer-227k.md): OldUnreal 227k_15 compatibility work.
- [Configuration](docs/configuration.md): launch syntax and renderer settings.
- [Testing](docs/testing.md): automated and manual validation procedures.
- [Engineering progress](docs/progress.md): completed milestones and evidence.
- [Project layout](docs/project-layout.md): implemented and planned components.
- [Permissions](PERMISSIONS.md): authorized pinned payload and exclusions.

### Roadmap

1. Continue flat-screen D3D12 parity and regression coverage.
2. Add release automation and a portable profile launcher.
3. Begin native OpenXR stereo rendering, input, and comfort features after the
   flat-screen baseline remains stable.

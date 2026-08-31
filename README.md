# Unreal Revived

Unreal Revived is a Windows modernization project for the original **Unreal
Gold**. Its current focus is a native Direct3D 12 renderer, reliable modern
display behavior, and a refreshed in-game options experience on the OldUnreal
227k_15 runtime.

This is not a standalone game or a replacement asset distribution. You need an
existing Unreal Gold installation. Development and installation tools copy
those game assets into a separate directory and never modify the original
Steam installation.

## Project status

The flat-screen Direct3D 12 path is implemented and actively validated on
Windows x64. The repository currently provides source code, automated
development setup, runtime tests, and tooling for building a fully offline
installer.

| Area | Current state |
| --- | --- |
| Host runtime | OldUnreal 227k_15 on Windows x64 |
| Renderer | Native `D3D12Drv.D3D12RenderDevice` |
| Build | CMake, Visual Studio 2022, C++17 |
| ModernMenu | Implemented as a separate UnrealScript package |
| Offline installer | Implemented and built locally with Inno Setup |
| OpenXR VR | Roadmap; not implemented |
| Portable launcher | Roadmap; not implemented |

There is not yet a public prebuilt Unreal Revived installer linked from this
README. The repository can build it from the pinned, verified inputs.

## What works today

- Native Direct3D 12 rendering without XOpenGL fallback.
- Logical 2560x1440 and 3840x2160 modes, including 4K with MSAA 8x.
- Monitor-aware borderless presentation, letterboxing, and corrected menu
	pointer mapping.
- Off, 2x, 4x, and 8x MSAA with capability-based fallback.
- Corrected OldUnreal 227 HD lightmaps, RGB10A2 textures, and alpha-blended
	geometry.
- High-refresh presentation and configurable VSync.
- A ModernMenu Video page with persistent FPS statistics and antialiasing
	controls.
- Normal Unreal and Return to Na Pali campaign discovery.
- Automated map, renderer-setting, menu-profile, display-profile, and
	screenshot-regression checks.
- A side-by-side offline installer with Steam discovery, source selection,
	repair/uninstall handling, and save/profile backup.

Physical 4K presentation is implemented but has not been validated on the
current 1080p development desktop. See [current validation
status](docs/current-state.md) for the precise supported boundary.

## Quick start for development

### Requirements

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

Generated game files, downloads, SDK files, logs, and build output stay under
the ignored `local/` directory.

### Launch the development runtime

After bootstrap completes:

```powershell
Set-Location local/game/System64
.\Unreal.exe Unreal.unr ini=D3D12Test.ini userini=D3D12TestUser.ini
```

The leading `Unreal.unr` argument is required by this host when selecting the
custom profiles.

## Downloads and offline use

The original OldUnreal `v227k_15` release is the source for the
runtime and SDK archives. Verified downloads are cached in `local/downloads/`.

Previously downloaded archives can be supplied from local or removable storage.
Every input must pass the same immutable size and SHA-256 checks before use.
See [archive acquisition and offline overrides](docs/building.md#archive-acquisition-and-offline-use)
for filenames and `-RuntimeArchive`/`-SdkArchive` examples.

## OldUnreal references

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

## Build and deploy manually

Bootstrap is the recommended entry point. Once the local runtime and SDK exist,
the underlying commands are:

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
cmake --build local/build --target deploy-d3d12drv --config Release
cmake --build local/build --target deploy-modern-menu --config Release
```

Deployment requires the `.unreal-revived-development.json` marker generated by
bootstrap. Unmarked game trees and the original Steam installation are
rejected, including when `-Force` is used.

## Build the offline installer

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
- backs up saves and dedicated profiles during uninstall.

The installer does not write to the selected original game directory.

## Test changes

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

## Repository map

| Path | Purpose |
| --- | --- |
| `D3D12Drv/` | Direct3D 12 renderer and OldUnreal 227 adapter |
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

## Documentation

- [Current state](docs/current-state.md): supported boundary, verified commands,
	invariants, and next priorities.
- [Building](docs/building.md): prerequisites, paths, source recovery,
	deployment, and packaging.
- [Renderer port](docs/renderer-227k.md): OldUnreal 227k_15 compatibility work.
- [Configuration](docs/configuration.md): launch syntax and renderer settings.
- [Testing](docs/testing.md): automated and manual validation procedures.
- [Engineering progress](docs/progress.md): completed milestones and evidence.
- [Project layout](docs/project-layout.md): implemented and planned components.
- [Permissions](PERMISSIONS.md): authorized pinned payload and exclusions.

## Roadmap

1. Continue flat-screen D3D12 parity and regression coverage.
2. Add release automation and a portable profile launcher.
3. Begin native OpenXR stereo rendering, input, and comfort features after the
	 flat-screen baseline remains stable.

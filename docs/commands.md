# Command reference

In the game console, `RecenterVR` performs the same action as Preferences > VR >
Recenter VR View. Default bindings are F10 and right-stick click (Joy10). Change
or clear them under Preferences > Bindings > VR. The action also works while
menus are open and has no view effect outside a running VR session.

Run these commands from the Unreal Revived repository root in PowerShell.
Generated runtimes, builds, logs, downloads, and packages stay under the
ignored `local/` directory.

For a quiet, non-destructive rebuild of every development and distribution
artifact, run:

```powershell
powershell -NoProfile -File scripts/rebuild-all.ps1
```

Detailed output is retained under `local/logs/rebuild/`. Use the
[clean full rebuild guide](rebuild-everything.md) when uncommitted source must
also be discarded.

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
modifying an unmarked directory or the original game installation.

## Configure and compile

Configure the canonical Visual Studio x64 build directory (required before any
`cmake --build` command, including packaging):

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
cmake --build local/build --target deploy-old-weapons --config Release
```

These targets are created when the configured game root already contains
`System64\Unreal.exe`; run bootstrap before configuring a new checkout.
The ModernMenu target compiles `ModernMenu.u`, updates the development INIs,
and refreshes the normal and recovery shortcuts. Deploy targets require the
development marker created by bootstrap.
Development menu builds include regression fixtures. Installer staging always
rebuilds with `scripts/build-modern-menu.ps1 -GameRoot local/game -Production`,
which excludes `*Test*.uc` from staged sources and verifies the compiled package
contains none of their class names. Packaging leaves this production package in
the development runtime; run `deploy-modern-menu` again before fixture tests.
The Old Weapons target compiles `OldWeapons.u` from the pinned SDK and mirrors
its `.int` registration into `System/` for New Game discovery.

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

Native regression suites (their generated directories may have been cleaned):

```powershell
cmake -S D3D12Drv/tests -B local/build-vr-tests -A x64
cmake --build local/build-vr-tests --config Release
ctest --test-dir local/build-vr-tests -C Release --output-on-failure
cmake -S XInputWinDrv/tests -B local/build-input-tests -A x64
cmake --build local/build-input-tests --config Release
ctest --test-dir local/build-input-tests -C Release --output-on-failure
```

Configure `local/build` first so the pinned OpenXR headers are available.

Run the required repository safety check before packaging or committing:

```powershell
powershell -NoProfile -File scripts/check-repository.ps1
```

Create a read-only content inventory under a timestamped directory in
`local/logs/content-audit/`:

```powershell
powershell -NoProfile -File scripts/audit-game-content.ps1
```

## Clean full rebuild

Use `scripts/rebuild-all.ps1` to recreate `local/build/`, compile and deploy
every component, build both distribution packages, and verify the outputs
without changing source files. Use `-ShowOutput` when live command output is
needed in addition to the retained log.

Use the [clean full rebuild guide](rebuild-everything.md) to discard
uncommitted source changes before running the same build stages.

To recreate the entire disposable runtime instead, rerun bootstrap with
`-Force`. This replaces the marked `local/game` development copy, so preserve
any local saves or settings you need first.

## Branding commands

Regenerate the tracked logo, installer, runtime, and icon derivatives without
replacing the authored menu background:

```powershell
powershell -NoProfile -File scripts/build-unreal-revived-branding.ps1 -BrandingOnly
```

To regenerate the menu artwork too, `-DeriveBranding` requires
`-MenuBackgroundSource` and rewrites tracked banners and the icon as well as the
menu artwork. Review those changes before keeping them:

```powershell
powershell -NoProfile -File scripts/build-unreal-revived-branding.ps1 -MenuBackgroundSource <path-to-16x9-image> -DeriveBranding
```

See [building.md](building.md) for setup and packaging details and
[testing.md](testing.md) for validation expectations.

## Runtime world/UI boundary command

`D3D12 BEGINUIPASS` ends world rendering and begins HUD/UWindow rendering for
the current frame. The renderer captures the completed world once, sends every
world-only post-process effect through that shared image, and records later UI
draw coverage in a dedicated composition mask. At presentation, marked pixels
come directly from the untouched completed frame, while unmarked pixels come
from the processed world image. This keeps opaque and translucent UI free of
bloom, chromatic aberration, and reconstruction artifacts.

ModernGameHud, ModernUPakHud and ModernIntroHud issue the command at the start of
`PostRender`. A custom HUD that draws through another path must issue it exactly
once, after its last world draw and before its first HUD or UI draw:

```unrealscript
PlayerOwner.ConsoleCommand("D3D12 BEGINUIPASS");
```

Return to Na Pali's stock `UPakHUD` is adapted by `ModernUPakHud`, including
after campaign travel and loading saves. Its health, armor, ammo, inventory,
and weapon hints use the shared VR UI panel; weapon overlays and the crosshair
retain the eye projection. The adapter inherits the expansion's cinematic
flags and uses stock rendering when the headset pose is inactive. Custom
UPak HUD subclasses are left intact.

Future world-only post-process effects must reuse this boundary, the captured
world image, and the existing UI composition step. They must not introduce
effect-specific world/UI detection.

## Shared VR UI panel

| Command | Behavior |
| --- | --- |
| `D3D12 VRHUDDISTANCE <metres>` | Save and apply distance, clamped to 0.50-5.00, without recentering or compensating physical size. |
| `D3D12 VRHUDSCALE <factor>` | Save and apply physical scale, clamped to 0.50-2.00, around the panel center. |
| `D3D12 VRPLAYERHEIGHT <meters>` | Save and apply a vertical VR viewpoint offset from -0.75 to 1.50 m; default 0.00 preserves the original camera height. Also available as Height Offset in Preferences > VR. |
| `D3D12 VRWORLDSCALE <factor>` | Save and apply perceived world size from 0.40 to 2.50; default 1.00 is 100%. Larger values make the world appear larger. Also available as World Size in Preferences > VR. |
| `D3D12 RESETVRUIANCHOR` | Explicitly recapture upright heading and eye-level placement for all UI. |
| `D3D12 RECENTERVR` | Queue combined view/UI recenter for the next valid tracking frame; level software pitch/roll and retain current horizontal gaze as forward. |
| `D3D12 VRLAUNCHMODE` | Return `-vr` or `-novr` for mode-preserving restart, including unavailable-headset fallback. |
| `D3D12 BEGINVRUIPASS` / `D3D12 ENDVRUIPASS` | Internal balanced canvas-projection boundary; world/weapon rendering stays outside it. |

Preferences > VR exposes HUD distance and scale, player height offset, world size,
and the combined `RECENTERVR` action. Height defaults to a zero offset from the
game's existing camera; world size defaults to 100%. Both settings apply live,
persist in the renderer configuration, and have reset buttons.

World size scales stereo eye separation, tracked movement, first-person camera
height above the pawn's feet, and the displayed weapon together. Above 100% makes
the player feel smaller in the map; below 100% makes the player feel bigger.
Height Offset remains an additional adjustment. Pawn collision, movement speed,
and gameplay weapon state are unchanged; view-target and third-person cameras
keep their authored base height.

The VR camera hook now fades the headset world image near blocking geometry,
including when height/scale adjustments place the camera inside a ceiling or
floor. It traces from the pawn (or the authored camera for alternate views) to
the shared head center and uses a scaled 12 cm comfort volume for progressive
fade. Blocking BSP, movers and decorations participate; pawns, triggers and
water volumes do not. Tracking is never clamped. The separate HUD/menu panel
stays visible for recovery. `D3D12 VRHEADCOLLISION <0-1>` is a transient internal
camera-to-renderer command, reset for each eye draw, not a saved preference.
The startup checkbox has been removed; use the normal/VR shortcuts. Opening/closing menus does not
recenter or change panel geometry. See [the maintenance contract](vr-ui-recovery-design.md).

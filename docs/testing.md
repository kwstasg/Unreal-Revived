# Testing

Runtime smoke automation covers map loading, selected renderer configurations,
menu state profiles, display profiles, clean D3D12 startup and shutdown, and
known log failure signatures. Screenshots remain necessary where logs cannot
establish visual correctness. Record significant results in
[`progress.md`](progress.md).

## Repository guard

```powershell
powershell -NoProfile -File scripts/check-repository.ps1
```

This must pass before committing or packaging. It ensures ignored game, SDK,
reference, binary, log, save, and build artifacts have not entered the project.

## Content audit

Inventory the effective disposable runtime against its recorded original-game
source and the extracted pinned patch:

```powershell
powershell -NoProfile -File scripts/audit-game-content.ps1
```

The read-only audit writes `files.csv`, `inventory.json`, and `report.md` under
`local/logs/content-audit/<timestamp>/`. Each effective runtime file records its
size, SHA-256, origin, conservative classification, rationale, and matching
engine `Paths=` or `LangPaths=` rule where applicable. The reported file and
byte totals are reconciled against direct filesystem enumeration before output
is accepted.

`candidate` means suitable for reversible quarantine testing, not approved for
removal. `unknown` always means retain. Runtime logs, saves, and other generated
state are included, so exact totals may change between snapshots. The audit
does not modify the original Steam installation, disposable runtime, extracted
patch, installer copy rules, or staged payload.

The installer currently consumes
`manifests/content/unreal-revived-install-content-v1.json`. Validate a policy
change first in the separate `local/game-content-audit/` runtime, then assemble
the original copy, staged patch, and installer payload under an ignored scratch
root and run the content suite with `UE1_GAME_ROOT` pointed at that root.
For renderer policy changes, enumerate `Object=(Name=...RenderDevice...)`
entries across the final tree and verify the set is exactly D3D12Drv,
OpenGLDrv, and XOpenGLDrv. Confirm every localized `Startup.*` file and the
mirrored `System/Startup.int` and `System64/Startup.int` omit descriptions for
removed renderer classes.

Launch a disposable profile with `[FirstRun] FirstRun=0` and verify the native
configuration window initially selects Direct3D 12. Selecting it must display
the Unreal Revived D3D12 recommendation. Confirm the window loads the branded
343x84 `Help/SetupLogo.bmp`, and inspect the tracked shortcut ICO for 16, 24,
32, 48, 64, 128, and 256 pixel frames.

Open the in-game menu with Escape while `ModernMenu.ModernRootWindow` is active.
Confirm the Unreal Revived background renders as a seamless 4x3 tile grid, the
menu and status bars remain visible, and the 16:9 source remains proportional.
A 16:9 viewport must fill without cropping or stretching. Other
viewport ratios must use centered cover cropping rather than stretching or
image-specific side extensions. The runtime log must contain no missing
texture or package warnings.

Open the Help menu and confirm **Technical Support** appears between **Unreal
Gold Credits** and the separator above **About Epic Games**. There must not be
two consecutive separators.

During the Unreal intro flyby, confirm the original Epic, GT Interactive,
Digital Extremes, and Unreal logos remain visible while the dynamic OpenAL and
PhysX driver-credit logos are absent. Start a normal gameplay map afterward and
confirm its HUD is unchanged.

After source-derived branding changes, confirm `MenuBackground.bmp` is a
3840x2160 24-bit bitmap and `Logo.bmp` is a 719x200 24-bit bitmap. Inspect the
ICO directory for 16, 24, 32, 48, 64, 128, and 256 pixel frames and verify the
circular crest has transparent corners.

For audio policy changes, enumerate `Engine.AudioSubsystem` registrations
across every locale and require ALAudio to be the only result. Confirm the
final `System64` tree retains `ALAudio.dll`, `OpenAL32.dll`, `libxmp.dll`,
`sndfile.dll`, `mpg123.dll`, and `libmp3lame.dll`. Each representative runtime
log must contain both `Bound to ALAudio.dll` and `ALAudio subsystem initialized.`

For `System` pruning, inspect PE machine fields before excluding native files.
The supported x64 installation must retain `System/*.u` and localized `.int`
registrations even when direct x86 `.dll` and `.exe` files are omitted. Run the
full D3D12 suite and start a dedicated server with
`System64/UCC.exe server DmDeck16?game=UnrealShare.DeathMatchGame`; require
`IpDrv`, `UWebAdmin`, the expected mutator, and port binding. The pinned host
currently logs a missing optional `UnrealIntegrity` package in both full and
filtered runtimes; do not treat other missing-package warnings as baseline.

Use explicit inputs when evaluating a runtime other than `local/game/`:

```powershell
powershell -NoProfile -File scripts/audit-game-content.ps1 `
  -RuntimeRoot <runtime> `
  -OriginalGameRoot <original> `
  -PatchRoot <extracted-patch> `
  -OutputRoot <ignored-report-directory>
```

## Build validation

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
cmake --build local/build --target deploy-d3d12drv --config Release
cmake --build local/build --target deploy-modern-menu --config Release
```

The deploy target is available only when the configured game root contains
`System64/Unreal.exe`.

## Runtime launch

From the disposable runtime's `System64` directory, use:

```powershell
.\Unreal.exe Unreal.unr ini=D3D12Test.ini userini=D3D12TestUser.ini
```

Confirm the process loads `D3D12Drv.dll` and does not load `XOpenGLDrv.dll` as a
fallback. Inspect `Unreal.log` after shutdown for initialization failures,
Direct3D errors, assertions, or unexpected relaunches.

## Automated runtime checks

Run the content suite from the repository root:

```powershell
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite Content
```

Run renderer-setting and menu/display profile checks separately, or run every
suite together:

```powershell
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite Settings
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite MenuDisplay
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite All
```

For a focused check, provide one or more map names:

```powershell
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Maps NyLeve -RunSeconds 8
```

Add opt-in present-cadence measurement to any suite or focused run:

```powershell
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 `
  -Maps NyLeve `
  -RunSeconds 8 `
  -MeasurePerformance
```

Performance mode foregrounds the game, ignores the first 30 present intervals,
and records cumulative average, median, p95, p99, maximum frame time, and
average FPS in `results.csv`. It requires at least one 120-sample summary and
fails when the renderer does not emit telemetry. The metric is present-to-present
wall-clock cadence, so it includes engine work, renderer submission, and frame
pacing; it is not isolated GPU execution time. Compare like-for-like runs and
use a demanding setting or resolution that falls below the host's approximately
240 FPS ceiling when measuring GPU headroom.

Capture screenshots without comparing them:

```powershell
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite Content -ScreenshotMode Capture
```

Create or deliberately replace ignored local baselines only after reviewing the
captured images, then compare future runs:

```powershell
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite Content -ScreenshotMode Update
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite Content -ScreenshotMode Compare
```

Baselines are stored under `local/logs/screenshot-baselines/` and are specific
to the validated host, display, game data, profile, and capture timing. They are
not committed because they contain game assets. `Update` is intentionally
explicit so a normal test run cannot bless changed output.

Comparison samples the central gameplay region, excluding dynamic title/FPS
and lower HUD bands. It fails when mean RGB channel delta exceeds `12` or more
than `12%` of sampled pixels differ by over `32` channel levels. Override these
thresholds only when calibration evidence justifies it. `Vortex2` and
`Terraniux` are captured but reported as `SkippedDynamic` because their camera
or player state changes between runs.

The harness works only in the ignored disposable runtime. It copies
`D3D12Test.ini` to a temporary automation profile, launches maps directly,
requests a normal window close, validates `Unreal.log`, and stores each run
under `local/logs/automated-<timestamp>/`. It verifies that the normal profile
and user profile did not change and never modifies the normal game shortcut.
Screenshot mode activates Unreal briefly and captures its exact window bounds
from the desktop because this 227 build did not produce an image through F9,
`EXEC=SHOT`, or `LEVACT_SaveScreenshot`. Avoid covering the game window while
capture mode runs. A passing comparison detects broad visual changes but does
not replace review for subtle rendering errors.

Set `UE1_GAME_ROOT` explicitly when testing another disposable tree. A
persistent override can otherwise direct the harness to an older staged
renderer even after `deploy-d3d12drv` updates `local/game`.

Use automation for map, renderer-setting, menu-profile, and display-profile
smoke checks. UWindow controls do not expose Windows UI Automation elements and
ignore background Win32 input messages, so deterministic external click tests
are not available. Retained screenshots provide the current menu-layout and
mouse-alignment evidence; future interactive revalidation is requested only
when a menu or input behavior changes and cannot be established another way.

## Rendering checklist

- Verify BSP surfaces and actors render in representative indoor and outdoor
  maps.
- Verify HD lightmaps have expected color and intensity, with no black or
  magenta corruption.
- Verify masked textures, translucent surfaces, fog maps, coronas, detail
  textures, and volumetric lighting.
- Verify realtime and scripted textures update rather than retaining stale
  frames.
- Verify precaching enabled and disabled.
- Verify screenshots with gamma correction enabled and disabled.
- Exercise `Off`, `MSAA_2x`, `MSAA_4x`, and `MSAA_8x` antialiasing and inspect
  the requested/effective sample-count diagnostic.
- Exercise VSync enabled and disabled and confirm intended high-refresh or
  uncapped presentation behavior with an external frame-rate measurement.

## Resolution and window checklist

- Start at the desktop's native resolution.
- Select at least one lower 16:9 resolution in borderless fullscreen.
- Confirm the image remains centered and correctly letterboxed.
- Confirm menu hover and click targets align at native and lower resolutions.
- Confirm the lower logical resolution is not reset to desktop dimensions.
- Exercise logical 2560x1440 and 3840x2160; include 3840x2160 with MSAA 8x when
  the GPU memory budget permits.
- On 4K hardware or with DSR enabled, confirm the physical swap chain and
  borderless window also use 3840x2160.
- Switch between windowed, fullscreen, and borderless modes.
- Alt-tab repeatedly and verify rendering and input recover.
- Resize a window and verify swap-chain recreation does not hang or crash.

## Startup and campaign checklist

- Launch through `Unreal.unr` without forcing a campaign map.
- Open Game, then New Game.
- Confirm both `Unreal` and `Return to Na Pali` are listed.
- Start Unreal and confirm travel begins at `Vortex2`.
- Start Return to Na Pali and confirm travel begins at `Intro1`.
- Confirm campaign screenshots and skill selection render correctly.

If the campaign combo is empty, verify that `System/UnrealShare.int` and
`System/UPak.int` match the files in `SystemLocalized/int/`. The deployment
target maintains those copies for the disposable runtime.

## Video menu checklist

- Open **Options > Preferences > Video**.
- Confirm **Show FPS Statistics** appears directly below **Show Fullscreen**
  and scrolls with the other video controls.
- With D3D12Drv active, confirm **Antialiasing** offers Off, 2x, 4x, and 8x and
  retains the selected mode after reopening Video preferences.
- Enable it and confirm the built-in TimeDemo statistics appear during play.
- Disable it and confirm the overlay is removed.
- Change a setting, use **Restart**, and confirm the relaunched process retains
  the `D3D12Test.ini` and `D3D12TestUser.ini` command-line arguments.
- In an installer-created runtime, use **Restart** and confirm the relaunched
  process retains `UnrealRevived.ini` and `UnrealRevivedUser.ini`, does not open
  First-Time Configuration, and keeps the ModernMenu root and saved settings.
- Reopen Video preferences after Restart and confirm the FPS checkbox retains
  its saved state.
- Open **Options > Preferences > Game** and confirm **Console** displays
  **Standard Unreal Console** and cannot open or select another console.
- Confirm Restart leaves `Engine.Engine.Console=UMenu.UnrealConsole` and Escape
  continues to open the windowed UMenu interface.

## Installer uninstall checklist

- Create a sentinel file under the installed `Save` directory.
- Start interactive uninstall and confirm **Keep save games** is checked by
  default in the native uninstall window.
- Click **Uninstall** and confirm the same window transitions to progress with
  no additional confirmation dialog.
- Complete uninstall and confirm only the retained `Save` directory remains
  under the former installation path, including the sentinel file.
- Confirm a timestamped `Unreal Revived Backup` under Documents contains the
  saves and dedicated profiles.
- Reinstall and confirm the retained saves remain available.
- In an isolated test installation, uncheck **Keep save games**, complete
  uninstall, and confirm the installation copy is removed after backup.
- Confirm an explicit `/SILENT` uninstall retains saves without prompting.

## Reporting results

A useful test record includes:

- OldUnreal host and architecture;
- build configuration and commit or working-tree state;
- GPU, driver, desktop resolution, and refresh rate;
- renderer settings changed from defaults;
- checks performed and their outcomes;
- relevant log or screenshot paths under ignored `local/` storage.

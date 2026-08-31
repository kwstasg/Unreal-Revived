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

The harness works only in the ignored disposable runtime. It copies
`D3D12Test.ini` to a temporary automation profile, launches maps directly,
requests a normal window close, validates `Unreal.log`, and stores each run
under `local/logs/automated-<timestamp>/`. It verifies that the normal profile
did not change and never modifies the normal game shortcut. A passing result
proves only that frames were presented without a detected crash or log error;
it does not prove visual correctness.

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
- Exercise `Off`, `MSAA_2x`, and `MSAA_4x` antialiasing.
- Exercise VSync enabled and disabled and confirm intended high-refresh or
  uncapped presentation behavior with an external frame-rate measurement.

## Resolution and window checklist

- Start at the desktop's native resolution.
- Select at least one lower 16:9 resolution in borderless fullscreen.
- Confirm the image remains centered and correctly letterboxed.
- Confirm menu hover and click targets align at native and lower resolutions.
- Confirm the lower logical resolution is not reset to desktop dimensions.
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
- Enable it and confirm the built-in TimeDemo statistics appear during play.
- Disable it and confirm the overlay is removed.
- Change a setting, use **Restart**, and confirm the relaunched process retains
  the `D3D12Test.ini` and `D3D12TestUser.ini` command-line arguments.
- Reopen Video preferences after Restart and confirm the FPS checkbox retains
  its saved state.
- Open **Options > Preferences > Game** and confirm **Console** displays
  **Standard Unreal Console** and cannot open or select another console.
- Confirm Restart leaves `Engine.Engine.Console=UMenu.UnrealConsole` and Escape
  continues to open the windowed UMenu interface.

## Reporting results

A useful test record includes:

- OldUnreal host and architecture;
- build configuration and commit or working-tree state;
- GPU, driver, desktop resolution, and refresh rate;
- renderer settings changed from defaults;
- checks performed and their outcomes;
- relevant log or screenshot paths under ignored `local/` storage.

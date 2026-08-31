# Current state

Use this page to resume work after a context reset. It records the supported
boundary and points to the authoritative detail without depending on chat
history.

## Read first

1. Read [`progress.md`](progress.md) for completed milestones and validation.
2. Read [`renderer-227k.md`](renderer-227k.md) before changing renderer or
   viewport behavior.
3. Read [`building.md`](building.md) before configuring or deploying.
4. Read [`testing.md`](testing.md) before declaring a behavior complete.
5. Follow the repository and renderer rules under `.github/`.

## Supported boundary

- Host: OldUnreal 227k_15, Windows x64.
- Renderer: native `D3D12Drv.D3D12RenderDevice`.
- Build system: CMake with Visual Studio 2022 and C++17.
- Runtime model: ignored disposable installation under `local/game/`.
- SDK model: ignored 227k_15 SDK under `local/sdk/227k_15/`.
- Development setup: one-command bootstrap using the original pinned OldUnreal
  runtime and SDK downloads plus the locally installed Steam game. Verified
  MEGA links are recorded as manual recovery mirrors.
- Original Steam installation: recovery source only; never modify it.
- Distribution model: the fully offline Unreal Revived Inno Setup executable
  creates a side-by-side installation under `C:\Games\Unreal Revived` by
  default from the user's selected original-game directory and the bundled
  pinned 227k_15 patch. Steam discovery prefills but does not lock that source.
- Packaging authorization: redistribution, mirroring, and offline bundling of
  the pinned OldUnreal 227k_15 Windows patch is confirmed in
  [`../PERMISSIONS.md`](../PERMISSIONS.md) and must not be reopened as a blocker.

The renderer builds, deploys, and loads without XOpenGL fallback. Native and
lower logical resolutions, borderless letterboxing, menu coordinate mapping,
HD lightmaps, RGB10A2 textures, 227 alpha-blended geometry, normal startup, and
campaign metadata discovery have been implemented and validated. The Video
preferences page exposes a persistent checkbox for 227's built-in FPS
statistics and the D3D12 Off/2x/4x/8x antialiasing modes. Logical 2560x1440 and
3840x2160 rendering, including 4K with MSAA 8x, is validated on the current
RTX 3060 host. Borderless physical sizing follows the monitor containing the
game window; true physical 4K output remains unvalidated on the current 1080p
desktop.

OpenXR rendering, VR input, comfort features, and the portable launcher are not
implemented. The offline installer includes visual source selection, hidden
original-game copying, and direct Inno installation of the build-time-extracted
patch tree; dedicated launch profiles, Start Menu shortcut, and uninstall
backup are implemented. Rerunning Setup offers uninstall, repair/update, or
cancel. Runtime smoke automation exercises representative maps, renderer
settings, menu state profiles, and display profiles. Retained screenshots cover
the currently validated menu layout and input alignment; external click
automation is unavailable because UWindow exposes no automation elements and
ignores background window messages.

Optional window screenshot capture and tolerant sampled-pixel comparison are
available through `scripts/test-d3d12-runtime.ps1`. Ignored host-specific
baselines live under `local/logs/screenshot-baselines/`; `Vortex2` and
`Terraniux` remain capture-only because their camera or player state is
nondeterministic.

## Verified commands

From the repository root:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
cmake --build local/build --target deploy-d3d12drv --config Release
cmake --build local/build --target deploy-modern-menu --config Release
cmake --build local/build --target package-offline-installer --config Release
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite All
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite Content -ScreenshotMode Compare
powershell -NoProfile -File scripts/check-repository.ps1
```

From the disposable runtime's `System64` directory:

```powershell
.\Unreal.exe Unreal.unr ini=D3D12Test.ini userini=D3D12TestUser.ini
```

The leading `Unreal.unr` token is required. A command beginning with bare
`ini=` is parsed as a network URL by this executable, while `-ini=` did not
select the intended profile during testing.

## Non-obvious invariants

- Keep logical viewport dimensions separate from physical desktop presentation
  dimensions in borderless mode.
- Preserve and forward the original viewport callback. Restore it only if the
  renderer's wrapper is still installed.
- Keep 227-specific host adaptations behind `UNREAL_227` where practical.
- Do not enable the inherited lightmap atlas for this target.
- Keep the corrected 227 texture enum, realtime `RenderTag`, RGB10A2 channel
  layout, lightmap conversion, and `PF_AlphaBlend` pipeline intact unless
  replacement behavior is validated.
- The New Game menu's `IntDescIterator` reads campaign registrations from
  `System/`. Deployment must mirror localized `UnrealShare.int` and `UPak.int`
  there from `SystemLocalized/int/`.
- Early startup recovery runs before normal localization lookup is reliable.
  Deployment must mirror `Startup.int` into both `System/` and `System64/`.
- A profile generated from the pristine patch default must set
  `[FirstRun] FirstRun=227`; leaving `FirstRun=yes` invokes an unusable startup
  wizard before the normal localization paths are active.
- Never track files under `local/` or deploy into the original game install.
- Deployment and runtime automation require the development marker generated
  by bootstrap; `-Force` cannot authorize an unmarked destination.
- Archive and binary source-control exclusions do not prevent release tooling
  from embedding the pinned 227k_15 payload from ignored local inputs.

## Next priorities

1. Add deterministic camera control for currently dynamic visual cases.
2. Expand automated checks where engine integration permits stronger
  assertions than process and log validation.
3. Improve installer UX and release-signing automation.
4. Begin OpenXR architecture only after flat-screen behavior has a stable
   validation baseline.

## Updating the handoff

When behavior changes, update the focused technical document and
[`progress.md`](progress.md). Update this page only when the supported boundary,
critical invariant, verified command, or next priority changes.
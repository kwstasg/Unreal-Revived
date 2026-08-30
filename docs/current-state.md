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
- Original Steam installation: recovery source only; never modify it.

The renderer builds, deploys, and loads without XOpenGL fallback. Native and
lower logical resolutions, borderless letterboxing, menu coordinate mapping,
HD lightmaps, normal startup, and campaign metadata discovery have been
implemented and validated.

OpenXR rendering, VR input, comfort features, the portable launcher, and
automated renderer tests are not implemented.

## Verified commands

From the repository root:

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
cmake --build local/build --target deploy-d3d12drv --config Release
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
- Keep the corrected 227 texture enum, realtime `RenderTag`, and RGB10A2
  lightmap paths intact unless replacement behavior is validated.
- The New Game menu's `IntDescIterator` reads campaign registrations from
  `System/`. Deployment must mirror localized `UnrealShare.int` and `UPak.int`
  there from `SystemLocalized/int/`.
- Never track files under `local/` or deploy into the original game install.

## Next priorities

1. Broaden flat-screen D3D12 regression coverage across maps, texture formats,
   display modes, and renderer settings.
2. Add repeatable automated checks where engine integration permits them.
3. Design the portable installation and profile launcher.
4. Begin OpenXR architecture only after flat-screen behavior has a stable
   validation baseline.

## Updating the handoff

When behavior changes, update the focused technical document and
[`progress.md`](progress.md). Update this page only when the supported boundary,
critical invariant, verified command, or next priority changes.
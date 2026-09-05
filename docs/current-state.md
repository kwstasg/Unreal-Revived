# Current state

Use this page to resume work after a context reset. It records the supported
boundary and points to the authoritative detail without depending on chat
history.

## Read first

1. Read [`progress.md`](progress.md) for completed milestones and validation.
2. Use [`commands.md`](commands.md) for the common build, deploy, launch, test,
  and packaging commands.
3. Read [`renderer-227k.md`](renderer-227k.md) before changing renderer or
   viewport behavior.
4. Read [`building.md`](building.md) before configuring or deploying.
5. Read [`testing.md`](testing.md) before declaring a behavior complete.
6. Follow the repository and renderer rules under `.github/`.

## Supported boundary

- Host: OldUnreal 227k_15, Windows x64.
- Renderer: native `D3D12Drv.D3D12RenderDevice`.
- Build system: CMake with Visual Studio 2022 and C++17.
- Runtime model: ignored disposable installation under `local/game/`.
- SDK model: ignored 227k_15 SDK under `local/sdk/227k_15/`.
- Development setup: one-command bootstrap using the original pinned OldUnreal
  runtime and SDK downloads plus a detected `C:\Unreal` or Steam installation,
  or an explicitly selected original-game directory. Missing-source errors link
  developers to OldUnreal's official full-game installer.
- Original Unreal Gold installation: recovery source only; never modify it.
- Distribution model: the fully offline Unreal Revived Inno Setup executable
  creates a side-by-side installation under `C:\Games\Unreal Revived` by
  default from the user's selected original-game directory and the bundled
  pinned 227k_15 patch. Setup detects `C:\Unreal` and Steam, links to
  OldUnreal's official full-game installer when neither exists, and can detect
  the resulting installation without restarting Setup.
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
manifest-filtered original-game copying, and direct Inno installation of the
filtered build-time-extracted patch tree. The policy removes only validated
historical distribution media, copied state, and obsolete D3D7, D3D9, Glide,
software, Metal, and ICBINDx11 renderers while retaining both campaigns,
multiplayer/server support, all languages, standard OpenGL, and XOpenGL
recovery. Video Preferences and recovery register only Direct3D 12, OpenGL,
and XOpenGL. Direct x86 binaries under `System` and end-user editor/setup assets
are filtered, while the required `.u` packages, localized registrations, x64
native modules, and `System64/UCC.exe` dedicated-server entry point remain.
ALAudio with bundled OpenAL Soft is the sole supported audio engine; deprecated
Galaxy and experimental SwFMOD are filtered with their registrations. The
first-time configuration page defaults to D3D12, describes it in every locale,
and uses tracked original Unreal Revived artwork; installed shortcuts use the
tracked project-owned multi-resolution icon. The in-game menu desktop uses a
tracked Unreal Revived background embedded in `ModernMenu.u`. Dedicated
development launch profiles, canonical argument-free installed startup, Start
Menu shortcut, and uninstall
backup are implemented. Interactive uninstall keeps saves by default through a
checked option embedded in the native uninstall window, which transitions into
progress in place and states that the original source and OldUnreal downloads
remain untouched; explicit silent uninstall uses the same default. Rerunning Setup opens that interactive uninstaller for uninstall,
or offers repair/update and cancel. A retained save-only installation directory is accepted on
reinstall and protected from the original-game copy. Runtime smoke automation exercises representative maps, renderer
settings, menu state profiles, and display profiles. Retained screenshots cover
the currently validated menu layout and input alignment; external click
automation is unavailable because UWindow exposes no automation elements and
ignores background window messages.

Optional window screenshot capture and tolerant sampled-pixel comparison are
available through `scripts/test-d3d12-runtime.ps1`. Ignored host-specific
baselines live under `local/logs/screenshot-baselines/`; `Vortex2` and
`Terraniux` remain capture-only because their camera or player state is
nondeterministic.

A side-by-side `XInputWinDrv.dll` is staged reproducibly from the pinned SDK,
built for Windows x64, and selected by fresh generated profiles. A pinned,
statically linked SDL3 Gamepad backend now normalizes Xbox, DualShock 4,
DualSense, and other mapped controllers into Unreal's existing joystick keys;
the dynamically loaded system XInput path remains as fallback. It supports
automatic controller selection and WinMM fallback, and keeps stock WinDrv
available for recovery. A DualShock 4 v2 was manually validated without Steam
or DS4Windows over Bluetooth and USB for standard menu and gameplay controls,
including sticks, D-pad, face and shoulder buttons, triggers, Share, Options,
and stick clicks. Hotplug, binding persistence, rumble, touchpad, gyro, and
lightbar behavior remain unvalidated. An Xbox Series controller was also
manually regression-tested over Bluetooth and USB; SDL selected it natively on
both transports and its standard menu and gameplay controls remained correct.
Disconnect handling emits button releases and neutral axes before fallback.
Xbox disconnect/reconnect, USB/Bluetooth transport switching, and disconnect
while holding gameplay input were manually validated without stuck movement or
fire, and input resumed after reconnection.
ModernMenu provides focused Input and Bindings
pages plus compiled controller routing for menu toggle, focus navigation,
activation, return, tab switching, scrolling, combo boxes, slider reset, and
binding capture. Modal dialogs now own controller focus and expose an outlined
default selection. Raw menu axes are separated from elapsed-time-normalized
gameplay axes, preserving the 60 FPS controller feel at uncapped rates while
preventing analog movement from entering UE1's double-tap dodge detector.
Fresh environments explicitly inherit the validated mouse and controller
option defaults. Menu-shell navigation, pull-down recovery, combo interaction,
direct slider reset, modal selection, consistent movement/look at about 240 and
over 1000 FPS, keyboard-only dodge, and mouse look were manually validated with
an Xbox controller. Focused sliders use an independently tuned fast one-step
repeat cadence that was also manually confirmed.
The stock New Game dialog now exposes every visible action in visual controller
order, and Start launches through its original click path. Load and Save slots
also traverse, wrap, scroll, and activate correctly, with Restart appended to
the Load order; these flows were manually confirmed. Advanced and Mutator
dialogs have initial combo, list, and cross-window tab handling compiled, but
their complete controller workflows remain pending and are not a supported
claim yet.
Binding persistence and broader lifecycle coverage remain unvalidated and are
not yet supported claims.

## Verified commands

See the focused [`commands.md`](commands.md) reference for common workflows and
important side effects. The core verified commands are:

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
.\Unreal.exe Unreal.unr?Game=ModernMenu.ModernIntro ini=D3D12Test.ini userini=D3D12TestUser.ini
```

The leading `Unreal.unr` token is required. A command beginning with bare
`ini=` is parsed as a network URL by this executable, while `-ini=` did not
select the intended profile during testing.

The explicit command above applies only to the disposable development runtime.
The installed product uses canonical `Unreal.ini` and `User.ini` profiles and
starts from bare `System64\Unreal.exe`. A clean isolated install validated that
argument-free path with `ModernMenu.ModernIntro`, D3D12, XInput, and the
ModernMenu root window active.

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
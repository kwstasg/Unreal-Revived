# Current state

Use this page to resume work after a context reset. It records the supported
boundary and points to the authoritative detail without depending on chat
history.

## Current 0.9.0 release candidate

The source version is now **0.9.0**. The owner confirmed the maintenance cleanup
looks correct in game. [End-user highlights](release-0.9.0.md) and the changelog
describe changes since 0.8.0. Built from `local/build`, the installer is
`local/package/offline-installer/output/UnrealRevived-Setup-0.9.0.exe`.
The isolated 0.9.0 installation lifecycle passed; installed-build owner visual
acceptance remains pending. See [validation record](release-0.9.0-validation.md).
0.8.0 remains the published release; rebuilding disposable staging replaced its
previous local installer. No push/publication.

The owner rejected the motion-to-gaze weapon fix `d267b77`: the original offset
remained and more weapons were affected. `129c000` reverts that attempt, including
its changed geometry reference poses. The previous weapon behavior is restored;
the original save-load offset has not recurred in the owner's latest retest but
has no confirmed root-cause fix. Preserve existing calibration
and establish the equipped/rendered failure before another change.

Preferences > VR now offers Smooth (unchanged default), Instant Snap and Smooth
Snap, with a 15-90-degree snap-angle slider defaulting to 30 degrees. The owner
accepted turning behavior as perfect and requested these snap-mode names.
The [automatic HUD recovery](vr-standing-and-turning.md) retains a stable anchor
for small seated motion and follows sustained larger translations/turns without
a new option. Open menus remain stationary after conditional opening recovery.
Recenter preserves tracked height across sitting/standing within the running XR
session. The owner accepted the result as looking awesome on CV1 at `b69ae2c`.
Preserve this automatic behavior; full room-scale support is not claimed.
The owner authorized the subsequent 0.9.0 installer build and lifecycle checks.

The horizon-lock audit found full-pose world reference capture on startup/recenter.
World capture now uses heading only; the owner confirmed the world fix. HUD
recenter now uses heading only too after the owner reported remaining panel tilt.
Natural head tracking and scripted cameras remain. The VR vignette was reported
barely visible; its maximum fade now spans 20-40 degrees instead of 35-55.
The owner accepted [world/HUD horizon lock](vr-horizon-lock.md) and the revised
stereo vignette as perfect on CV1 on September 25 at checkpoint `232f768`.
Preserve this baseline; other-headset validation remains separate.

After owner acceptance of controller/menu behavior, Balanced (100%) is the default.
The temporary Current profile option is removed; four runtime-scaled presets remain.

Commit `df6921c` preserves the owner-accepted CV1 baseline. The follow-up removes
Epic and improves aspect labels. Optional HUD/Menu Sharpness was subsequently
removed at the owner's request; the original fixed UI texture is restored.
Retired-setting and installer profile migrations are removed: installs seed fresh
settings while saves remain retained. Rotated-eye math now has automated coverage. See [current settings and validation limits](vr-render-quality.md). Other
headsets remain hardware-unverified. Focus-loss stutter is closed at the owner's
direction (24 September 2026). Broader controller profiles, canted-eye head
orientation and consistent B/back navigation are covered in
[the compatibility contract](vr-controller-compatibility.md).

## Build workflow

Use `local/build` for development and packaging, as documented in `commands.md`.
If absent, run `cmake -S . -B local/build -A x64`. Temporary experiment trees
are not the normal build path. Standalone test builds retain their own directories.

## Read first

1. Read [`progress.md`](progress.md) for completed milestones and validation.
2. Use [`commands.md`](commands.md) for the common build, deploy, launch, test,
  and packaging commands.
3. Read [`renderer-227k.md`](renderer-227k.md) before changing renderer or
   viewport behavior.
4. Read [`building.md`](building.md) before configuring or deploying.
5. Read [`testing.md`](testing.md) before declaring a behavior complete.
6. Follow the repository and renderer rules under `.github/`.

## Accepted VR weapon baseline

On 2026-09-21 the owner confirmed the completed weapon work was visually correct
in the headset after the final Eightball adjustment. The local annotated tag
`vr-weapons-validated-2026-09-21` preserves this known-good baseline: shared
weapon sizing, gaze right/left/center placement, tracked placement, muzzle/aim
alignment, RazorJack alternate animation and weapon/HUD composition.
The 14 accepted calibration profiles are now the shipped seed defaults,
including Eightball gaze Y=20; existing user calibration is never overwritten.
See [the milestone and recovery record](vr-weapon-tuning.md#accepted-milestone)
before changing these paths. This supersedes older pending visual-acceptance
notes for these weapon changes, not the separate remote-client multiplayer,
broader VR compatibility limitations.

## Release readiness after the weapon milestone

The failed focus-recovery paint change and temporary diagnostics have been
removed. The following release record describes the September 21 weapon milestone;
subsequent development changes are summarized above and in `progress.md`.
Release cleanup status:

- Focus-loss stutter is closed at the owner's direction on 24 September 2026;
  no further investigation is scheduled.
- Both VR script hooks now explicitly use the transient package as their owner.
  The production creation path passes repeated map travel, save/load, rebinding
  and shutdown without invalid-outer warnings. Weapon firing regression passes.
- Installer staging builds a production `ModernMenu.u` without development test
  fixtures and rejects their names in the compiled output. Development builds
  retain fixtures for regression tests.
- Startup/state/error logging remains intentional. Performance sampling is
  opt-in via `UNREAL_REVIVED_MEASURE_PERFORMANCE`; this audit is not an FPS or
  zero-overhead certification.
- The cleanup candidate (then numbered 0.7.0) was locally validated through fresh
  installation, desktop/VR startup and restart, payload hashes, preservation of
  edited profiles/calibration, uninstall, save retention and reinstall. Validation
  used an isolated app identity and cleaned its registration, shortcuts and test
  backups. All 30 development profile/save hashes stayed unchanged. Artifact
  identity and evidence are recorded in [the progress log](progress.md).
- The four agreed release-cleanup tasks are complete. The historical focus-loss investigation
  was subsequently closed. The owner tested, accepted and explicitly authorized publication of
  0.8.0 on September 21, 2026. The accepted installer was published without rebuilding:
  SHA-256 `5A00521B1F84CA25A423DD3109153C21D3BF3218A3DB02BC659764933CAEBD58`.
  Its embedded payload records base revision `988eb80` and `sourceDirty=true`
  at build time; that original record is retained in the accepted artifact.
- [Unreal Revived 0.8.0](https://github.com/kwstasg/Unreal-Revived/releases/tag/UnrealRevived-Setup-0.8.0)
  is published as the latest stable release. Source commit `9b8ce3a`, release
  tag `UnrealRevived-Setup-0.8.0` and weapon-milestone tag are pushed to GitHub.
  GitHub's SHA-256 digests verify both the installer and checksum sidecar.
- The 0.8.0 installer and launcher metadata, payload hashes, optional calibration
  inclusion and fixture exclusion passed. All 30 runtime profile/save hashes
  stayed unchanged. The earlier lifecycle result applies to the preceding cleanup
  build; the owner has now tested and accepted the versioned installer. No
  rebuild is needed for this documentation-only acceptance record.

See [release notes](release-0.8.0.md) and [the investigation record](progress.md).

## Supported boundary

- Host: OldUnreal 227k_15, Windows x64.
- Renderer: native `D3D12Drv.D3D12RenderDevice`.
- Build system: CMake with Visual Studio 2022 and C++17.
- Runtime model: ignored disposable installation under `local/game/`.
- SDK model: ignored 227k_15 SDK under `local/sdk/227k_15/`.
- Development setup: one-command bootstrap using the original pinned OldUnreal
  runtime and SDK downloads plus a detected `C:\Unreal` installation or an
  explicitly selected original-game directory. Missing-source errors link
  developers to OldUnreal's official full-game installer.
- Original Unreal Gold installation: recovery source only; never modify it.
- Distribution model: the fully offline Unreal Revived Inno Setup executable
  creates a side-by-side installation under `C:\Games\Unreal Revived` by
  default from the user's selected original-game directory and the bundled
  pinned 227k_15 patch. Setup checks `C:\Unreal` first, retains legacy Steam
  detection for existing owners, links to OldUnreal's official full-game
  installer when no source exists, and can detect the resulting installation
  without restarting Setup.
- Prebuilt build: the installer is attached to the project's
  [latest GitHub release](https://github.com/kwstasg/Unreal-Revived/releases/latest).
  The owner-approved 0.8.0 update adds Touch aiming, calibrated weapons, optional weapon
  tuning, binding and brightness improvements, and release cleanup.
- Packaging authorization: redistribution, mirroring, and offline bundling of
  the pinned OldUnreal 227k_15 Windows patch is confirmed in
  [`../PERMISSIONS.md`](../PERMISSIONS.md) and must not be reopened as a blocker.

The renderer builds, deploys, and loads without XOpenGL fallback. Native and
lower logical resolutions, borderless letterboxing, menu coordinate mapping,
HD lightmaps, RGB10A2 textures, 227 alpha-blended geometry, normal startup, and
campaign metadata discovery have been implemented and validated. The Video
preferences page exposes a persistent checkbox for Unreal Revived's compact FPS
statistics and the D3D12 Off/2x/4x/8x antialiasing modes. Logical 2560x1440 and
3840x2160 rendering, including 4K with MSAA 8x, is validated on the current
RTX 3060 host. Borderless physical sizing follows the monitor containing the
game window; true physical 4K output remains unvalidated on the current 1080p
desktop.

D3D12 Video preferences also expose bloom, chromatic aberration, vignette,
animated film grain, and CRT scanlines. All five use the renderer's single
`BEGINUIPASS` contract, captured world image, and dedicated UI composition
mask; no effect-specific HUD detection or legacy boundary aliases remain.
Missing the explicit boundary safely bypasses world-only effects for that
frame instead of applying them to UI.

The D3D12 renderer now keeps OpenXR strictly opt-in: normal launches and
`-novr` do not query or load the bundled Khronos loader. `-vr` or the stored
`EnableVR=True` setting creates an OpenXR instance, reports the active runtime
and HMD system when available, verifies the runtime's D3D12 adapter and
feature-level requirements, and creates a guarded OpenXR session. It allocates
two runtime-recommended eye swapchains, begins the session when it reaches
`READY`, locates both eye views, and renders two independently culled UE1 views
using the runtime eye poses, IPD, asymmetric FOV, and frame timing while
retaining normal monitor output. A render-only
`PlayerPawn.ViewRotation` experiment was removed after flat/VR flyby comparison
showed that pawn view state is not UE1's authoritative calculated camera for
scripted views. Orientation tracking now uses a 227 `PlayerInteraction` to
compose the relative OpenXR pose onto the authoritative `PlayerCalcView` result
before scene culling, with per-eye position and seated translation applied in
the same base-camera space. Live Oculus Rift CV1 validation confirmed fused
stereo with natural depth, correct base direction, natural yaw/pitch/roll, no
black visibility gaps, and no rotational stretching or swimming. Balanced renders each eye at its runtime-recommended size (1344x1600 in the
earlier CV1 test). Other presets scale that recommendation; logical layout
stays fixed at 1280x1024. The first-person
weapon now follows headset rotation and seated head-center translation through
a render-only overlay hook, with a conservative lower, handed placement that
does not alter gameplay state. Live validation retained scripted flybys,
controls, stereo fusion, and distortion-free tracking. The September 21 weapon
milestone accepts shared gaze/motion sizing, placement, firing alignment and
weapon/HUD composition for all 14 calibrated stock/UPak families. Remote-client
VR firing remains unsupported. Gamepad headset-yaw walking/jumping and
horizontal right-stick turning were user-validated on 2026-09-11. Combined view/UI
recenter, quick bindings and UI colors are user-validated. Head-collision fade
and recovery were user-validated at walls, corners and low ceilings, with a door,
world-size adjustments, swimming in water and an elevator also passing on
2026-09-15. Gaze-directed swimming/flying was accepted on September 24. Selectable mirror
options and broader hardware acceptance remain open. The
offline installer includes visual source selection, hidden
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
Menu shortcut, and uninstall backup are implemented. Windows Installed Apps,
a direct uninstaller launch, and rerunning Setup over a current installation
all lead to one branded uninstall dialog with a default-checked save-retention
option. Choosing Uninstall continues into standard progress; choosing Cancel
leaves the installation unchanged. The dialog states that the original source
and OldUnreal downloads remain untouched, and explicit `/VERYSILENT` uninstall
retains saves without prompting. A retained save-only installation directory
is accepted on reinstall and protected from the original-game copy. Runtime
smoke automation exercises representative maps, renderer settings, menu state
profiles, and display profiles. Retained screenshots cover
the currently validated menu layout and input alignment; external click
automation is unavailable because UWindow exposes no automation elements and
ignores background window messages.

Disposable-runtime provisioning and offline-installer staging repair the
missing base wizard caption in every retained `Startup.*` localization. This
is required even with `FirstRun=227` because the 227k_15 client constructs the
configuration wizard object before deciding that no wizard page is needed.

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
and stick clicks. DualShock 4 hotplug plus rumble, touchpad, gyro, and lightbar
behavior remain unvalidated. An Xbox Series controller was also
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
The disposable runtime also builds the pinned Old Weapons mutator and mirrors
its registration into `System/`. It is discoverable from New Game and was
confirmed to join the runtime mutator chain; normal games remain unchanged
when Use Mutators is disabled.
The three-assignment binding workflow and persistence across restart were
manually validated. Broader controller lifecycle coverage beyond the documented
Xbox reconnect cases remains unvalidated.

## Verified commands

See the focused [`commands.md`](commands.md) reference for common workflows and
important side effects. The core verified commands are:

From the repository root:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
cmake --build local/build --target deploy-d3d12drv --config Release
cmake --build local/build --target deploy-xinputwindrv --config Release
cmake --build local/build --target deploy-modern-menu --config Release
cmake --build local/build --target deploy-old-weapons --config Release
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
The installed product starts from `System64\UnrealRevived.exe` for desktop
or `System64\UnrealRevivedVR.exe` for VR, without shortcut arguments. Each host
selects its own engine profile (`Unreal.ini` or `UnrealVR.ini`); controls and saves
remain shared. Native launch, restart, profile isolation, and installer lifecycle
checks are recorded in [`branded-launchers.md`](branded-launchers.md).

The validated local 0.9.0 installer is
`local/package/offline-installer/output/UnrealRevived-Setup-0.9.0.exe`, with
its base source revision and working-tree dirty flag in `payload-manifest.json`.
The installer is unsigned; installed-build owner acceptance remains pending. See
[release notes](release-0.9.0.md) and [validation evidence](release-0.9.0-validation.md). The
preserved 0.6.0 publication and validation record remains in
[`release-0.6.0.md`](release-0.6.0.md).

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
- Every retained `Startup.*` localization must contain
  `IDDIALOG_WizardDialog.IDC_WizardDialog`; otherwise ordinary client startup
  can exit while constructing the dormant configuration wizard.
- A profile generated from the pristine patch default must set
  `[FirstRun] FirstRun=227`; leaving `FirstRun=yes` invokes an unusable startup
  wizard before the normal localization paths are active.
- Never track files under `local/` or deploy into the original game install.
- Deployment and runtime automation require the development marker generated
  by bootstrap; `-Force` cannot authorize an unmarked destination.
- Archive and binary source-control exclusions do not prevent release tooling
  from embedding the pinned 227k_15 payload from ignored local inputs.

## Next priorities

The authoritative current checklist is [pending tasks](pending-tasks.md).
World/HUD horizon lock and the stereo vignette have CV1 owner acceptance at
`232f768`; music navigation is reviewed and separately checkpointed. Community
hardware reports remain pending.
The September 25 current-source installer passed the isolated install/uninstall/
reinstall lifecycle after settings-migration removal. All four profiles returned
to fresh defaults and saves were retained. Desktop/VR startup and restart passed;
Oculus/CV1 initialized in IDLE, without headset visual acceptance. The local
package records base revision `d2eda30` and a dirty tree including the separately
reviewed music changes. That package predates the subsequent upright-HUD and
stronger-vignette follow-up, which is deployed only to the development runtime.
No new publication or push is authorized or performed.

The spatial UI milestone was user-accepted on 2026-09-10: complete desktop-like
HUD/menu layout on one upright OpenXR panel, explicit UI recenter, and stable,
independent distance/scale controls. See [the maintenance contract](vr-ui-recovery-design.md).
This is a source milestone; no release or tag was published for it. Broader VR
runtime/gameplay coverage remains separate from this headset acceptance.

The ordered major additions are maintained in [`roadmap.md`](roadmap.md):

1. Seated PC VR through OpenXR.
2. RTX support.
3. A native Vulkan driver.

VR's validated base feature set was frozen for 0.6.0; 0.6.1 adds the Return to
Na Pali VR HUD hotfix. Remaining compatibility work, RTX and Vulkan belong to
later releases. Continue flat-screen validation, automated regression coverage,
installer UX, and release automation alongside them.

## Updating the handoff

When behavior changes, update the focused technical document and
[`progress.md`](progress.md). Update this page only when the supported boundary,
critical invariant, verified command, or next priority changes.

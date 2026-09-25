# Testing

## VR turning modes

Follow [the turning and standing-HUD contract](vr-standing-and-turning.md).
The native `vr-turning` regression exercises production turn accumulation and
neutral/interrupt behavior. `scripts/test-video-preferences.ps1` also checks the
new menu defaults, persistence, reset and desktop isolation. The owner accepted
turning behavior at `f995a53`; final names are Instant Snap and Smooth Snap.
Retain physical input/comfort checks for future changes and other hardware.

## Music menu navigation

After building ModernMenu with test fixtures (omit `-Production`), launch
`NyLeve?Game=ModernMenu.ModernMusicTestGame` using disposable engine/user INIs
and `-novr`. Require `MUSICTEST completed` with no `MUSICTEST FAIL` or script
warnings. This exercises Tab through the twelve music controls and playlist,
reverse navigation, disabled-button skipping, Browse activation/toggling and
list selection. It also checks actual selected-track playback through gamepad
confirm and Enter, plus harmless confirmation on an empty playlist. Use
up/down to select rows and left/right or Tab to leave a focused list. Rebuild
with `-Production` afterward to exclude test classes from the shipped menu.

## VR hook lifecycle and production packaging

Build the fixture-enabled development menu before running these checks:

```powershell
cmake --build local/build --target deploy-modern-menu --config Release
powershell -NoProfile -File scripts/test-vr-map-travel.ps1
powershell -NoProfile -File scripts/test-vr-motion-regressions.ps1
```

The lifecycle fixture calls the production console's hook creation method,
checks that neither hook belongs to the console, travels through three maps,
saves and loads using a temporary isolated save directory, rebinds the hooks,
and exits. Invalid owners, assertions and script warnings fail the check.
User profiles and saves are not used as test output.

Installer staging rebuilds the menu with `-Production`, omitting the development fixture
classes and rejecting their names in the compiled package. Rebuild the normal
development target before running fixtures again. The release package is tested
through the isolated installer/launcher lifecycle, not by shipping test classes.

## Focus-recovery task status

Closed at the owner's direction on 24 September 2026. No further focus-loss
stutter investigation is scheduled; historical logs remain in the progress record.

## VR gamepad locomotion checks

Build/run the portable direction tests with:

```powershell
cmake -S XInputWinDrv/tests -B local/build-vr-gamepad-tests -A x64
cmake --build local/build-vr-gamepad-tests --config Release
ctest --test-dir local/build-vr-gamepad-tests -C Release --output-on-failure
```

In a playable VR map, look left/right/back and check forward, backward, strafe
and diagonals. Looking up/down or rolling the head must not introduce vertical
movement or change speed. Turn with right-stick X while walking; right-stick Y
must not add camera pitch. Check jump/crouch, release to rest, reconnect, and
menu navigation. Desktop controls must retain both right-stick axes. The initial
VR remap covers first-person walking/falling and plain movement-axis bindings.
Gaze swimming/flying/CheatFlying now use state hooks; check forward/backward
while looking up/down and after turning the chair. Custom aliases retain native
behavior. Use `scripts/test-vr-motion-regressions.ps1` for state-dispatch checks.

Verify normal/VR shortcuts pass `-novr`/`-vr` despite the saved startup checkbox.
Installer tasks must independently select neither, either or both desktop icons.

## Accepted VR UI regression checks

Build and run the focused renderer tests:

```powershell
cmake -S D3D12Drv/tests -B local/build-vr-panel-tests -A x64
cmake --build local/build-vr-panel-tests --config Release
ctest --test-dir local/build-vr-panel-tests -C Release --output-on-failure
```

On Windows, `vr-ui-occlusion` executes the production UI shader through WARP
and checks weapon cutouts, UI-mask channel isolation, asymmetric-eye lookup,
out-of-view rejection and partial premultiplied-alpha coverage. This does not
replace headset checks: overlap the weapon with status HUD pixels in both
gaze and motion aiming, inspect each eye, fire, hide/switch weapons, recenter,
open/close menus and test collision fade. Confirm the panel has not moved and
no stale silhouette remains. Include MSAA off and the normal MSAA setting.

The shared-panel milestone was accepted by the user in the headset on 2026-09-10.
Use [its maintenance contract](vr-ui-recovery-design.md) as the source baseline.
For any projection, layout or pose change, compare at identical game resolution,
GUI/HUD scale, VR distance and VR scale:

- Flyby and playable map: full menu edges, centered Preferences, dropdowns,
  HUD corners, intro artwork, messages, translator and FPS statistics.
- Open/close the menu while moving the head: identical panel bounds and anchor.
- Adjust distance and scale continuously: no pose recapture; distance changes
  apparent size, scale resizes about the center, explicit Recenter resets heading.
- Compare cursor, hover, clicks, dragging and controller focus across the canvas.
- Check ordinary desktop UI remains unchanged. Include 5:4 and widescreen layouts.

Build/lifecycle automation is necessary but cannot prove these visual checks.
Do not treat an ordinary desktop mirror as the submitted OpenXR layer.

Runtime smoke automation covers map loading, selected renderer configurations,
menu state profiles, display profiles, clean D3D12 startup and shutdown, and
known log failure signatures. Screenshots remain necessary where logs cannot
establish visual correctness. Record significant results in
[`progress.md`](progress.md).

The harnesses clear a stale `Running.ini` and request shutdown by posting
`WM_QUIT` to the Unreal process threads. Closing the viewport window alone can
leave this host running without a viewport, while `WM_QUIT` follows the native
engine message-pump exit path and preserves renderer unbind and log evidence.

## Supported renderer smoke matrix

```powershell
powershell -NoProfile -File scripts/test-supported-renderers.ps1 -RunSeconds 3
```

The matrix loads six representative maps with D3D12, OpenGL, and XOpenGL. It
runs only against the asserted disposable development runtime, clears a stale
`Running.ini` marker before launch, and forces each temporary profile windowed
so automation cannot request an exclusive display-mode change or open Recovery
Mode. A rejected resolution change, `Failed3D` localization event, crash
signature, missing package, or incomplete renderer bind/unbind cycle fails the
run. The source engine and user profiles must retain their original hashes.

Provisioning and installer staging add the required
`Startup.IDDIALOG_WizardDialog.IDC_WizardDialog` caption to every retained
`Startup.*` localization. OldUnreal constructs that base dialog during every
client startup, even when `FirstRun=227` prevents a configuration page from
opening; omitting the caption can therefore abort ordinary smoke launches.

## Gamepad viewport and controller

Build, deploy, and run the non-hardware loader smoke case with:

```powershell
cmake --build local/build --target deploy-xinputwindrv --config Release
powershell -NoProfile -File scripts/test-d3d12-runtime.ps1 -Suite Input -RunSeconds 3
```

The test clones `[WinDrv.WindowsClient]` into a temporary automation profile,
enables gamepad input, and requires clean `XInputWinDrv.dll` and `D3D12Drv.dll`
bind/unbind cycles. The driver should log SDL initialization and may also log a
supported system XInput fallback library. This does not prove physical
controller behavior.

Before claiming Xbox Series or DualShock 4 controller support, fully exit Steam
and controller translation tools, then manually validate USB and Bluetooth with
the controller connected before launch, connected after launch,
and disconnected/reconnected while moving or firing. Verify both sticks,
independent LT/RT actions, A/B/X/Y, shoulders, View, stick clicks, D-pad
diagonals, simultaneous keyboard/mouse input, Alt+Tab, level travel, death and
respawn, and absence of stuck movement or fire. For DualShock 4, verify Cross,
Circle, Square, Triangle, L1/R1, Share, Options, stick clicks, and independently
mapped L2/R2. Also disable gamepad input and verify WinMM fallback. Record
Windows version, controller firmware, transport, chosen slot, observed mappings,
and relevant log lines.

With `ModernMenu.ModernConsole` active, verify Menu opens UWindow and pauses a
standalone game, then closes it and restores play. In Preferences, verify D-pad
and left-stick focus movement, dominant-axis handling, held-stick repeat,
automatic scrolling, A activation, B return, and wrapped LB/RB tab switching.
Verify that message boxes immediately outline their default button, all four
directions cycle only their available buttons, A confirms the outlined result,
and B cancels without changing controls behind the modal. Confirm the Input
page presents Controller before Mouse and aligns all visible checkbox squares.
In standalone gameplay, walk continuously across known legacy BSP floor seams
and confirm the player clears them without a visible teleport. Press forward
against hostile and friendly pawns for several seconds from multiple angles;
confirm they are not damaged or killed and the player cannot pass through them.
After clearing a seam near a pawn, back away and confirm the normal collision
radius returns without crushing either pawn.
On Bindings, use A to select a row and capture A, X, Y, LB/RB, View, stick
clicks, triggers, and each D-pad direction. Verify B cancels capture, Menu closes
without becoming a binding, and keyboard/mouse input still works. Restart and
confirm changed bindings persist.

Run the binding handler regression after building ModernMenu:

```powershell
Push-Location local/game/System64
.\UCC.exe ModernMenu.ModernBindingsTestCommandlet -silent ini=D3D12Test.ini
Pop-Location
```

This executes the production binding handlers with an isolated input store. It
covers a full Crouch row, successive oldest-input replacement, duplicate input,
cancellation, clear, mouse capture, and moving an input from another action.
It does not simulate the operating system's keyboard or physical controllers.

To verify saved binding order across separate engine processes, use a disposable
user profile:

```powershell
Push-Location local/game/System64
Copy-Item DefUser.ini BindingHistoryTestUser.ini -Force
.\UCC.exe ModernMenu.ModernBindingsTestCommandlet history-write -silent ini=D3D12Test.ini userini=BindingHistoryTestUser.ini
.\UCC.exe ModernMenu.ModernBindingsTestCommandlet history-read -silent ini=D3D12Test.ini userini=BindingHistoryTestUser.ini
Pop-Location
```

For interactive validation, use a disposable user profile. Left-click Crouch
with three bindings and confirm the capture prompt remains after releasing the
mouse. Assign F, then G; each must replace the oldest displayed input. Cancel
another capture with Escape and B and confirm no assignments change. Check
right-click, Delete, and controller X clear without starting capture. Check
Enter, Space, and A start capture, and that X and middle mouse can be assigned
once capture is active. Idle middle-click must not clear the row. Restart and
confirm both assignments and their oldest-to-newest order persist. Finally,
Reset should restore the shipped bindings.

Manual Xbox controller validation confirmed that Escape and Menu open the menu
shell, A or D-pad opens a closed pull-down, all four D-pad and left-stick
directions navigate pull-downs, B closes the pull-down, and Menu exits and
unpauses. Combo boxes open, navigate, and commit with the controller. A also
resets focused Video and HUD sliders directly. Broader USB/Bluetooth hotplug
coverage remains pending.

In `NyLeve`, verify the first-house doorstep and the narrow blood-stained
corridor steps can be crossed using continuous walking without jumping. Confirm
the player does not visibly snap or accelerate, ordinary movement retains its
normal collision radius, crouching and airborne movement remain unchanged, and
the assist still works after normal map travel and loading a save.

Compare full-stick movement and turn speed at a conventional frame rate and an
uncapped rate. Physical testing confirmed consistent movement and look at about
240 FPS with VSync and above 1000 FPS uncapped. Also verify that left-stick
movement and strafing do not trigger dodge, keyboard double-tap dodge still
works with the stick centered, and mouse look remains unchanged. Modal default
focus, directional selection, A confirmation, B cancellation, controller-only
dodge suppression, and restored horizontal/vertical mouse look were manually
confirmed. Focused sliders use a separate fast one-step repeat cadence, which
was manually confirmed to retain precise increments while moving smoothly.

In **New Game**, verify controller focus follows Campaign, Difficulty, Classic
Balance, Use Mutators, Mutators, Advanced, and Start,
wrapping in both directions. A on Start must launch the selected campaign.
Verify Up/Down and Left/Right traverse the same focus ring with both the
keyboard and controller. At the initial screen, each arrow direction must open
the top menu navigation. Left/Right must continue adjusting a focused slider
and retain native navigation in open combos and top menus.
In the two-row Preferences tab strip, gamepad shoulders must traverse tabs in
their visible row order rather than their interleaved creation order. The tabs
must wrap sequentially as Video, Audio, HUD, Game, Input, Bindings, and Network
with no shortest-row redistribution. Preferences must be wide enough to keep
that sequence in exactly two rows: four tabs followed by three.
Verify both Enter and Space activate focused buttons and checkboxes, open and
confirm combo-box selections, activate lists, and confirm message boxes. Space
must remain available for typing in text-entry controls.
For Load and Save, verify every visible slot traverses in display order,
scrolls into view, and activates; Load must include Restart after the final
slot. These New Game and Load/Save flows were manually confirmed. Advanced and
Mutator-dialog controller coverage remains incomplete and requires a later
focused pass.

In the New Game **Mutators** dialog, verify both arrow keys and the gamepad can
traverse Always Use, Mutators Not Used, Mutators Used, and Close in both
directions, and verify Tab follows the same complete ring. Up/Down must select list entries, and Enter, Space, or gamepad A
must transfer the selected mutator to the opposite list. In **Advanced**,
verify every control on the selected page is reachable, followed by Start and
Close, and that continuing past Close returns to the first page control;
gamepad shoulder buttons must switch pages, restore the new page viewport, and
focus its first control rather than either footer button.
Opening Advanced must display the Match page controls immediately; the blank
area after the Bots header is the unused remainder of the tab strip.
After closing the Match page's Map List or Mutators child dialog, focus must
return to the first control on the selected Advanced page and its complete
navigation ring must remain usable.

For resizable dialogs, verify all four edges resize from a four-pixel logical
hit region and all four corners resize diagonally from a fifteen-pixel
region. Confirm the title bar still drags the window and its close button still
clicks normally at every supported GUI scale. Dialog controls overlapping an
expanded border must not prevent resizing, while clickable buttons in that
region, including their child windows, retain their input instead of starting
a resize.
Pay particular attention to the bottom edge and both bottom corners, whose
expanded regions must take precedence over the client area at the frame
boundary. Once dragging starts, the frame must own mouse capture so its size
tracks physical pointer movement continuously rather than intermittently.

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
does not modify the original game installation, disposable runtime, extracted
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
the Unreal Revived D3D12 recommendation. Confirm the window loads the tracked
`Help/SetupLogo.bmp`, and inspect the tracked shortcut ICO for 16, 24, 32, 48,
64, 128, and 256 pixel frames.

Open the in-game menu with Escape while `ModernMenu.ModernRootWindow` is active.
Confirm the Unreal Revived background renders as a seamless 4x3 tile grid, the
menu and status bars remain visible, and the 16:9 source remains proportional.
A 16:9 viewport must fill without cropping or stretching. Other
viewport ratios must use centered cover cropping rather than stretching or
image-specific side extensions. The runtime log must contain no missing
texture or package warnings.

Open the Help menu and confirm **OldUnreal** appears below **About Unreal**, with
**Unreal Revived** immediately below it and the separator above **About Epic
Games**. Confirm the two entries open `https://www.oldunreal.com/` and
`https://github.com/kwstasg/Unreal-Revived` respectively, and that there are no
consecutive separators.

Open **About Unreal** and confirm every original and OldUnreal credit remains
visible. Beneath the lowest existing entry, confirm one empty row separates a
left-aligned **Unreal Revived** section identifying **Project Creator: Kwstasg -
Kostas Giannakakis**, **Developers: Kostas & Nikos Giannakakis**, and
`github.com/kwstasg/Unreal-Revived`.
Hover the repository text and confirm its color and cursor change, then click it
and confirm the project page opens.
Confirm the dark-backed Unreal Revived banner appears proportionally above the
credits and that the taller dialog keeps every credit and the Close button
visible.

During the Unreal intro flyby, confirm the original Epic, GT Interactive,
Digital Extremes, and Unreal logos remain visible while the dynamic OpenAL and
PhysX driver-credit logos are absent. Start a normal gameplay map afterward and
confirm its HUD is unchanged.

After source-derived branding changes, confirm `MenuBackground.bmp` is a
3840x2160 24-bit bitmap. For manual banner changes, confirm `Logo.bmp` is a
952x295 24-bit bitmap, `SetupLogo.bmp` is a 343x84 24-bit bitmap, and their
deployed copies match the tracked sources. Confirm the installer uses the
generated portrait wizard artwork without stretching the logo, shows the
author and clickable GitHub URL, offers a desktop-shortcut task, and offers a
post-install launch checkbox. Inspect the ICO directory for 16,
24, 32, 48, 64, 128, and 256 pixel frames and verify the circular crest has
transparent corners.

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
cmake --build local/build --target deploy-xinputwindrv --config Release
cmake --build local/build --target deploy-modern-menu --config Release
```

The deploy target is available only when the configured game root contains
`System64/Unreal.exe`.

## Runtime launch

From the disposable runtime's `System64` directory, use:

```powershell
.\Unreal.exe Unreal.unr?Game=ModernMenu.ModernIntro ini=D3D12Test.ini userini=D3D12TestUser.ini
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

Smoke-test all supported renderers across the six representative maps:

```powershell
powershell -NoProfile -File scripts/test-supported-renderers.ps1
```

This uses isolated profiles for D3D12, OpenGL, and XOpenGL, verifies the
expected renderer bind/unbind cycle, rejects crash and missing-package
signatures, and confirms normal shutdown without changing the development
profiles.

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

Run `scripts/test-d3d12-runtime.ps1 -Suite VRFoundation` for the isolated
OpenXR groundwork checks. The suite covers `-vr`, stored `EnableVR=True`, and
the `-novr` override, requiring a runtime-detection result whenever the loader
is present. If an HMD is detected, the test also requires a reported D3D12
session outcome. A compatible live session must report two ready eye
swapchains, and a begun session must submit at least one completed headset
frame. The harness accepts both the earlier monoscopic diagnostic and
the current independent stereo-frame diagnostic because ordinary automation
may run without a connected OpenXR runtime.

Weapon regression checks:

```powershell
powershell -NoProfile -File scripts/test-vr-motion-regressions.ps1
powershell -NoProfile -File scripts/test-vr-motion-regressions.ps1 -ListenServer
powershell -NoProfile -File scripts/test-vr-weapon-reload.ps1
powershell -NoProfile -File scripts/test-vr-map-travel.ps1
```

The motion regression verifies real DispersionPistol primary/charged projectiles,
all five Stinger burst projectiles, and ASMD alternate balls and primary beam
origins against the calculated muzzle, including stock spread and restoration of
weapon offsets/player view. It reconstructs ASMD beam starts from the original
effect and confirms stock desktop beam offsets are unchanged. Stock Stinger/ASMD
landmark checks compare resting-mesh measurements and preserve live animation.
DispersionPistol landmark checks cover all five power levels and a return to
level zero, verifying muzzle-cache updates without changing scale and restoring
the live mesh, rotation and animation state.
It exercises a forced
motion pose and the production gaze calculation with synthetic head rotation,
translation and world scale. It also verifies exact state-function bindings and
one shared neutral size baseline and equal configured scales in both modes for
all 14 stock/UPak profile classes, two Old Weapons subclasses and a custom fixture
with a replaced first-person mesh/view scale. These checks do not establish
controller tracking accuracy, visual barrel alignment, arbitrary mutator
compatibility or complete Return to Na Pali gameplay support.

The remaining-weapon matrix checks AutoMag, Rifle, Minigun, QuadShot and CARifle
hitscan starts/directions, CARifle alternate rounds, Flak fragments/shells,
RazorJack primary/alternate blades, charged bio shots, both UPak rocket modes,
six-rocket/six-grenade Eightball volleys and both GrenadeLauncher modes. It covers
forced off-axis motion origins and production gaze eligibility/calculation using
only a synthetic interaction lookup, with both neutral and saved runtime gaze
tuning. Mesh checks cover every remaining stock landmark and both AutoMag/QuadShot
handed meshes. AutoMag/Minigun alternate-state traces and all four loaded QuadShot
patterns are checked explicitly. Rifle zoom and QuadShot reload remain available
with a blocked muzzle in both aiming modes. State-function cache reuse and native
resolver equivalence are asserted; a 10,000-lookup microbenchmark logs timing
without a machine-dependent pass/fail performance threshold.

`-ListenServer` runs the same matrix on a loopback listen host and asserts the
engine's actual listen-server mode. It does not launch a remote client or validate
remote pose replication. Both configurations use disposable engine/user profiles
and leave the saved weapon-tuning file untouched. These are focused firing-entry-
point checks, not complete campaign, animated-socket, remote-detonation gameplay,
rocket-guidance flight or remote multiplayer validation. See the explicit
[multiplayer boundary](vr-motion-controllers.md#multiplayer-boundary).

Weapon/HUD material coverage checks:

```powershell
cmake --build local/build-vr-panel-tests --target vr-ui-occlusion --config Release
ctest --test-dir local/build-vr-panel-tests -C Release -R '^vr-ui-occlusion$' --output-on-failure
```

The WARP test executes the production scene and presentation shaders. Opaque
zero-alpha skin pixels and surviving masked pixels must fully occlude the HUD;
discarded mask texels, alpha-blended, translucent and modulated effects retain
their transparency. Ordinary UI alpha remains unchanged. Inspect the reported
UPak weapons in both eyes and aiming modes to confirm the actual content issue;
shader pixel checks and an IDLE OpenXR startup are not that visual acceptance.

For the F8/on-off report, manually alternate tuning reloads and removing/replacing
the HMD during a sustained session. Check frame pacing after each return, both
eyes, and the log for session transitions or `xrEndFrame` failures. Automated
startup while the session remains IDLE cannot validate this lifecycle sequence.

For live orientation validation, begin with the headset facing comfortably
forward and compare the intro flyby's initial direction with a flat launch.
Yaw, pitch, and roll must move naturally without changing the scripted base
direction or exposing black visibility gaps. Confirm that both eyes fuse with
natural depth, text is not doubled, and physical up/down and left/right
rotation does not stretch or swim. The Oculus Rift CV1 passed these checks on
2026-09-09. Repeat them whenever eye pose, projection, intermediate resolution,
or swapchain presentation changes.

Every ordinary D3D12 case also enumerates loaded process modules and requires
both an absent `openxr_loader.dll` and the renderer's
flat-screen-default diagnostic. The supported-renderer matrix applies the same
isolation check to each D3D12 launch.

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
- Switch between both campaigns and confirm each uses the same transparent
  Unreal Revived wordmark without changing the original 180x90 preview bounds.
- Start Unreal and confirm travel begins at `Vortex2`.
- Start Return to Na Pali and confirm travel begins at `Intro1`.
- Confirm campaign screenshots and skill selection render correctly.

If the campaign combo is empty, verify that `System/UnrealShare.int` and
`System/UPak.int` match the files in `SystemLocalized/int/`. The deployment
target maintains those copies for the disposable runtime.

## Video menu checklist

- Open **Options > Preferences > Video**.
- Confirm **Video Driver** offers only Direct3D 12, OpenGL, and XOpenGL.
- Confirm **Display Mode** replaces the fullscreen and borderless checkboxes
  and offers Fullscreen, Borderless, and Windowed. With D3D12Drv active, press
  Alt+Enter from Windowed and confirm it selects Borderless; press it again and
  confirm it returns to Windowed. Select Fullscreen explicitly, press
  Alt+Enter, and confirm it changes to Windowed.
- Confirm Color Depth and GUI Mouse Speed are absent and later controls close
  their former row gaps.
- Confirm **Show FPS Statistics** appears directly below **Display Mode**
  and scrolls with the other video controls.
- Enable FPS statistics and confirm the overlay contains only **FPS**, **AVG**,
  **Low**, **High**, **Res**, and **VSync**; confirm FPS values use one decimal,
  resolution matches the rendered canvas, VSync follows the renderer, the text
  is smoothly filtered at half the configured HUD scale with a sixteen-pixel
  left inset, and the overlay remains visible while the Escape menu is open.
  Change HUD Scaling and confirm the overlay follows it. Open a dropdown over
  the overlay and confirm the dropdown covers the intersecting text. With bloom
  enabled, confirm opening the menu does not make menu pixels bloom.
- Press F11 repeatedly and confirm it toggles the statistics overlay without
  changing brightness. With Video Preferences open, confirm F11 immediately
  updates the checkbox; click the checkbox and confirm it immediately performs
  the same toggle. Restart the game and confirm the saved overlay state matches
  the last selection.
- Move keyboard focus through sliders, checkboxes, combo boxes, edit fields,
  tabs, and buttons. Confirm a solid two-pixel gold outline surrounds only the
  interactive widget, not its label. Open pulldown menus and combo lists and
  confirm neither dropdown receives an outline.
- With D3D12Drv active, confirm **Contrast** and **Saturation** appear directly
  below Brightness without overlapping adjacent rows, update the rendered scene
  immediately, display Contrast as 50% through 200% with 100% neutral and
  Saturation as 0% grayscale through 200% boosted, and retain changes after the
  Video page is reopened. Confirm stale raw Contrast values below `64` or above
  `170` render at the nearest supported endpoint. Confirm Saturation reset
  restores 100%. Confirm
  Brightness displays its neutral `0.5` value as 100% and the slider handles
  are 8 pixels wide. Confirm stale Brightness values outside `0.25` through
  `1.0` snap to the nearest slider endpoint when Video Preferences opens.
  Confirm Brightness and Contrast move and display in 1%
  increments. Change Brightness while the menu is visible and confirm the scene
  updates without a renderer flush, texture-precache failure, or Critical Error.
  Set Contrast to 115%, use Preferences Restart, and confirm it still displays
  115% after restart even though the renderer stores the quantized raw value.
  Drag each Video and HUD slider and confirm its displayed value and live
  setting update before releasing the mouse button.
  Confirm both
  D3D12 controls are disabled on other renderers.
- Confirm every visible Video slider has a square reset button whose right edge aligns
  with the slider's former endpoint and whose vertical center aligns with the
  handle. Confirm it is blank rather than showing an unrelated combo-box icon.
  Change each slider, reset it, and confirm its handle, displayed value, live
  behavior, and saved setting return to the documented default. Confirm disabled
  D3D12 sliders also disable their reset buttons.
- With D3D12Drv active, confirm **Bloom Amount** appears directly below
  Saturation, displays 0% through 100%, disables bloom at 0%, changes bright-light
  glow immediately without a restart, leaves HUD glyphs and icons sharply
  rendered without bloom halos, does not brighten the Escape menu artwork or
  text, and retains a positive amount after reopening Video preferences.
- Confirm **Chromatic Aberration** appears directly below Bloom Amount, is fully
  disabled at 0%, produces a strong radial color split at 100%, updates without
  a restart, and retains its value after reopening Video preferences. Check
  opaque, translucent, and modulated HUD/menu elements on both gameplay maps
  and the intro: they must remain sharp, correctly blended, and free of color
  streaks while the 3D world remains processed.
- Confirm **Vignette**, **Film Grain**, and **CRT Scanlines** follow Chromatic
  Aberration, each displays 0% through 100%, defaults and resets to disabled at
  0%, updates live, and persists after reopening Video preferences. At 100%,
  verify darkened corners, frame-varying monochrome grain, and a balanced
  four-row CRT pattern with a dark core, soft shoulder, and two subtly lifted
  phosphor rows respectively. HUD, menu, and intro UI pixels must remain
  untouched, including under 8x MSAA.
- On the `Unreal.unr` intro, compare bloom 0 and 255 while paused. Confirm the
  vendor logos, center logo, NVIDIA badge, FPS text, and **Press ESC to begin**
  do not become bloom emitters while highlights in the 3D background still do.
- With D3D12Drv active, confirm **Antialiasing** offers Off, 2x, 4x, and 8x and
  retains the selected mode after reopening Video preferences.
- Confirm **Anisotropic Filtering** is enabled for D3D12, offers Off, 2x, 4x,
  8x, and 16x, changes texture filtering immediately, and retains the selected
  level after reopening Video preferences and restarting the game.
- Enter a Brute encounter from a freshly launched process and allow several
  projectiles to produce smoke trails and explosions. Confirm the first shot
  does not cause the FPS sample to collapse, actor blob shadows remain visible,
  and projectile visuals, sounds, dynamic lights, decals, damage, and Brute
  behavior remain unchanged on D3D12, OpenGL, and XOpenGL.
- Enable it and confirm the compact statistics appear during play without
  changing flyby interpolation or starting TimeDemo.
- Disable it and confirm the overlay is removed.
- Change a setting, use **Restart**, and confirm the relaunched process retains
  the `D3D12Test.ini` and `D3D12TestUser.ini` command-line arguments.
- In an installer-created runtime, use **Restart** and confirm the relaunched
  process retains `Unreal.ini` and `User.ini`, does not open First-Time
  Configuration, and keeps the ModernMenu root and saved settings.
- Close the installed runtime, launch `System64\UnrealRevived.exe` with no arguments,
  and confirm it opens the same ModernIntro shell without stock intro frames.
- Confirm the installed Start Menu shortcut and, when selected during Setup,
  the desktop shortcut have no arguments and launch the same canonical profile.
- Reopen Video preferences after Restart and confirm the FPS checkbox retains
  its saved state.
- Open **Options > Preferences > Game** and confirm **Console** displays
  **Standard Unreal Console** and cannot open or select another console.
- Confirm Restart leaves `Engine.Engine.Console=ModernMenu.ModernConsole` and Escape
  continues to open the windowed UMenu interface.
- Open **Options > Preferences > HUD** and confirm **Show Game Behind Menus**
  appears below HUD Scaling, aligns with the other checkboxes, and is checked
  by default in a fresh profile. Confirm Crosshair Scale and HUD Scale are
  sliders with 8-pixel handles and show their effective values beside their
  labels with one decimal place. Confirm all four HUD sliders have blank reset
  buttons vertically centered on their handles, with the same 2-pixel right
  inset as combo-box arrow buttons.
  Change each value and confirm reset restores HUD Layout and Crosshair Style
  to index `0`, and both scale controls to `1.5`, including their live and saved
  values. Confirm each button ends at the slider row's original right edge. During
  gameplay, confirm the paused world appears behind the still-open Preferences
  window. Disable the option and confirm the branded background returns.
- Confirm the option persists after reopening Preferences and that the
  normal shortcut's `Unreal.unr` intro/main-menu scene shows its live 3D view
  instead of the branded background when enabled. Disable the option and
  confirm branding returns there as well.
- In the disposable development runtime, launch bare `System64/UnrealEd.exe`
  and confirm its editor viewports remain visible without the full-screen
  branded menu background.

## Installer uninstall checklist

- Create a sentinel file under the installed `Save` directory.
- Start uninstall through Windows Installed Apps and confirm one compact
  branded dialog appears with the banner, clickable GitHub link, and **Keep
  save games** checked by default.
- Click **Uninstall** and confirm removal proceeds without an additional native
  confirmation dialog.
- Complete uninstall and confirm only the retained `Save` directory remains
  under the former installation path, including the sentinel file.
- Confirm a timestamped `Unreal Revived Backup` under Documents contains the
  saves and dedicated profiles.
- Reinstall and confirm the retained saves remain available.
- In an isolated test installation, uncheck **Keep save games**, complete
  uninstall, and confirm the installation copy is removed after backup.
- Launch the uninstaller directly and confirm the same branded dialog appears
  without Inno's additional native confirmation; saves remain retained by
  default.
- Confirm an explicit `/VERYSILENT` uninstall retains saves without prompting.

## Reporting results

VR follow-up checks:

- Run `cmake -S D3D12Drv/tests -B local/build-vr-panel-tests -A x64`, build
  Release, then `ctest --test-dir local/build-vr-panel-tests -C Release` for
  upright orientation, vertical-look fallback and source aspect preservation.
- Follow [the horizon-lock cases](vr-horizon-lock.md): recenter upright, looking
  up/down and with sideways head tilt, then straighten and turn. Software tilt
  must clear while natural head tilt remains tracked and the world reference
  stays level. The separate panel stays upright at eye height along the captured heading;
  opening/closing menus must still leave its anchor unchanged.
- Start through each shortcut and use Preferences Restart. Confirm the same
  requested normal/VR mode, including VR-runtime-unavailable fallback.
- Confirm desktop logs report VR UI buffers disabled, then a successful VR
  startup rebuilds them enabled without missing HUD/menu elements.
- Run the fresh local installer and independently select each desktop icon.
  Check normal targets `UnrealRevived.exe` and VR targets `UnrealRevivedVR.exe`,
  both without shortcut arguments. Launch each executable without arguments:
  the log must select its mode/profile and browse the local startup map
  with no pending connection to `ini=UnrealVR.ini` or host resolution failure.
  Confirm installed VR starts in a 1280x1024 window, desktop retains its own
  display settings, and Preferences Restart keeps the selected profile/mode.
  Change the VR window size and rerun profile installation over existing files;
  confirm display preferences survive. The intentional Setup rerun opens the
  uninstall dialog; uninstall backs up settings to Documents and optionally
  retains saves. User-data backup must include `UnrealVR.ini`.
- Reinstall into a folder containing retained `Save` data and only genuine
  `UnrealRevived/UnrealRevived-Icon-<hash>.ico` branding files without an install
  marker. Confirm the copy proceeds and retains destination saves. Unknown
  files and icons whose contents do not match their filename hash must still
  be rejected. Copy failures must show the underlying error in Setup and its log.

A useful test record includes:

- OldUnreal host and architecture;
- build configuration and commit or working-tree state;
- GPU, driver, desktop resolution, and refresh rate;
- renderer settings changed from defaults;
- checks performed and their outcomes;
- relevant log or screenshot paths under ignored `local/` storage.

## VR resolution and compatibility

Follow [the quality regression and hardware checklist](vr-render-quality.md#validation-and-remaining-acceptance).
HUD/menu texture remains the original fixed size; the optional sharpness feature
was withdrawn. Automated tests cover sizing/limits, rollback descriptor capacity,
aspect labels and the shared production rotated-eye math. Hardware acceptance
remains distinct from mock runtime and WARP validation.

For fresh installer profile generation without launching Setup or touching registry:

```powershell
powershell -NoProfile -File scripts/test-installer-profile-reset.ps1 -StageRoot local/package/offline-installer
```

Use an available staged payload/patch directory. This creates a new directory under
`local/tests`, runs the real profile writer, adds old settings and verifies all four
profiles return to the fresh defaults while a save sentinel remains unchanged.
The disposable directory is removed on success or failure.
The full branded-installer lifecycle separately checks actual uninstall/reinstall
and backup behavior; profile migration is no longer part of that contract.
`scripts/test-branded-installer.ps1` requires an installer compiled from the same
staged payload with `/DValidationBuild` and a new test directory under `local/`.
It verifies production fixture exclusion and launcher startup/restart, backs up
modified settings, retains the save sentinel, and requires all four reinstalled
profiles to match their pre-launch fresh-install SHA-256 hashes exactly.
Startup logs are copied to the test root before uninstall. Its validation-only
registration, shortcuts and uniquely identified backups are removed on success.
VR launcher fallback startup is not evidence of a working headset session.

## Multi-profile controllers and menu back

See [the controller matrix and validation contract](vr-controller-compatibility.md).
Run `scripts/test-menu-back.ps1` with the development menu for hierarchical B/back
and pause-state checks. The native controller lifecycle tests exercise optional
profile rejection and wand combinations; physical controller behavior still needs
reports from owners of the other devices; the owner accepted CV1 Touch/Xbox.

## Stereo vignette

The production shader regression in `vr-ui-occlusion` verifies shared-ray
attenuation for asymmetric FOVs and horizontal/vertical eye cant, center visibility,
slider strength, UI exclusion and unchanged desktop falloff. `vr-pose-math`
checks the production eye-to-head transform under head yaw/pitch and eye cant.
Build/run using the native-test commands in [commands](commands.md).

In CV1 compare 0%, 50% and 100%: one smooth fade around head-forward, no double
circles, stable alignment on yaw/pitch/roll, clear center, readable HUD/menu and
unchanged effect across 75/100/125/150% render quality. Verify desktop appearance
separately. A shared angular mask does not guarantee subjective comfort or
alignment in every untested runtime; report hardware and active profile.

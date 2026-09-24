# Motion-controller aiming

Preferences > VR > **Aiming Method** selects **Head gaze** (default) or
**Motion controllers**. The setting is `VRAimMode=0/1` in
`[D3D12Drv.D3D12RenderDevice]`; it does not enable VR by itself. Launch with the
VR shortcut. The selection persists and can change during a VR session.

For per-weapon shared scale and independent position overrides in both aiming modes,
see [VR weapon tuning](vr-weapon-tuning.md). Defaults preserve the current calibration.
The [crash and performance review](vr-code-audit.md) records the latest checks
and the limits of the automated coverage.

The existing weapon-hand preference chooses the controller:

| Weapon preference | Controller | Mesh |
| --- | --- | --- |
| Right | Right | Visible |
| Left | Left | Visible |
| Center | Right | Visible at the right hand |
| Hidden | Right | Hidden |

Oculus Touch (including Rift CV1) retains its original 17 suggested bindings.
Additional profiles now cover Index, Vive wands, Microsoft motion controllers,
Khronos simple controllers, and optional Cosmos, Focus 3, HP, Touch Pro and Touch
Plus profiles. Extension profiles are enabled only when the runtime advertises
them. A rejected profile does not disable the remaining profiles. Controllers
can connect after startup. Only CV1 Touch and Xbox have owner hardware acceptance.
See [the controller compatibility matrix](vr-controller-compatibility.md).

## Controls

Motion-controller input feeds the existing Xbox input processing and menu navigation in
**both Head gaze and Motion controllers**. The aiming selection changes the aim
source, not whether the Touch buttons/sticks can be used.
It does not rewrite any gamepad bindings. Existing controller dead zones,
sensitivity, and action assignments apply. Keep joystick/XInput input enabled
in the input preferences. Touch and a connected Xbox controller can both be
used: held buttons/triggers are combined, and each stick pair uses the device
with the stronger stick movement. Releasing one device cannot release a button
still held on the other. Keyboard/mouse remain available.

| Touch input | Existing Xbox input |
| --- | --- |
| Left / right sticks | Left / right sticks |
| A, B, X, Y | A, B, X, Y |
| Left / right grip | Left / right shoulder |
| Left / right trigger | Left / right trigger |
| Left / right stick click | Left / right stick click |
| Left menu button | Start |

The system-owned right Oculus button is not rebound. Touch has no dedicated
D-pad or Back button. Stick-based menu navigation continues to work. Primary
fire remains the existing right-trigger binding even with left-hand aiming;
no bindings are automatically swapped. This implementation does not add haptics,
hand meshes, laser menus, physical reloading, or two-handed weapon handling.

Release controls after changing modes. Initial activation requires neutral
controls. Losing the aiming hand releases trigger input; firing requires a
trigger release after tracking returns. Missing tracking does not select gaze.
The VR preferences show whether the selected aiming controller is available.

## Isolation and firing

The renderer attaches the optional action set once during VR session setup.
It synchronizes it in either aiming mode while VR is focused. Failure to initialize motion
input leaves the existing headset renderer available. Desktop launches do not
initialize OpenXR. The default `OPENXRPOSE` contract remains unchanged;
`OPENXRCONTROLLER` and `OPENXRINPUT` provide separate cached controller data.

Controller orientation supplies aim, and the grip position places the weapon.
The same recenter reference and world-size conversion are used for head and
hands. Both eyes use the same controller sample. Weapon animation continues on
the existing weapon actor; the controller overlay temporarily changes its
position, rotation and scale, then restores them. The motion-mode camera removes
stock `WalkBob` before applying tracking so head and hands use the same anchor;
crouching and stair smoothing still use `EyeHeight`. Gaze camera behavior is unchanged.
Stock screen-space muzzle
flashes and the standard reticle are placed at the controller muzzle/aim point.

Weapon hooks normally retain original firing implementations, substituting controller
rotation during synchronous callbacks and restoring the body view afterward.
Class-level Fire/AltFire are re-entered through a narrow native dispatch that
preserves `Global.Fire`/`Global.AltFire`. State-specific no-op Fire functions are
not hooked. This avoids trapping refire in NormalFire and blocking PutDown.
Blocked shots return to Idle or honour a pending switch instead of leaving a
completed firing state with no way to finish.
The firing scope temporarily compensates the stock `FireOffset` so the shot begins
at the controller muzzle. Blocking-world traces check the path to the hand and
barrel before firing. Explicit stock/UPak firing-state adapters cover the
Eightball, Dispersion Pistol, Grenade Launcher and RazorJack special paths.
Eightball target selection and its lock reticle follow the controller.
The stock Eightball/GrenadeLauncher spawn adapters replace their hard-coded
body-relative origins, while RazorJack primary and UPak RocketLauncher adapters
restore their missing lateral offset. Active VR shots follow the computed aim
ray without legacy auto-aim deflection. Weapon spread, gravity and guidance remain
intact. Non-firing reload, zoom and remote-detonation actions bypass muzzle blocking.

Both gaze and tracked first-person meshes are normalized to the same weapon-specific physical sizes
using their measured render bounds (maximum dimension): Automag 40.32 cm,
Dispersion Pistol 48 cm, Stinger 56 cm, ASMD 80 cm, Eightball 85 cm, Flak Cannon
75 cm, Rifle 110 cm, Minigun/QuadShot/CARifle 90 cm, Grenade Launcher 80 cm,
Rocket Launcher 100 cm, and 65 cm for other weapons. Old Weapons subclasses
inherit the same target sizes. One shared per-weapon scale gives equal model
sizes, with independently retained view/controller offsets. Unrelated custom
weapon classes use the generic length; unusual drawing/firing paths may still
need adapters. See [weapon tuning](vr-weapon-tuning.md) for migration details
and the distinction between size coverage and complete gameplay support.

The Automag now uses an initial grip anchor at 20% along its bounds from the
rear, centered laterally, and 25% up from the bottom. The model offset rotates
with the wrist; the muzzle and flash receive the same offset. This calibration
applies to both handed meshes and Old Automag. The resulting calibrated weapon
placement is included in the September 21 accepted milestone.

The stock Automag/Old Automag cache now measures the `Still` frame, temporarily
restoring the live animation immediately afterward. This prevents a pickup,
lowering, reload or twirl pose from becoming a permanent grip/size offset.
Regression tests compare against resting measurements recorded before this
fix, scaled by the subsequently requested 20% pistol enlargement. Both pistols
are 20% larger than the restored build; grip fractions, rendered mesh selection,
and all other weapons' calibration remain unchanged. The broader calibration
pass was reverted following headset feedback.

Gaze's standard crosshair and Eightball reticle now use the same depth treatment
as motion aiming: trace a world target and project it separately for each eye.
The gaze ray uses the calculated camera's head center before IPD, including its
existing bob, height and world-size adjustments. `OPENXRPOSE CENTER` provides
the shared head rotation during stereo drawing. This changes reticle placement,
not gaze firing, camera movement, or desktop crosshairs.

The gaze ray cache belongs to the current player's `ModernVRInteraction`, not
a class default holding a pawn reference. Keeping a pawn in the class default
left a broken pointer during map-load garbage collection when starting a new
game. VR script hooks use the transient package as their outer so console
teardown cannot leave invalid hook owners.

All 14 stock/UPak weapon families use guarded resting-mesh muzzle references in
both modes; replacement meshes retain the forward-bound estimate. QuadShot uses
its muzzle-face centre independently of handed mesh vertex ordering. Multi-barrel
weapons share a reference rather than exposing individual animated sockets.
DispersionPistol updates its muzzle for each power level without changing the
cached model size. These are not animated muzzle sockets. ASMD gaze shots use
the same muzzle transform, and its primary beam's amplified stock visual offsets
are compensated during VR firing only. The mesh, projectile origin and flash
share this geometry and world-size scaling. The owner accepted the calibrated
placement and primary/alternate alignment for the stock/UPak weapon families.
Mods with different spawn/render paths may need their own adapter.

## Multiplayer boundary

No new replicated actors, pawn subclasses, RPCs or network protocol were added.
Stock weapon replication and server authority remain in place. The firing wrapper
requires weapon authority; local VR rendering is not permission to originate
authoritative shots on a remote client.

The full focused firing regression passes for the local player on a loopback
listen server, including stock/UPak primary and alternate paths in synthetic gaze
and motion modes. This does **not** validate a connecting remote client.
Stock `ServerMove` carries pawn position, view angles and firing buttons, not
tracked-hand/head translation or calibrated muzzle offsets. The server therefore
cannot reconstruct those muzzle positions from unchanged stock packets. Local
temporary aim substitutions are restored before ordinary movement replication.
Permitting client-side ScriptHooks alone does not solve this information gap.
Equivalent remote-client VR muzzle origins/aim remain unsupported under the
unchanged-network constraint; no pose replication or server firing replacement
was introduced to claim otherwise.

## Verification and remaining acceptance

Development baseline: `local/backups/vr-motion-baseline-20260919-233710/`.

- Release renderer/input builds and ModernMenu compilation.
- `D3D12Drv/tests/OpenXRControllersTests.cpp`: real input component with a mock
  runtime; inactive VR, disconnected controllers, focus loss, invalid pose,
  mode deactivation, partial initialization failure, and resource teardown.
- Existing panel geometry and gaze movement-axis tests.
- `XInputWinDrv/tests/VRControllerInputTests.cpp`: concurrent Touch/Xbox holds,
  disconnection, stick selection and full-range diagonal input.
- `ModernMenu.ModernVRMotionTestCommandlet`: native hook signatures, stock/UPak
  global hook registration, duplicate prevention and rotation composition.
- `scripts/test-vr-map-travel.ps1`: seeds the VR camera cache and hooks without
  a headset through the production console hook constructor, performs real map
  travel and isolated save/load, checks the new player's cache starts empty,
  and rejects broken references or invalid hook owners through shutdown.
- `ModernVRMotionTestGame`: real engine regression for global versus state Fire
  dispatch, blocked-shot recovery, repeated stock/Old Weapons firing and switching,
  measured physical sizes, a shared baseline and profile scale for both modes,
  exact native state-function resolution and real
  stock/UPak projectile, volley and hitscan origins in both aim
  paths. Run with
  `scripts/test-vr-motion-regressions.ps1`; it uses disposable profiles and exits.
  Size coverage includes all 14 stock/UPak profile classes, two Old Weapons
  subclasses, and a custom fixture with a runtime mesh/view-scale replacement.
  Origin coverage includes saved gaze tuning, both AutoMag/QuadShot handed meshes,
  straight-shot directions, charged shots and non-firing actions near blocked muzzles.
  ASMD checks reconstruct the primary beam origin from the stock effect and
  verify its desktop visual offsets remain unchanged. Stinger/ASMD landmark
  checks preserve live animation and model scale during measurement.
- Startup evidence in `local/logs/automated-20260919-235453/`: motion selected
  with `-novr` did not load OpenXR; both VR selections safely fell back when the
  Oculus runtime reported the headset unavailable. These were fallback tests,
  not successful live stereo/controller sessions.

The September 21 owner acceptance covers the calibrated stock/UPak weapon
sizing, gaze handed placement, motion placement, primary/alternate alignment
and HUD overlap. It supersedes earlier pending weapon-acceptance notes, not
unverified hardware combinations or every tracking-loss/held-input scenario.
Remote-client VR firing remains unsupported. Focus-loss stutter is deferred.

Build the standalone native tests with CMake from `D3D12Drv/tests` and provide
`OPENXR_INCLUDE_DIR` if the pinned SDK is outside `local/build/_deps/openxr-src`.
Run the script commandlet with `IsEditor=False`; the engine disables hooks in
editor commandlets.

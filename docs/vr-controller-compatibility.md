# Headset and controller compatibility

## Preserved CV1 and Xbox behavior

CV1 Touch and Xbox are the owner's available hardware and the acceptance baseline.
Touch's original 17 bindings are retained: sticks, A/B/X/Y, grip-as-shoulder,
triggers, stick clicks and left Menu as Start. Xbox input, binding preferences,
dead zones, sensitivity, tracking-loss firing protection and mixed-device merging
remain unchanged. Head-gaze versus motion aiming still changes aiming only.
Default world resolution, HUD texture, panel layout, distance and scale are unchanged.

## Controller profiles

All profiles feed the existing Xbox-style actions. Profile selection follows the
runtime's controllers, not the HMD brand. A Beyond used with Index controllers
therefore uses Index bindings. No invented PSVR2 or Pimax OpenXR profile is supplied.

| Controller/profile | Mapping to the existing controls | Menu and View/Back |
| --- | --- | --- |
| Oculus Touch / Touch Pro / Touch Plus | Existing Touch controls unchanged | Left Menu = Start; right system button reserved |
| Valve Index | Right A/B = A/B; left A/B = X/Y; sticks, triggers and squeeze retain the same roles | Left trackpad pressure = Start; right trackpad pressure = View |
| Vive Cosmos | Touch-shaped buttons/sticks; digital squeeze supplies shoulder | Left application Menu = Start; right system button reserved |
| Vive Focus 3 | Touch-shaped buttons/sticks and analog squeeze | Left Menu = Start |
| HP mixed reality | Touch-shaped buttons/sticks and squeeze | Left Menu = Start; right Menu = View |
| Vive wands | Trackpad touch moves/turns; triggers fire; grip combinations supply missing face/stick buttons | Left application Menu = Start; right application Menu = B/back |
| Microsoft motion controllers | Sticks and triggers; digital grip = shoulder; pad click = A/X | Left Menu = Start; right Menu = B/back; fewer face buttons |
| Khronos simple controller | Poses, select = A/X, menu = Start | Minimal fallback, not a full gameplay layout |

The optional Cosmos/Focus 3/HP/Touch Pro/Touch Plus profiles require their
advertised OpenXR extensions on this OpenXR 1.0 application. Unsupported suggestions
are isolated; at least one accepted profile is required for motion input. Failure
of motion initialization leaves headset rendering available.

### Vive wand combinations

Wands cannot provide a physical one-to-one match for all Touch buttons. While
holding grip, trackpad movement is suppressed and a clicked upper/lower sector
supplies that hand's primary/secondary button (right A/B, left X/Y). A grip plus
centre click supplies the stick click (right recenter, left crouch by default).
Grip used alone supplies the shoulder action on release; after a combination,
release does not also change weapon. Focus loss/disconnection clears pending
combinations. Ordinary trackpad touch controls movement and turning.
These are application defaults chosen for limited-button hardware, not an
industry-standard layout or a hardware-validated recommendation.

### Start and Select are not system/dashboard buttons

The current Touch left Menu deliberately remains Start, preserving the owner's
mapping. The right Oculus/Meta button cannot be treated as a reliable game Start
button. Index system buttons likewise may be unavailable to applications, so
trackpad pressure supplies game Menu/View without relying on dashboard inputs.
Vive application-menu buttons are distinct from its system buttons.

PSVR2 Create/Options labels describe physical buttons, but their availability
and emulated OpenXR paths are determined by the PC runtime/driver. PSVR2 Sense
and Pimax controllers target the runtime's supported/emulated profile, commonly
a Touch-shaped layout. In SteamVR, select an accepted interaction profile and
remap application controls if the driver's automatic mapping differs. Match
Cross/Circle/Square/Triangle to A/B/X/Y where supplied, and assign an available
Create/Options control to the menu action. This is a compatibility route to
validate, not a claim that every driver maps those buttons automatically.

## Headset rendering

Eye dimensions, limits, positions and asymmetric FOVs remain runtime-driven.
The application does not apply its own lens-distortion correction or model-specific
IPD/FOV constants. Parallel-eye head orientation retains the CV1 baseline exactly.
When eye orientations differ, the renderer uses the runtime VIEW reference-space
orientation; if unavailable, it uses the shortest-path midpoint of both eye
orientations. This prevents inheriting left-eye cant for gaze/recentering.
Eye rendering/submission still uses each original eye pose and FOV. The existing
170-degree culling cap remains a hardware-validation concern in extreme wide-FOV modes.

Targets: Quest 2/3/3S/Pro through PC VR; Index; Vive Pro/Pro 2/Cosmos;
Beyond/Beyond 2; Pimax Crystal/Crystal Light; PSVR2 with its PC setup.
Only CV1 has owner optical validation. All other devices require owner/community
reports; panel specifications and mock tests do not prove stereo comfort.

## Menu back behavior

B closes one level: binding capture, modal dialog, focused dropdown, open menu
list, then the visible dialog/frame. Closing Preferences keeps the menu paused;
B at the root resumes play. Start continues to toggle the full menu as before.
The active Unreal Revived GUI skin is included in the Preferences skin list,
preventing an unintended skin reset of the whole menu on close. Mouse-driven
window closing is otherwise left on its existing path.

## Validation and diagnostics

`vr-controller-lifecycle` tests original Touch binding count, extension gating,
independent rejected profiles, digital grip paths, Index button names, no system
button dependencies, wand combinations, disconnect/focus reset and resource cleanup.
Pose tests cover cant, quaternion sign equivalence and the unchanged parallel-eye
path. Existing Xbox direction, merging and input-guard tests remain in use.
`scripts/test-menu-back.ps1` drives the actual console B press/release through
dropdown, modal, stale frame focus, Preferences and root, checking pause state.

`D3D12 OPENXRPROFILES` reports each hand's current runtime interaction profile.
Together with `D3D12 VRRENDERSIZE 0/1`, this makes external reports actionable.
Record runtime version, headset, controller model, active profile and any physical
button that does not produce the expected action. Test each hand, held-input
release, disconnect/reconnect, menus, firing and recentering. CV1 Touch plus Xbox
should retain the accepted controls; this build still needs that visual/manual check.

## Primary references

- [Khronos controller component definitions](https://raw.githubusercontent.com/KhronosGroup/OpenXR-Docs/main/specification/sources/chapters/semantic_paths.adoc): available inputs and reserved system controls.
- [Khronos registry](https://raw.githubusercontent.com/KhronosGroup/OpenXR-Docs/main/specification/registry/xr.xml): profile paths, component types and extension contracts.
- [Valve OpenXR driver compatibility](https://github.com/ValveSoftware/openvr/blob/master/docs/Driver_API_Documentation.md#application-compatibility): automatic rebinding and emulated profiles.

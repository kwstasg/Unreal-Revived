# Seated PC VR first-milestone plan

The accepted spatial UI implementation and maintenance rules are documented in
[the VR UI milestone](vr-ui-recovery-design.md). Failed approaches are historical
evidence in [vr-ui-investigation.md](vr-ui-investigation.md).

## Status

Opt-in [motion-controller aiming](vr-motion-controllers.md) adds a second aiming
method. The owner accepted the shared gaze/motion weapon sizing, placement,
firing alignment and HUD overlap on September 21. Other controller profiles and
remote-client VR firing remain outside the validated support boundary.

This document records the implemented seated VR mode and its remaining roadmap. The
mode-selection, loader, runtime/HMD detection, D3D12 compatibility, session
lifecycle, frame timing, independent eye rendering, runtime IPD, asymmetric
projection, and seated head-pose bridge are implemented locally. Live Oculus
Rift CV1 validation confirms fused stereo with natural depth, correct scripted
camera direction, natural yaw/pitch/roll, no visibility gaps, and no rotational
stretching or swimming. The vertical optical-center mapping accounts for UE1's
positive-down camera Y and the renderer's final vertical presentation flip.

The first-person weapon follows headset rotation and seated leaning through a
render-only placement path. Scoped gaze/motion firing hooks align actual shots
with the calibrated muzzle without changing scripted cameras. The September 21
milestone accepts all 14 stock/UPak weapon profiles; custom weapon adapters and
remote-client multiplayer remain separate compatibility work.
Head-oriented gamepad walking/strafing and horizontal right-stick turning were
user-validated on 2026-09-11, including movement while looking 90 degrees left/right.
Gaze-directed swimming/flying and right-stick turning were subsequently fixed
and accepted on September 24. Mirror selection, broader gameplay validation
and other-runtime hardware coverage remain open.
Head-collision fade was user-validated on 2026-09-15: walls, corners and low
ceilings fade to black and recover on retreat; a door, world-size adjustments,
swimming in water and an elevator behaved normally.
The eye swapchains use the runtime-recommended resolution; the UE1 scene is
still rendered at the selected logical game resolution before being scaled
into those swapchains.

The spatial HUD/menu milestone was accepted in the headset on 2026-09-10:
desktop-like canvas layout, one upright fixed panel, stable live distance/scale,
and explicit UI recenter. This supersedes earlier plans for automatic panel
following or larger menus that recenter on opening. Explicit Recenter VR View
now captures full gaze orientation once; its pitch/roll behavior, quick bindings
and UI color correction were subsequently accepted by the user.

## Implementation alignment checkpoint

- Complete and live-validated: strict opt-in mode isolation, runtime/HMD and
  D3D12 checks, session lifecycle, predicted frame timing, two eye swapchains,
  independently culled views, runtime IPD and asymmetric FOV, correct scripted
  camera direction, and distortion-free yaw/pitch/roll on Oculus Rift CV1.
- Complete and live-validated: render-only first-person weapon following for
  headset rotation and seated leaning without changing gameplay state.
- Implemented but needing focused live validation: representative stereo
  rendering across geometry, skyboxes, particles, transparency, mirrors,
  portals, and additional scripted cameras and weapons.
- Complete and user-accepted: spatial HUD/menu layout and VR preferences,
  shared upright panel, independent distance/scale and explicit UI recenter.
- User-validated: gamepad headset-yaw walking/strafing and horizontal right-stick
  turning. Gaze aim hooks still need broader weapon checks. The script-side menu-open
  recenter left behind by the earlier cleanup was removed on 2026-09-11.
- User-validated: combined view/UI recenter, including full gaze panel placement,
  software tilt reset, right-stick click/F10 bindings and corrected UI colors.
- User-validated on 2026-09-15: progressive head-collision fade and recovery at
  walls, corners and low ceilings, plus a door, world-size adjustments, swimming
  in water and an elevator. This covers the reported scenarios, not every custom
  map or trigger. Swimming movement semantics remain a separate roadmap item.
- Still to implement: swimming/
  flying movement semantics, desktop-mirror selection, and
  incompatible-overlay handling; finer weapon placement remains optional tuning.
- Still to validate before support: saves and multiplayer behavior in VR,
  recovery/failure cases with a live runtime, Meta and SteamVR parity, extended
  comfort testing, and packaged-install behavior.

## Goal

Add optional, seated-first PC VR through OpenXR while preserving the existing
flat-screen experience. Both modes will use
`D3D12Drv.D3D12RenderDevice`; players will not need to change video drivers.

The milestone includes true stereo, seated 6DoF tracking, head-gaze aiming,
gamepad locomotion, smooth right-stick turning, the accepted fixed shared HUD/menu
panel with explicit recenter, and fade-based head collision.

## Mode selection and non-VR isolation

- Flat-screen play is free of all VR behavior by default.
- `-vr` requests the OpenXR runtime, HMD detection, and guarded D3D12 session
  handshake; `-novr` disables it and wins if both switches are present.
- Mode is selected with normal/VR shortcuts (`-novr`/`-vr`). The redundant startup
  checkbox was removed at user request. `EnableVR` remains a low-level legacy
  config fallback for direct launches; Preferences Restart preserves launch mode
  with an explicit switch, even after headset-unavailable fallback.
- Command-line arguments override the stored preference.
- Do not initialize OpenXR, activate headset software, allocate stereo eye targets,
  or query runtime tracking during non-VR play. Shared code probes cached pose
  availability, but VR UI postprocess textures/descriptors are now allocated only
  when OpenXR rendering is ready. Buffer readiness handles the transition after
  initial desktop-sized allocation. The user accepted the resulting active VR
  behavior; desktop/fallback allocation checks are also recorded in the audit.
- Keep the existing single-view D3D12 path unchanged behind a strict runtime
  branch.
- Missing loaders or runtimes, unavailable HMDs, and incompatible graphics
  adapters are diagnosed and continue safely in flat-screen D3D12. A compatible
  session renders independently culled views for both eyes while the monitor path
  stays active.
- Keep OpenGL and XOpenGL as non-VR recovery renderers.
- Require a restart when entering or leaving VR; do not transition the renderer
  live.

## VR options

Implemented in the dedicated VR preferences page:

- Recenter VR View: level software tilt, make current horizontal gaze forward,
  refresh the seated tracking reference, and recenter the shared panel.
- HUD distance and scale.
- Basic active/inactive status.
- Explicit normal/VR shortcuts select the mode; Preferences Restart preserves it.

UI recenter and HUD adjustments update immediately in VR.
Motion aiming and multi-profile controller mappings are implemented; see
[controller compatibility](vr-controller-compatibility.md). Stereo-aligned VR
vignette masking is implemented and awaits CV1 visual/comfort acceptance.

Pending: selectable left/right/off desktop mirror and more
detailed runtime/headset status. Automatic/delayed HUD following was superseded
by the user-accepted fixed panel and must not be reintroduced by assumption.

## Stereo camera and head collision

- Use the system's active OpenXR runtime through a vendor-neutral path.
- Render independently culled left- and right-eye scenes using runtime poses,
  asymmetric projections, IPD, recommended resolution, and frame timing.
- Use a seated/local reference space; recenter makes the current seated pose
  and yaw neutral.
- Track head orientation and seated leaning independently of the gameplay
  collision capsule.
- Preserve 1:1 physical head tracking without clamping or pushing the camera.
- Fade the headset image progressively when the tracked head enters solid
  geometry and restore it when the head returns.
- Ignore triggers, water, portals, non-solid decorations, and other
  non-obstructing surfaces.
- Preserve Unreal's existing player collision for gamepad-driven movement.
- Adapt or suppress incompatible view bob, forced pitch, camera roll, and
  screen overlays.
- Provide an optional single-eye desktop mirror.

## Controls and aiming

- Use the left stick for forward/backward movement and strafing.
- Orient movement to headset yaw while ignoring head pitch and roll.
- Use the right stick for smooth horizontal body/world rotation only.
- Keep head rotation independent of right-stick turning.
- Aim the crosshair and weapon through the center of the headset view.
- Preserve muzzle origin, close-wall obstruction, projectiles, hitscan,
  spread, recoil, and weapon-specific offsets.
- Retain the existing SDL gamepad, keyboard, and mouse paths.
- Use the existing crouch action; physical crouching is not required.

Current implementation scope: SDL/XInput first-person walking/falling with a
valid cached OpenXR pose. Rotate shaped movement axes into horizontal gaze space,
accounting for body/view yaw and axis speed. Raw JoyZ/JoyR menu input is unchanged.
Plain JoyX aStrafe / JoyY aBaseY bindings are supported; custom aliases and compound
commands are preserved without remapping. Keyboard/mouse, third-person cameras,
flybys, swimming/flying and unavailable tracking retain their existing paths.

## HUD and menus

- Render the HUD as a floating stereo panel with adjustable depth and scale.
- Keep it stable during ordinary head movement.
- Use one fixed panel anchor for HUD, intro and menus; no automatic following.
- Do not continuously follow head pitch, roll, or seated leaning. Explicit
  Recenter VR View captures full gaze orientation once, including pitch/roll.
- Capture horizontal heading and eye height at session initialization or low-level
  UI-only reset. Explicit view recenter captures all three orientation axes;
  gamepad turning and opening menus do not reset this reference.
- Keep the crosshair head-gaze aligned independently from the HUD panel.
- Preserve identical panel geometry when opening or closing menus.
- Recenter the shared panel only with the VR Preferences Recenter control.
- Preserve existing gamepad menu navigation.

## Architecture and compatibility

- Add OpenXR discovery, session lifecycle, reference-space tracking, timing,
  D3D12 binding, swapchains, submission, and diagnostics to the D3D12 package.
- Add a narrowly version-pinned OldUnreal 227k_15 bridge capable of producing
  two correctly positioned and culled scene views per simulation frame.
- Initialize and execute the bridge's stereo path only while VR is active.
- Tear down OpenXR resources safely during shutdown and failure recovery.
- Preserve existing maps, saves, gameplay classes, multiplayer protocol,
  configuration, installation, uninstall, and recovery workflows.
- The pinned Khronos OpenXR loader is packaged for VR use and remains unloaded
  during normal play.

## Acceptance testing

- Confirm normal launches never open or query a VR runtime and incur no stereo
  allocation or per-eye rendering cost.
- Compare flat-screen rendering, screenshots, frame pacing, input, menus,
  saves, profiles, multiplayer, and recovery behavior with the existing
  baseline.
- Test normal and VR launch modes, stored preference, command-line overrides,
  restart messaging, missing-headset fallback, and failed-session recovery.
- Validate stereo depth, scale, IPD, FOV, geometry, skyboxes, mirrors, portals,
  particles, transparency, weapons, overlays, and post-processing.
- Verify seated tracking, leaning, recentering, locomotion, turning, crouching,
  jumping, swimming, flying, elevators, and scripted cameras.
- Verify head-collision fading without changing the OpenXR pose.
- Test head-gaze aiming, recoil, spread, projectiles, hitscan weapons, muzzle
  obstruction, and nearby targets.
- Confirm fixed shared-panel behavior, explicit recenter, live scale/distance
  changes, spatial menus, and mirror selection.
- Validate Meta OpenXR first and SteamVR second with the same executable.
- Regression-test ordinary D3D12 plus OpenGL and XOpenGL recovery startup.

## Deferred work

The first supported configuration is seated gamepad play with smooth turning
and horizontal head-oriented locomotion. Standing tracking may work but is not
an acceptance requirement. Motion-controller aiming and bindings are implemented. Tracked hands,
teleportation, snap turning, room-scale design and advanced comfort settings
remain future work. The vignette now preserves the desktop effect and uses a shared angular
fade in VR; headset acceptance remains pending.

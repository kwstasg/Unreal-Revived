# Seated PC VR first-milestone plan

## Status

This document is the implementation plan for a future supported VR mode. The
mode-selection, loader, runtime/HMD detection, D3D12 compatibility, session
lifecycle, frame timing, independent eye rendering, runtime IPD, asymmetric
projection, and seated head-pose bridge are implemented locally. Live Oculus
Rift CV1 validation confirms fused stereo with natural depth, correct scripted
camera direction, natural yaw/pitch/roll, no visibility gaps, and no rotational
stretching or swimming. The vertical optical-center mapping accounts for UE1's
positive-down camera Y and the renderer's final vertical presentation flip.

This is a validated rendering milestone, not a supported VR release. Head-gaze
aiming, head-oriented locomotion, recentering, head-collision fade, spatial HUD
and menus, mirror selection, broader gameplay validation, and SteamVR coverage
remain incomplete. The eye swapchains use the runtime-recommended resolution;
the UE1 scene is still rendered at the selected logical game resolution before
being scaled into those swapchains.

## Implementation alignment checkpoint

- Complete and live-validated: strict opt-in mode isolation, runtime/HMD and
  D3D12 checks, session lifecycle, predicted frame timing, two eye swapchains,
  independently culled views, runtime IPD and asymmetric FOV, correct scripted
  camera direction, and distortion-free yaw/pitch/roll on Oculus Rift CV1.
- Implemented but needing focused live validation: seated positional leaning
  and representative stereo rendering across geometry, skyboxes, particles,
  transparency, weapons, mirrors, portals, and scripted cameras.
- Still to implement: recentering, headset-yaw locomotion, right-stick body
  semantics, head-gaze weapon aim, collision fade, spatial HUD and menus,
  desktop-mirror selection, VR preferences, and incompatible-overlay handling.
- Still to validate before support: saves and multiplayer behavior in VR,
  recovery/failure cases with a live runtime, Meta and SteamVR parity, extended
  comfort testing, and packaged-install behavior.

## Goal

Add optional, seated-first PC VR through OpenXR while preserving the existing
flat-screen experience. Both modes will use
`D3D12Drv.D3D12RenderDevice`; players will not need to change video drivers.

The milestone includes true stereo, seated 6DoF tracking, head-gaze aiming,
gamepad locomotion, smooth right-stick turning, a Skyrim-style delayed-following
HUD, spatial menus, and fade-based head collision.

## Mode selection and non-VR isolation

- Flat-screen play is free of all VR behavior by default.
- `-vr` requests the OpenXR runtime, HMD detection, and guarded D3D12 session
  handshake; `-novr` disables it and wins if both switches are present.
- The persistent `EnableVR` renderer setting is available for development and
  takes effect on launch. Its future menu checkbox is not implemented yet.
- Command-line arguments override the stored preference.
- Do not initialize OpenXR, activate headset software, allocate stereo targets,
  query tracking, or run VR logic during non-VR play.
- Keep the existing single-view D3D12 path unchanged behind a strict runtime
  branch.
- Missing loaders or runtimes, unavailable HMDs, and incompatible graphics
  adapters are diagnosed and continue safely in flat-screen D3D12. A compatible
  session presents the same completed game image to both eyes while the monitor
  path stays active.
- Keep OpenGL and XOpenGL as non-VR recovery renderers.
- Require a restart when entering or leaving VR; do not transition the renderer
  live.

## VR options

Add a dedicated VR preferences page containing:

- Enable VR on next launch.
- Recenter seated view.
- HUD distance and scale.
- Delayed HUD following.
- Desktop mirror selection: left eye, right eye, or disabled.
- Active OpenXR runtime, detected headset, and session status.
- Clear restart-required messaging when VR mode changes.

Recenter and safe HUD or mirror adjustments may update immediately in VR.
Broader comfort and motion-control options are deferred.

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

## HUD and menus

- Render the HUD as a floating stereo panel with adjustable depth and scale.
- Keep it stable during ordinary head movement.
- Begin horizontal following when the player looks approximately 55 degrees
  away, then move smoothly until it returns to approximately 35 degrees from
  the current view.
- Do not follow head pitch, roll, or seated leaning.
- Translate the HUD with gamepad locomotion.
- Treat right-stick body turning as the new forward reference immediately.
- Keep the crosshair head-gaze aligned independently from the HUD panel.
- Render menus as larger spatial panels that remain fixed after opening.
- Place a menu directly ahead when it opens or the player recenters.
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
- Confirm HUD dead-zone behavior, delayed following, live scale/distance
  changes, spatial menus, and mirror selection.
- Validate Meta OpenXR first and SteamVR second with the same executable.
- Regression-test ordinary D3D12 plus OpenGL and XOpenGL recovery startup.

## Deferred work

The first supported configuration is seated gamepad play with smooth turning
and horizontal head-oriented locomotion. Standing tracking may work but is not
an acceptance requirement. Motion controllers, tracked hands, teleportation,
snap turning, room-scale design, comfort vignette, and advanced comfort
configuration belong to later milestones.

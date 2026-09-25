# VR horizon-lock investigation

## World reference and tracking

The September 25 audit found that `PrepareOpenXRFrame` captured the full head
quaternion as `OpenXRBaseOrientation` on first tracking and explicit recenter.
The renderer then used inverse(base) * eye for orientation and inverse(base)
for eye/head/controller translation. Recenter while pitched or rolled therefore
stored that tilt in the world reference: straightening the head introduced the
opposite virtual tilt. Software pitch recovery alone cannot correct this.

The world reference now captures horizontal heading only. Looking up/down or
rolling the head remains naturally tracked, including at the instant of recenter.
Returning upright leaves no captured world tilt. Near vertical gaze, where heading
is undefined, capture retains the previous heading (identity on first startup).
Recenter transfers the change in horizontal heading to pawn yaw before capturing
the new reference, preserving the facing direction. Position is still recentered.

The HUD anchor is separate. Following owner feedback that the world was fixed
but the HUD still tilted, explicit recenter now captures heading only for the
panel too. It stays upright at eye height instead of storing recenter pitch/roll.
Its distance, size, projection and menu-transition behavior are unchanged.
Scripted `PlayerCalcView` rotations still
compose with tracking; authored flyby/view-target tilt is not flattened.

## Audited entry points

- Mouse: `SuppressVRMousePitch` suppresses plain MouseY look-axis bindings only
  during active first-person VR. Horizontal mouse input, menus, desktop,
  alternate cameras and compound/custom aliases retain their existing behavior.
  This is not a promise to suppress arbitrary scripted/custom tilt commands.
- Load/travel: `ModernVRInteraction` uses a transient initialization flag, resets
  it on `NotifyLevelChange`, and levels software pitch/roll before the first
  eligible first-person calculated view. Head orientation remains tracked.
- Remount: `VRPitchRecovery` schedules software leveling on user-presence return,
  or hidden-to-focused transitions when presence events are unavailable. Focus
  return alone is not a recenter. Session restart captures a heading-only world
  reference; ordinary remount does not move the HUD anchor.
- Explicit recenter: software pitch/roll and pending vertical input are cleared;
  world heading/position and the independent upright UI reference are captured
  between eye frames. No controller mappings changed.

## Evidence and remaining acceptance

Production pose-math tests cover pitched/rolled recenter, straightening, preserved
natural tilt/yaw, vertical-gaze fallback and composition with an authored camera.
The nine native suites include remount scheduling and the stereo vignette shader.
These are automated/math checks, not CV1 optical or comfort acceptance.
Canonical builds, gameplay and save/load/travel regressions passed. The packaged
launcher initialized Oculus/CV1 and all four live eye-size probes passed outside
the sandbox, but the session remained idle with no stereo frames submitted.
The earlier sandboxed probe reported runtime unavailable (-51). Evidence is in
`local/logs/horizon-20260925`; neither result substitutes for the following checks.

In CV1, repeat startup, save loading and remove/replace with the head upright,
looking up/down and tilted sideways. Recenter in each pose, then straighten and
turn left/right: world verticals must stay aligned with physical gravity, while
natural head motion stays visible. Check mouse yaw and vertical mouse movement,
the intro flyby and view-target cameras. The HUD should remain upright at eye
height along the captured horizontal heading, and stay fixed when menus open/close.
The owner confirmed the world fix; the updated HUD behavior still needs CV1
acceptance. Focus-loss stutter remains closed.

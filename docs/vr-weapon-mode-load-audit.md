# Motion save, restart, load, then gaze: code audit

The owner's clarified sequence is: play using motion controllers, save, exit,
start again, load that save while still using motion, then select gaze. The issue
did not recur after reverting `d267b77`, but is not established as fixed.

## Findings

- `ModernVRConfigCW.Notify` sends `D3D12 VRAIMMODE`. The renderer updates its
  configured mode and clears controller input state. It does not modify weapon
  placement, reinitialize handedness or clear the script geometry cache.
- `ModernVRInteraction.RenderControllerWeapon` temporarily changes location,
  rotation and draw scale, then restores them synchronously. It does not install
  motion profile offsets into `PlayerViewOffset`. Gaze rendering separately reads
  gaze calibration and restores its temporary view offset, draw scale and player
  view rotation. Firing hooks likewise restore their temporary fire offset.
  No direct motion-offset-to-gaze assignment was found in these paths.
- Both aiming modes use `ModernVRMotionSupport.Default.Geometry`. Its cache key
  includes weapon class, view mesh and view scale, not animation or aiming mode.
  A new process starts without the prior process's computed cache. First geometry
  use can occur in motion after loading, and gaze then reuses that entry. Most
  weapon bounds depend on the animation at that first measurement. This is a
  plausible history-sensitive path, not proof of the reported visible offset.
- The host's saved-game `PlayerPawn.Possess` branch does not call `SetHand`.
  Normal `ChangedWeapon` does call it. The copied owner save contained both
  initialized and uninitialized inventory offsets; unequipped defaults alone
  are not evidence that the equipped weapon is wrong. Gaze uses the current
  weapon's `PlayerViewOffset`, so diagnosing this requires the equipped value.
- The reverted test selected gaze before loading and reused the process. It did
  not reproduce the clarified sequence. It also explicitly initialized hand
  offsets, so it could not establish correctness of restored hand state.

## Next reproduction boundary

Use isolated saves and profiles, two separate game processes, and record the
equipped weapon before saving, immediately after load in motion, and after gaze
selection. Compare view/fire offsets, handedness, live/view meshes, draw/view
scales, animation/frame and the first cached geometry. Check weapon switching
separately; do not initialize SetHand as part of the observation. Distinguish
position from size and compare against a fresh gaze run of the same save.

This audit changes no runtime behavior. The rejected fixed-pose sizing approach
must not be reinstated based on cache consistency tests alone. Preserve the
current geometry, accepted calibration, HUD and controls until the visible
failure is tied to a specific state difference.

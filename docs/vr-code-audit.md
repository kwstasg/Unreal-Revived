# VR crash and performance review — 2026-09-20

Scope: recent gaze crosshair, controller aiming/input, weapon geometry, tuning
INI, live reload, and their object lifetimes. This is a source review and engine
regression run, not a complete CV1 frame-time capture or proof that no crashes remain.

## Crash checks

The earlier map-load crash was reproduced as a broken `CrosshairPlayer` reference
in `ModernVRAimSupport` class defaults. Its ray cache now belongs to the current
player's interaction. The hook objects' invalid console outer at shutdown was
also corrected before this review.

The expanded travel regression populates VR caches, performs three real map
changes, rebinds the same hook objects after each transition, verifies that new
players do not inherit the previous camera ray, and shuts down. It passed without
broken-reference or invalid-outer warnings. The newly cached profile indices hold
weapon classes, not player or weapon actor instances, and passed these transitions.

No additional crash cause was reproduced in this review. Save/load transitions,
custom weapon scripts, remote multiplayer, and hardware/runtime device loss
still need their own end-to-end coverage.

## Performance changes

- Tuning now resolves each weapon class to its nearest matching INI profile once
  per settings instance. Warm calls compare class pointers and read the selected
  profile, avoiding repeated ancestor walks and case-insensitive string matching.
  Live reload replaces the instance, invalidating cached profile indices; profile
  removal and inherited overrides remain covered by tests.
- `OPENXRMOTIONACTIVE` supplies the same mode-selection result without building a
  complete controller pose or converting its quaternion. Actual pose reads now
  request the controller pose once instead of requesting it once to check the mode
  and again to parse it. Tracking poses are not cached by these changes.

One engine microbenchmark of 8,000 mixed stock/inherited/unmatched profile lookups
reported **115.23 ms before versus 3.91 ms cached**, with identical selected
profiles and a stable cache size. This measures profile lookup only, not total
frame time or VR FPS. The source test includes the old lookup for comparison.

## Remaining frame-time considerations

The new controller component synchronizes once per OpenXR frame and queries its
action states without per-frame logging or asset loading. Geometry measurement
is cached by weapon class/mesh/view scale. INI disk reads happen on initial use
and explicit reload, not each draw; pressing reload can still cause a brief
synchronous pause.

Each stereo eye still performs camera collision and crosshair traces and draws
its weapon. OpenXR frame/swapchain waits and GPU fence waits remain in the existing
renderer. Their contribution, initial asset uploads, and sustained firing costs
need CPU/GPU frame-time captures on the headset before claiming stutter is fixed.
No changes to these timing-sensitive paths, weapon calibration, or INI values
were made in this review.

## Verification

- Native renderer build and script compilation: passed.
- Firing, switching, profile lookup/override/removal, physical geometry: passed.
- Three map changes, hook rebinding and shutdown: passed.
- Live disk edit/reload and removal of a profile: passed; user's INI restored.
- Four standalone panel, controller lifecycle, movement-axis and combined-input
  tests: passed (including mocked focus/tracking loss and partial initialization).

Evidence in the development runtime:
`VRMotionRegression-20260920-234234.log`, `VRTravel-20260920-234240.log`, and
`VRReload-20260920-234248.log` in `local/game/System64`.

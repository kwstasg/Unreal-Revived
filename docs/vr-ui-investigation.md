# VR UI investigation log

This document records headset-observed VR UI behavior, failed experiments, and
the constraints for the next implementation. It exists to prevent repeating
the September 2026 trial-and-error cycle.

## Restored baseline

- Baseline commit: `9dc4802` (`Add OpenXR UI Layer Support and VR UI
  Enhancements`).
- Restored and deployed on 2026-09-10 after the later experiments regressed the
  UI.
- The baseline uses a 1024x1024 OpenXR UI swapchain, a 1.60 metre quad, and a
  `VRMenuScale` of 0.40 in `ModernRootWindow`.
- The baseline is not correct: the menu appears in the headset, but is too
  small and partially clipped. It is nevertheless the last known state that
  shows useful menu content and is the mandatory starting point.

## Confirmed headset observations

- In the flyby intro, the menu can be clipped or absent and the logo/splash
  elements are outside the useful view.
- In playable maps, the HUD is visible, but its position and scale still need
  comfort tuning.
- The menu has the same readability and clipping problem in flyby and playable
  maps.
- Updating HUD controls continuously originally made the HUD jump. Separating
  control interaction from recentering removed that jump.
- The distance control produced only a small perceived change and needs a
  physically meaningful range and mapping.
- The VR panel must not inherit head roll. This requirement has not yet been
  independently implemented and validated.
- Curvature is a requested enhancement, not a solution to the missing-menu
  problem. It must wait until a complete flat menu is visible.

## Failed or inconclusive experiments

### Logo and intro special handling

Attempts to recover or separately position the intro logos made the result
worse: at one point only the Unreal logo was visible and the menu disappeared.
The logo work was abandoned. Do not reintroduce logo composition until the
entire menu is stable; hiding the logos is acceptable for the first working
version.

### Increasing panel size as part of a combined layout rewrite

A wider, resolution-aware UI swapchain and panel were introduced together with
changes to menu scaling, placement, orientation, and presentation. The result
was not a wider complete menu: the menu disappeared or only a small fragment
was visible. Because several coordinate systems changed at once, that test did
not identify a single cause and must not be repeated as one combined patch.

### Root-window paint-bound and coordinate changes

Changing the root window's paint boundaries and attempting to derive the VR
layout from the desktop resolution did not restore the menu. UE1/UWindow's
logical size, GUI scale, render-target pixels, quad metres, and eye projection
were mixed together. Future work must measure and log each space explicitly
before converting between them.

### Presentation flip, depth, and composition guesses

Experimental vertical flipping, depth-write changes, and other presentation
state guesses did not produce a confirmed improvement. The depth change was
reverted. These states must not be changed again without a capture or log that
demonstrates the specific fault.

### Opening Preferences automatically and synthetic input

Forcing a window open and using automated mouse/hotkey input were unreliable
diagnostics. DirectInput focus, flyby state, and UWindow state made the results
ambiguous. They are not acceptance tests for menu composition.

### Using the desktop mirror as proof of headset UI output

The ordinary desktop image is not a reliable view of the OpenXR composition
layer. It can show the non-VR game frame while the headset UI layer is missing,
clipped, or positioned elsewhere. A desktop screenshot alone must never again
be treated as proof that the headset menu works. Mirror-based validation is
valid only after the mirror explicitly composites the same UI layer submitted
to OpenXR.

### VR preferences page

A dedicated VR tab with enable, distance, scale, and recenter controls was
implemented, but it was removed during the rollback because it was coupled to
the broken panel/layout work. The product idea remains valid. Reintroduce the
tab only after the base menu is fully visible, and land it separately from
renderer geometry changes.

## Rules for the next attempt

1. Start every experiment from commit `9dc4802` or a descendant proven to have
   the same partially visible menu.
2. Change one coordinate boundary per build: UWindow logical canvas,
   UI-swapchain extent, texture sampling, quad physical size, or quad pose.
   Never change two of these in the same diagnostic build.
3. First goal: show the complete existing menu on a flat, no-roll panel. Ignore
   logos, curvature, preferences, and HUD comfort tuning until that passes.
4. Add an explicit debug visualization to the UI texture: full-target border,
   centre lines, and labelled corners. Confirm which edges reach the headset
   before changing scale or dimensions.
5. Log, for the same frame, the UWindow root size, GUI scale, requested paint
   rectangle, UI swapchain extent, sampled UV rectangle, quad size in metres,
   pose, and submitted layer type.
6. Validate in the headset. If desktop validation is required, first implement
   an explicit debug mirror of the UI swapchain rather than inferring headset
   output from the ordinary game mirror.
7. A change is retained only if it improves the single targeted measurement.
   Otherwise revert it immediately before starting another experiment.
8. Do not tune HUD distance/scale while dragging by recentering or rebuilding
   panel pose; slider interaction must not move the panel anchor unexpectedly.

## Next isolated diagnostic

Keep all baseline geometry and composition unchanged. Add only the debug border
and corner labels to the existing 1024x1024 UI target, with a way to copy that
exact target to the desktop for inspection. This will distinguish source
clipping from UV cropping, quad framing, and headset field-of-view placement
without another speculative layout rewrite.

# Standing HUD strategy and turning choices

## Preserve the accepted seated baseline

CV1 world/HUD horizon lock and vignette were accepted at `232f768`. Automatic HUD
recovery now builds on that upright shared panel without a seated/standing option.
Small seated movements remain fixed. The follow and recenter-height changes
pass automated tests and were accepted by the owner on CV1 at `b69ae2c`.
Full room-scale gameplay is
not claimed. Turning choices do not change headset pitch/roll tracking.

## Automatic standing HUD

There is no new setting. Keep one shared panel, the accepted symmetric canvas
projection, upright heading, distance/scale controls and weapon/UI composition.
Only the panel anchor follows sustained physical movement.

- After head-center displacement exceeds 20 cm for 0.3 seconds, ease the anchor
  toward the head until within 2 cm. Translation is capped at 1.5 m/s, with no
  overshoot. Small seated motion does not move the panel.
- Keep yaw stable during small glances. After a sustained horizontal turn outside
  a dead zone, ease the panel back into view. Never capture pitch or roll. CV1
  has no torso tracker, so this approximates body-relative UI with horizontal
  headset heading and hysteresis, rather than claiming measured body orientation.
- Begin yaw catch-up after exceeding 35 degrees for 0.3 seconds, finish within
  15 degrees of forward, and cap speed at 90 degrees/second. These thresholds
  need CV1 testing and are not platform requirements.
- Explicitly opening the menu summons the panel once only if displaced beyond
  20 cm or 35 degrees, then freezes it during interaction. Nested dialogs,
  dropdowns and slider adjustments must not recapture or move it. Recenter stays
  available to bring it back after walking away. Nearby seated menu transitions
  retain their anchor. Follow resumes after closing the menu.
- Freeze on invalid tracking, reset follow timing on recenter or tracking return,
  and retain horizontal heading near vertical gaze. Do not alter the world
  reference to move the HUD.

This strategy adapts Microsoft's guidance favoring body-relative HUDs and
rotation thresholds over rigid head attachment, with restrained follow movement.
See [comfort / HUDs](https://learn.microsoft.com/en-us/windows/mixed-reality/design/comfort#heads-up-displays)
and [tag-along guidance](https://learn.microsoft.com/en-us/windows/mixed-reality/design/billboarding-and-tag-along).

HUD following alone does not establish room-scale gameplay. The current camera
tracks translation relative to a seated pawn and uses collision fade; physical
walking does not move the gameplay collision body through the level. A separate
room-scale phase must reconcile physical walking with pawn collision, stairs,
doors, crouching, save/load, motion-weapon alignment and turning around the tracked
head rather than orbiting a displaced pawn origin. Preserve the seated path until
these cases are established. No teleportation or movement redesign is included
in this change.

## Recenter height

Previously, explicit recenter replaced all three components of the world position
reference. Standing after seated initialization and recentering erased the gained
head height, lowering the viewpoint back toward the seated pawn eye level.
Recenter now refreshes horizontal position and heading while preserving the
vertical reference established at initial tracking for the running session.
Repeated standing, sitting and crouching recenter operations retain their tracked
height without accumulating an offset. Eyes, head and controllers share this
reference. The separate HUD anchor still recenters at current eye height.
This is not floor calibration; restarting the XR session establishes a new reference.

## Implemented turning controls

Preferences > VR offers:

| Turning mode | Behavior |
| --- | --- |
| Smooth (Default) | Existing continuous right-stick turning, unchanged |
| Instant Snap | One immediate turn through the chosen angle |
| Smooth Snap | The same angle eased over 150 ms |

**Snap Angle** is a slider with 15/30/45/60/75/90-degree choices; default/reset is
30 degrees. It is disabled in Smooth mode. Both settings apply immediately and
persist in `[D3D12Drv.D3D12RenderDevice]` as `VRTurnMode=0/1/2` and
`VRSnapAngle=30`. Smooth Snap is a preference, not a comfort guarantee.

Touch and Xbox share the existing merged right-stick path. Snap triggers at 70%
normalized horizontal deflection and requires return below 25% before another
turn. A held stick does not repeat. Animation accumulates integer yaw increments
to the exact selected angle independent of frame rate. Only plain `JoyU=Axis
aTurn ...` bindings participate; custom aliases/compound bindings keep their
original semantics. Axis direction inversion is retained; ordinary stick
sensitivity still controls Smooth, while snap magnitude uses the angle slider.

Menus, typing, pause, death, alternate cameras, inactive/unfocused tracking,
input reset/disconnection, recenter and mode/angle changes cancel pending snap
motion and require neutral before another snap. Default Smooth and desktop keep
the original axis events. Head tracking, aiming modes, walking/swimming/flying,
other mappings, horizon lock and the HUD anchor are unchanged.

Meta's [locomotion input guidance](https://developers.meta.com/horizon/design/locomotion-input-maps/)
also places view turning on the right stick; our existing mapping is retained.

## Validation

The owner accepted turning behavior as perfect at `f995a53`, requesting only
the final display names Instant Snap and Smooth Snap. The rename does not change
turning behavior. The checks below remain for future regressions and other hardware.

Native `vr-turning` tests cover neutral arming, threshold/hysteresis, no held-stick
repeat, direction, exact animated angles at 30/72/90/144/1000 updates per second,
interruption, long input gaps, invalid input and Smooth bypass. Production menu
tests cover defaults, live selection, reload, slider reset and no desktop yaw
change. These checks do not establish headset comfort or physical input behavior.

In CV1 with Touch and Xbox, compare Smooth to the accepted baseline; try both
snap modes in both directions at 30 and 90 degrees, hold the stick, return neutral,
and turn again. Open/close menus or recenter during Smooth Snap, remount, and
disconnect/reconnect with a held stick. Confirm no leftover turn, unchanged
natural pitch/roll, stable HUD, firing alignment and persistent preferences.
The owner accepted automatic HUD recovery and recenter height at `b69ae2c`, saying
the result looks awesome. This is overall visual acceptance, not a report that
every regression scenario below was individually exercised. For future changes, test small
seated motion, sustained standing/stepping/turning, menu recovery and frozen menu
interaction. Recenter seated, stand and recenter, then sit and recenter repeatedly:
the world viewpoint must retain physical height changes without drops or drift.

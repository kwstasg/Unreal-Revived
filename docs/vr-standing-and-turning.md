# Standing HUD strategy and turning choices

## Preserve the accepted seated baseline

CV1 world/HUD horizon lock and vignette were accepted at `232f768`. Seated/fixed
HUD remains the default. The standing HUD behavior below is a proposal, not an
implemented or hardware-validated room-scale mode. Turning choices are implemented
separately and do not move the HUD anchor or change headset pitch/roll tracking.

## Proposed standing HUD

Offer an optional **Standing / Follow HUD** setting alongside **Seated / Fixed**.
Keep one shared panel, the accepted symmetric canvas projection, upright heading,
distance/scale controls and weapon/UI composition. Modify only the panel anchor.

- Follow physical head-center translation so stepping sideways, standing up or
  crouching does not leave the panel at the original seat. Preserve physical
  distance and size; filter small positional jitter without spring overshoot.
- Keep yaw stable during small glances. After a sustained horizontal turn outside
  a dead zone, ease the panel back into view. Never capture pitch or roll. CV1
  has no torso tracker, so this approximates body-relative UI with horizontal
  headset heading and hysteresis, rather than claiming measured body orientation.
- Initial tuning proposal: begin yaw catch-up after exceeding 35 degrees for
  0.3 seconds, finish within 15 degrees of forward, and limit angular speed.
  These numbers need CV1 testing and are not platform requirements.
- In standing mode only, explicitly opening the menu can summon the panel once
  in front of the player, then freeze it during interaction. Nested dialogs,
  dropdowns and slider adjustments must not recapture or move it. Recenter stays
  available to bring it back after walking away. Seated menu transitions remain
  exactly as accepted. Follow resumes after closing the menu.
- Freeze on invalid tracking, reset follow timing on recenter or tracking return,
  and retain horizontal heading near vertical gaze. Do not alter the world
  reference to move the HUD.

This recommendation adapts Microsoft's guidance favoring body-relative HUDs and
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
in this turning change.

## Implemented turning controls

Preferences > VR offers:

| Turning mode | Behavior |
| --- | --- |
| Smooth (Default) | Existing continuous right-stick turning, unchanged |
| Instant Snap | One immediate turn through the chosen angle |
| Animated Snap | The same angle eased over 150 ms |

**Snap Angle** is a slider with 15/30/45/60/75/90-degree choices; default/reset is
30 degrees. It is disabled in Smooth mode. Both settings apply immediately and
persist in `[D3D12Drv.D3D12RenderDevice]` as `VRTurnMode=0/1/2` and
`VRSnapAngle=30`. Animated snap is a preference, not a comfort guarantee.

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

Native `vr-turning` tests cover neutral arming, threshold/hysteresis, no held-stick
repeat, direction, exact animated angles at 30/72/90/144/1000 updates per second,
interruption, long input gaps, invalid input and Smooth bypass. Production menu
tests cover defaults, live selection, reload, slider reset and no desktop yaw
change. These checks do not establish headset comfort or physical input behavior.

In CV1 with Touch and Xbox, compare Smooth to the accepted baseline; try both
snap modes in both directions at 30 and 90 degrees, hold the stick, return neutral,
and turn again. Open/close menus or recenter during animated snap, remount, and
disconnect/reconnect with a held stick. Confirm no leftover turn, unchanged
natural pitch/roll, stable HUD, firing alignment and persistent preferences.
Standing HUD implementation and its physical walk/turn/menu checks remain future
work after agreement on the strategy.

# Unreal Revived 0.9.0

**Stay immersed. Turn your way. Make the view your own.**

*Upcoming release — installer build and final installation checks pending.*

Return to Unreal and Na Pali with a VR experience that adapts to how you play.
Keep your HUD nearby, choose your turning style and adjust visual quality on the
spot—all while retaining the desktop game and your familiar controls.

## Highlights

- **A HUD that keeps up.** Stable during small seated movements, with gentle
  automatic recovery when you stand, step or turn farther away. No mode selection
  needed. Menus stay stationary while you interact.
- **A level horizon.** Recenter while looking up, down or sideways without storing
  head tilt in the world or HUD. Natural headset orientation remains tracked.
- **Keep your standing height.** Recenter after standing without dropping your
  viewpoint back toward the ground during the same VR session.
- **Turn your way.** Smooth, Instant Snap or Smooth Snap, with snap angles from
  15° to 90°. Smooth remains default; snap starts at 30°.
- **Tune quality live.** Switch between 75%, 100%, 125% and 150% of the runtime's
  recommended per-eye dimensions without restarting. Balanced 100% is default.
- **A more coherent VR vignette.** Shared head-relative fading across both eyes,
  stronger visible coverage and one simple slider. Desktop appearance is preserved.
- **Look where you swim and fly.** Gaze-directed vertical movement complements
  the existing horizontal movement on foot.
- **Smoother menu navigation.** More consistent controller Back behavior and
  improved music-player navigation and playback controls.
- **Useful visual feedback.** VR-aware F11 statistics, clearer desktop resolution
  labels and corrected VR bloom behavior.
- **Prepared for more hardware.** Expanded OpenXR controller profiles and per-eye
  runtime sizing, with community hardware validation still needed.

Read [everything new since 0.8.0](../CHANGELOG.md) for the full changelog.

## Installing and updating

The planned installer is **UnrealRevived-Setup-0.9.0.exe**. It requires an original
Unreal Gold installation and creates a separate Unreal Revived installation.
Use **Unreal Revived** for desktop or **Unreal Revived VR** for VR.

When updating through uninstall/reinstall, retain saves when prompted. Settings
start fresh; uninstall backs up settings and weapon calibration to a timestamped
**Unreal Revived Backup** folder in Documents. Reapply your preferences or restore
chosen profile files yourself. Existing weapon calibration encountered during
deployment is preserved; fresh installs receive the accepted defaults.

## Tested boundary

The current owner-tested VR baseline is **Oculus Rift CV1 with Touch and Xbox**.
Other headsets are not universally certified. Automatic HUD follow and standing
height preservation do not add full room-scale player-body movement/collision.
Remote-client VR firing and some custom weapons remain unsupported. The
intermittent motion-save/load-to-gaze offset report is currently not reproducing;
this release does not claim a confirmed fix or include the rejected sizing change.

Source cleanup has passed native, menu, gameplay, save/load and desktop-renderer
checks, and the owner confirmed the in-game result. Those checks do not replace
the pending 0.9.0 installer lifecycle. No 0.9.0 download, checksum or publication
is claimed yet.

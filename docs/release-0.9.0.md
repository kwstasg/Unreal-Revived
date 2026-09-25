# Unreal Revived 0.9.0

*Release candidate: installer lifecycle passed; final owner check pending.*

Version 0.9.0 includes VR HUD positioning, recentering and turning improvements,
runtime render-quality settings, and controller and menu fixes. Existing desktop
play and controller mappings are retained.

## Highlights

- **Automatic HUD repositioning.** Stable during small seated movements, with gentle
  automatic recovery when you stand, step or turn farther away. No mode selection
  needed. Menus stay stationary while you interact.
- **World and HUD horizon lock.** Recenter while looking up, down or sideways without storing
  head tilt in the world or HUD. Natural headset orientation remains tracked.
- **Recenter height preservation.** Recenter after standing without dropping your
  viewpoint back toward the ground during the same VR session.
- **VR turning modes.** Smooth, Instant Snap or Smooth Snap, with snap angles from
  15° to 90°. Smooth remains default; snap starts at 30°.
- **VR render-quality presets.** Switch between 75%, 100%, 125% and 150% of the runtime's
  recommended per-eye dimensions without restarting. Balanced 100% is default.
- **Stereo VR vignette.** Shared head-relative fading across both eyes,
  stronger visible coverage and a single slider. Desktop appearance is preserved.
- **Gaze-directed swimming and flying.** Gaze-directed vertical movement complements
  the existing horizontal movement on foot.
- **Controller and music-menu navigation.** More consistent controller Back behavior and
  improved music-player navigation and playback controls.
- **Rendering statistics and display fixes.** VR-aware F11 statistics, clearer desktop resolution
  labels and corrected VR bloom behavior.
- **OpenXR hardware compatibility.** Additional controller profiles and runtime-driven
  per-eye sizing, with community hardware validation still needed.

Read [changes since 0.8.0](../CHANGELOG.md) for the full changelog.

## Installing and updating

The installer is **UnrealRevived-Setup-0.9.0.exe**. It requires an original
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
checks, and the owner confirmed the in-game result. The isolated 0.9.0 installer
lifecycle also passed fresh settings, save retention,
production fixture exclusion and desktop/OpenXR startup. Installed-build headset
visual acceptance remains pending. See the [local validation record](release-0.9.0-validation.md).
No public 0.9.0 release is claimed yet.

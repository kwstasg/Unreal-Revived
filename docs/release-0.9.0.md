# Unreal Revived 0.9.0

Released 25 September 2026. [Download installer and checksum](https://github.com/kwstasg/Unreal-Revived/releases/tag/UnrealRevived-Setup-0.9.0).

Version 0.9.0 extends seated VR with standing play, automatic HUD positioning,
recentering and turning improvements,
runtime render-quality settings, and controller and menu fixes. Existing desktop
play and controller mappings are retained.

## Highlights

- **Seated and standing VR support.** Stand, step or turn physically while the HUD
  automatically follows larger movements. Recenter preserves changes in head
  height during the session. No seated/standing mode switch is required.
- **VR turning modes.** Smooth, Instant Snap or Smooth Snap, with snap angles from
  15° to 90°. Smooth remains default; snap starts at 30°.
- **Automatic HUD repositioning.** Stable during small seated movements, with gentle
  automatic recovery when you stand, step or turn farther away. No mode selection
  needed. Menus stay stationary while you interact.
- **World and HUD horizon lock.** Recenter while looking up, down or sideways without storing
  head tilt in the world or HUD. Natural headset orientation remains tracked.
- **Accidental mouse movement fix in VR.** Mouse movement no longer adds unwanted
  camera pitch during normal first-person VR play. Head tracking and yaw turning
  remain available.
- **VR render-quality presets.** Switch between 75%, 100%, 125% and 150% of the runtime's
  recommended per-eye dimensions without restarting. Balanced 100% is default.
- **Gaze-directed swimming and flying.** Gaze-directed vertical movement complements
  the existing horizontal movement on foot.
- **Stereo VR vignette.** Shared head-relative fading across both eyes,
  stronger visible coverage and a single slider. Desktop appearance is preserved.
- **OpenXR hardware compatibility.** Additional controller profiles and runtime-driven
  per-eye sizing.
- **Controller and music-menu navigation.** More consistent controller Back behavior and
  improved music-player navigation and playback controls.
- **Rendering statistics and display labels.** VR-aware F11 statistics and clearer
  desktop resolution labels.
- **VR bloom correction.** Corrected bloom behavior in VR.

Read [full changelog](../CHANGELOG.md).

## Installing and updating

The installer is **UnrealRevived-Setup-0.9.0.exe**. It requires an original
Unreal Gold installation and creates a separate Unreal Revived installation.
Use **Unreal Revived** for desktop or **Unreal Revived VR** for VR.

When updating through uninstall/reinstall, retain saves when prompted. Settings
start fresh; uninstall backs up settings and weapon calibration to a timestamped
**Unreal Revived Backup** folder in Documents. Reapply your preferences or restore
chosen profile files yourself. Existing weapon calibration encountered during
deployment is preserved; fresh installs receive the accepted defaults.

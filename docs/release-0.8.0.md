# Unreal Revived 0.8.0

## Motion aiming and a better weapon fit

Version 0.8.0 builds on 0.7.0 with Oculus Touch aiming, calibrated VR
weapons, optional per-weapon adjustments, easier key bindings and brightness
fixes. The owner tested, accepted and approved this build for release on
September 21, 2026.

## What's new since 0.7.0

- **Oculus Touch aiming:** select Head gaze or Motion controllers in Preferences
  > VR > Aiming Method. Touch buttons and sticks work in either aiming mode.
- **Fourteen calibrated weapons:** original-game and Return to Na Pali weapons
  share physical sizing across modes, with separately tuned positions and more
  accurate muzzle/shot alignment, including special primary and alternate fire.
- **Handedness and HUD fixes:** corrected left/center gaze placement, animated
  RazorJack alternate-fire alignment, and weapon coverage over the VR HUD.
- **Simpler bindings:** up to three inputs per action, oldest-input replacement
  when full, persistent order and consistent clear/cancel controls.
- **Updated defaults:** Q/E/F select and use inventory; Home opens the command
  line and Page Up opens team chat. Existing saved bindings are preserved.
- **Brightness fixes:** settings remain correctly displayed across menu and
  display changes, with five-point keyboard/controller steps.
- **Release cleanup:** fixed VR-hook shutdown ownership and excluded developer
  test fixtures from the production menu package.

See the [full changelog](https://github.com/kwstasg/Unreal-Revived/blob/UnrealRevived-Setup-0.8.0/CHANGELOG.md) for details.

## Optional weapon configuration

No configuration is required. The installer includes all 14 calibrated profiles
in `System64/ModernVRWeapons.ini` inside your Unreal Revived installation
(normally `C:\Games\Unreal Revived`).

To customize a weapon, edit its existing `Profiles=` line:

| Value | What it changes |
| --- | --- |
| `Scale` | Weapon size in both aiming modes; `1.2` means 120% of the physical baseline. |
| `GazeOffsetCM` | Position while aiming with your head. |
| `MotionOffsetCM` | Position relative to the aiming controller. |

Offsets are centimetres: X is forward, Y is right and Z is up. Gaze Y is
mirrored for left-handed placement and ignored for center; motion offsets are
not automatically mirrored. Save your edit and enter `ReloadVRWeapons` in the
game console. Both modes update without restarting or reloading the map.
This command does not write to the file. More detail: [weapon tuning](https://github.com/kwstasg/Unreal-Revived/blob/UnrealRevived-Setup-0.8.0/docs/vr-weapon-tuning.md).

## Installation and existing settings

Run **UnrealRevived-Setup-0.8.0.exe** and select your original Unreal Gold
installation. Setup creates a separate Unreal Revived installation and needs
your original game files. Launch **Unreal Revived** for desktop or
**Unreal Revived VR** for VR.

For an existing installation, Setup uses the supported uninstall/reinstall
flow. Retain your saves when prompted. Uninstall backs up settings, including
weapon calibration, to a timestamped **Unreal Revived Backup** folder in
Documents. Reinstall does **not** automatically restore those settings: restore
your chosen profile files from that folder after installation if you want to
keep them. When installation encounters an existing weapon configuration, it
leaves it untouched; fresh installations receive the supplied defaults.

## Known limits

- Desktop focus loss/return can cause recurring VR stutter. This is deferred,
  not fixed by 0.8.0.
- Oculus Rift CV1 with Touch is the validated VR setup. Other headsets and
  controller profiles are not certified by this release.
- Equivalent tracked-muzzle firing on remote multiplayer clients is unsupported.
- Custom weapon renderers/firing paths may need dedicated compatibility work.
- The installer is unsigned; Windows may display a security warning.

The previous cleanup candidate passed isolated installation, desktop/VR
launch/restart, settings/calibration preservation and retained-save reinstall.
For this 0.8.0 rebuild, version metadata, payload hashes, inclusion of optional
weapon tuning and exclusion of test fixtures were checked. All 30 development
profile/save hashes remained unchanged. The full installer lifecycle was not
repeated after the version, configuration-comment and welcome-screen changes;
the owner subsequently tested this candidate and reported that everything is
in order on September 21, 2026. This records owner acceptance, not a new
automated test matrix or an expansion of the supported hardware boundary.
The corrected welcome layout was visually checked in an isolated validation
window: the heading and complete approved text are visible without clipping.

## Download identity

- File: `UnrealRevived-Setup-0.8.0.exe`
- Size: 89,756,358 bytes
- SHA-256: `5A00521B1F84CA25A423DD3109153C21D3BF3218A3DB02BC659764933CAEBD58`
- Built and accepted on September 21, 2026; distributed without rebuilding
  after owner acceptance.
- The payload manifest records base revision `988eb80` and uncommitted source
  changes (`sourceDirty=true`) at build time. The corresponding source is
  preserved by tag `UnrealRevived-Setup-0.8.0`; the original embedded build
  record is retained so the download remains the exact tested artifact.
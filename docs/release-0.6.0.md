# Unreal Revived 0.6.0

Experience Unreal Gold in seated VR with OpenXR, alongside the native DirectX 12
desktop experience. This release freezes the feature set accepted by the project
owner on Oculus Rift CV1; new features are deferred to the next release.

## Highlights

- Stereo rendering and head tracking, with gaze-aligned gamepad walking and
  strafing and smooth right-stick turning.
- Complete HUD and menus on one stable spatial panel. Opening or closing menus
  keeps its position and size; distance and scale can be adjusted independently.
- Recenter from VR Preferences, right-stick click or F10. Recenter aligns the
  view and keeps the shared UI panel upright; shortcuts can be changed in Bindings.
- Corrected VR UI color presentation and a proportionally drawn transparent
  Unreal Revived logo in the flyby.
- Separate normal and VR launch shortcuts, with independent desktop shortcut
  checkboxes. Preferences Restart preserves the selected launch mode.
- Native branded desktop and VR executables select their own modes and engine
  profiles without shortcut arguments. VR defaults to a 1280x1024 window;
  subsequent desktop and VR display changes persist independently.
- VR-only UI textures are allocated only when needed by VR rendering.

## Installation

Run `UnrealRevived-Setup-0.6.0.exe` and select your original Unreal Gold
installation. Setup creates a separate Unreal Revived installation. Launch
**Unreal Revived** for desktop play or **Unreal Revived VR** with a configured
OpenXR runtime and connected headset. Original game assets are not included.

## Validation boundary

The project owner accepted the current feature set in headset and desktop use.
Rift CV1 is the validated headset. Other runtimes/headsets, VR multiplayer,
swimming/flying semantics and extended gameplay coverage remain follow-up work.
Head-collision fade and selectable desktop mirror modes are not included.
The automated suite checks desktop and startup/fallback paths; it does not
replace headset acceptance or interactive install/uninstall validation.

## Publishing

The current installer is a **tested release candidate**, available under
`local/package/offline-installer/output/` with its SHA-256 sidecar. Local native
startup/restart and isolated fresh install/uninstall/reinstall checks passed.
Uninstall behavior is unchanged: settings are backed up to Documents and saves
can be retained. Detailed evidence is in [`branded-launchers.md`](branded-launchers.md).

Release builds must come from committed source, with the same revision in the
payload manifest and release record. The earlier September 11 candidate is
retained under `local/backups/release-0.6.0-user-tested-20260912/`; the owner
confirmed that its installed game works in desktop and VR on September 12.
Before public release sign-off, validate installation on a clean supported PC.
The installer is unsigned; signing is a separate distribution decision.
No clean-PC or signing success is implied by the local tests.

Prepared for manual upload by the project owner. No release is published by the
preparation task. Upload the generated setup executable and its SHA-256 sidecar;
the package manifest records the source commit and hashes of bundled components.
The output directory's `release-manifest.json` records the final installer hash,
source revision, validation evidence and remaining validation limits.

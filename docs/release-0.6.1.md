# Unreal Revived 0.6.1

This hotfix builds on Unreal Revived 0.6.0 and fixes the VR HUD in Return to Na
Pali while retaining the complete seated OpenXR and native DirectX 12 desktop
experience from that release.

## Hotfix changes

- Fixed Return to Na Pali so its expansion HUD, status graphics, messages,
  menus, scoreboard and crosshair use the stable spatial VR panel.
- Preserved active Return to Na Pali HUD state when upgrading a running game or
  loading an older save that selected the stock expansion HUD.
- Added the Unreal Revived feature infographic to the project overview.

## Highlights carried forward from 0.6.0

- Stereo rendering and head tracking, with gaze-aligned gamepad walking and
  strafing and smooth right-stick turning.
- Complete HUD and menus on one stable spatial panel. Opening or closing menus
  keeps its position and size; distance and scale can be adjusted independently.
- Recenter from VR Preferences, right-stick click or F10. Recenter aligns the
  view and keeps the shared UI panel upright; shortcuts can be changed in
  Bindings.
- Corrected VR UI color presentation and a proportionally drawn transparent
  Unreal Revived logo in the flyby.
- Native branded desktop and VR executables select their own modes and settings
  profiles. Preferences Restart preserves the selected executable and mode.
- Separate normal and VR shortcut choices, with VR defaulting to a 1280x1024
  window and later display changes persisting independently.
- VR-only UI textures are allocated only when needed by VR rendering.

## Installation

Run `UnrealRevived-Setup-0.6.1.exe` and select your original Unreal Gold
installation. Setup creates a separate Unreal Revived installation. Launch
**Unreal Revived** for desktop play or **Unreal Revived VR** with a configured
OpenXR runtime and connected headset. Original game assets are not included.

## Validation boundary

Rift CV1 remains the validated headset. The automated suite covers desktop and
startup/fallback paths but does not replace interactive headset or clean-PC
acceptance. Other runtimes and headsets, VR multiplayer, swimming and flying
semantics, and extended gameplay coverage remain follow-up work. The installer
is unsigned.

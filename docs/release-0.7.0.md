# Unreal Revived 0.7.0

## A better fit for seated VR

Version 0.7.0 gives you more control over your height and your sense of scale
inside Unreal, adds protection when you lean into solid scenery, and fixes the
build and installation path for bundled mutators.

### Adjust your height without leaving your chair

Open **Preferences > VR > Height Offset** to raise or lower your viewpoint.
It helps you find a comfortable standing viewpoint while playing seated.
The range is **-0.75 to +1.50 meters**; **0.00 m** keeps the original height.

### Make maps feel larger or smaller

Use **Preferences > VR > World Size** when the environment feels too cramped
or too large. Higher values make you feel smaller in a larger world; lower
values make you feel bigger in a smaller world.

Try **150%** for a map that feels small, or **75%** for one that feels too big.
The full range is **40-250%**, with **100%** as the original scale. Your
viewpoint height, depth perception and displayed weapon size adjust together.
Height Offset lets you fine-tune your viewpoint afterward.

Both sliders apply immediately, remember your choices and offer reset buttons.

### Lean into a wall without seeing through it

Your view now gradually fades to black as your head approaches or enters solid
scenery, then returns when you move clear. Head tracking continues, and the
HUD/menu remains visible so you can recover or change your settings.
Water and non-solid areas that activate game events do not trigger the fade.

### Bundled mutators now install and activate correctly

Bundled mutators are now built, installed and registered so they appear in the
**New Game** mutator list and can join the game when selected. **Old Weapons**
is included as the first bundled mutator and was used to verify the full path
from installation to activation. Games started with **Use Mutators** disabled
continue to use the normal game rules.

### Reduce the cost of character shadows

The **Realtime Ultra Res** pawn-shadow setting has been removed because it
caused frame drops and frame-time spikes. Opening Video preferences changes an
existing Ultra selection to **Realtime High Res**, retaining detailed character
shadows without the unstable Ultra setting.

## Installation

Run **UnrealRevived-Setup-0.7.0.exe** and select your original Unreal Gold
installation. Setup creates a separate Unreal Revived installation; you still
need the original game files.

Use **Unreal Revived** for desktop play or **Unreal Revived VR** for a headset.
Each mode remembers its own display settings. VR requires a configured OpenXR
runtime and a connected headset.

For an existing installation, use the supported uninstall/reinstall flow.
Choose to retain your saves; the uninstaller also backs up your settings.

## Tested and still to come

The VR controls and collision fade have been tested by the project owner,
including walls, corners, low ceilings, a door, different sizes, water and an
elevator. Rift CV1 remains the validated headset.

Other headsets, VR multiplayer, dedicated swimming/flying controls and broader
custom-map coverage remain follow-up work. The installer is unsigned.

[Full changelog](../CHANGELOG.md)

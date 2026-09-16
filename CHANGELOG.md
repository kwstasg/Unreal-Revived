# Changelog

## 0.7.0 - 2026-09-16

This update gives you more control over how Unreal feels in seated VR, adds
protection when you lean into walls, and brings back an option for classic
weapon sounds.

### Find a comfortable height while seated

The new **Height Offset** slider in **Preferences > VR** lets you raise or
lower your viewpoint without leaving your chair. Use it to find a comfortable
standing viewpoint while playing seated.

Adjust from **-0.75 to +1.50 meters**. **0.00 m** keeps the original height.

### Make the world feel the right size

Does a room feel too cramped, or does a map feel enormous? The new
**World Size** slider in **Preferences > VR** lets you adjust your sense of
scale from **40% to 250%**.

- **Above 100%:** you feel smaller, so the world feels larger. Try **150%**
  when a map feels too small.
- **Below 100%:** you feel bigger, so the world feels smaller. Try **75%**
  when a map feels too large.
- **100%:** keeps the original scale.

Your viewpoint height, sense of depth and displayed weapon size change together
to support that feeling. Use Height Offset afterward to fine-tune your view.
Both sliders update immediately, remember your settings and have reset buttons
so you can easily return to the defaults.

### More comfortable encounters with walls and ceilings

Leaning into a solid wall or low ceiling now gradually fades the world to
black. Move your head back into clear space and the view returns. This helps
avoid seeing through walls or looking at broken scenery from inside an object.

Head tracking continues throughout, and the HUD and menus remain visible so
you can adjust your settings if needed. Water and invisible areas that activate
game events do not count as solid obstacles.

### Bring back classic Unreal weapon sounds

The **Old Weapons** mutator is now included with the installation. Enable it
in the mutator selection to replace newer weapon sounds with those from
**Unreal version 200**, for a more nostalgic sound to your game.

### A lighter pawn-shadow option

Removed **Realtime Ultra Res** from the pawn-shadow choices to avoid its high
rendering cost. If you previously selected it, opening Video preferences moves
you to **Realtime High Res**. This keeps detailed shadows while reducing the
shadow resolution used for characters and creatures.

[Installation and compatibility notes](docs/release-0.7.0.md)

## 0.6.1

- Fixed the Return to Na Pali VR HUD so health, messages and other HUD elements
  appear on the same stable panel as the menus, including when loading older saves.
- Added a feature overview image to the project page.

[0.6.1 release notes](docs/release-0.6.1.md)

## 0.6.0

- Play Unreal Gold in seated VR with stereo depth and head tracking.
- Walk in the direction you are looking, turn with the gamepad, and recenter
  your view with a button press.
- Use the HUD and menus on a stable panel with adjustable distance and size.
- Launch desktop and VR modes from separate shortcuts, each remembering its
  own display settings.

[0.6.0 release notes](docs/release-0.6.0.md)

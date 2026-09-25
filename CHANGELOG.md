# Changelog

## 0.9.0 — Unreleased

**Stay immersed. Turn your way. Make the view your own.**

Unreal Revived 0.9.0 brings a more adaptable VR experience to the original Unreal
and Return to Na Pali: a HUD that stays within reach, three ways to turn, instant
render-quality changes, and a level horizon when you recenter. Desktop play
remains available through its own shortcut, with no headset required.

### Your HUD keeps up with you

Stay seated, stand up or shift your position—the shared HUD and menu panel now
adapts automatically. Small seated movements keep it stable; sustained larger
movements and turns gently bring it back into view. **No seated/standing setting
to choose.** Open a menu you've moved away from and it returns within reach,
then stays still while you navigate or adjust sliders. Your distance and size
controls keep working as before.

### Recenter without losing your bearings

Recenter while looking up, down or tilting your head: the world reference and HUD
remain level, while your natural head movement stays fully tracked. Standing
after seated play and recentering now preserves the height you gained instead
of lowering your viewpoint again within the same VR session. Mouse input no
longer adds unwanted software pitch in normal first-person VR; loading saves
and returning to the headset also recover unwanted software tilt.

### Three ways to turn

Choose your preferred style in **Preferences > VR**:

- **Smooth:** familiar continuous turning, still the default.
- **Instant Snap:** jump through the selected angle with one stick deflection.
- **Smooth Snap:** ease through that same angle in a short animated turn.

Snap Angle offers **15°, 30°, 45°, 60°, 75° and 90°**, with **30°** as the default.
Both snap modes require returning the stick to neutral before the next turn.
Changes apply immediately and work through the existing Touch/Xbox turning input.

### Find your balance of detail and performance—instantly

Four clear VR quality presets let you choose **Performance 75%, Balanced 100%,
Quality 125% or Ultra 150%** without restarting. Balanced is the default. Each
preset scales the per-eye resolution recommended by your OpenXR runtime;
desktop resolution and the HUD/menu layout remain independent.

The VR tab is simpler, with the temporary Epic, Current profile and menu-sharpness
options removed. **F11** reports VR application FPS and per-eye scene resolution
when the headset is active, with desktop statistics when it is inactive.
Desktop resolution labels now include readable aspect ratios.

### A clearer view of the action

The VR vignette now forms a shared, head-relative fade across both eyes instead
of separate eye borders. One slider adjusts darkness and coverage, with a more
visible maximum effect and a clear center. Desktop vignette appearance is preserved.
Bloom behavior in VR has also been corrected.

Swimming and flying now follow your gaze, including looking up or down, while
ordinary walking retains horizontal head-oriented movement.

### Better controller and menu flow

- More consistent **B/Back** navigation through menus, dropdowns and dialogs.
- Improved keyboard/controller navigation in the music player, including playlist
  selection, playback, Browse and empty playlists.
- Expanded OpenXR controller profiles and runtime-driven per-eye sizing lay the
  groundwork for more hardware. **Rift CV1 with Touch and Xbox remain the current
  owner-tested baseline**; other headset combinations need community testing.
- The in-game update link now opens the latest Unreal Revived release on GitHub.

### A cleaner update, with your saves retained

Installation starts with fresh settings rather than migrating retired options.
The uninstall/reinstall flow can retain your saves, and uninstall backs up
settings and weapon calibration to Documents. Reapply your preferred settings
after reinstalling; existing calibration files encountered during deployment
remain protected.

Behind the scenes, this update removes obsolete code, avoids redundant work,
and strengthens isolated regression testing. It does not claim a measured FPS
increase. Existing weapon calibration is retained; the experimental weapon-size
change was reverted and is **not** part of 0.9.0.

**Release status:** source prepared; 0.9.0 installer build and lifecycle validation
are still pending. Automatic HUD recovery does not add room-scale player-body
movement/collision. Remote-client VR firing and custom weapon compatibility remain
limited. An intermittent motion-save/load-to-gaze weapon-offset report has not
recurred in the latest owner retest and has no confirmed fix.

[0.9.0 highlights and installation notes](docs/release-0.9.0.md)

## 0.8.0 - 2026-09-21

Changes since 0.7.0. Tested, accepted and approved for release by the owner on
September 21, 2026.

### Aim with Oculus Touch

Choose **Head gaze** or **Motion controllers** in **Preferences > VR > Aiming
Method**. Aim and position your weapon with a Touch controller, or keep the
familiar head-gaze mode. Touch buttons and sticks work in either mode using
your existing controller bindings. Head gaze remains the default.

### Weapons that fit both aiming modes

Fourteen weapon profiles cover the original game and Return to Na Pali. Weapons
keep consistent physical sizes between gaze and motion aiming, with separately
tuned positions. Shots, muzzle effects and aiming now follow the calibrated
barrel more accurately, including alternate and charged fire.

Left- and center-handed gaze placement has been corrected, including Eightball
and Rocket Launcher. RazorJack follows its rotating alternate-fire muzzle, and
solid weapon surfaces correctly cover the HUD behind them.

### Optional weapon tuning

The included `System64/ModernVRWeapons.ini` is ready to use without editing.
For a personal fit, change a weapon's shared `Scale`, its `GazeOffsetCM`, or its
`MotionOffsetCM`. Save and enter `ReloadVRWeapons` in the game console to apply
the changes immediately. Existing custom calibration is not overwritten when
installation applies files over it.

### Easier controls and steadier brightness settings

- Assign up to three inputs per action. Adding another replaces the oldest,
  with the displayed order remembered across restarts. Clearing and canceling
  bindings are more consistent across mouse, keyboard and controller.
- Fresh/reset controls use **Q/E/F** for previous item, next item and use item.
  **Home** opens the command line and **Page Up** opens team chat; Tab and R are
  no longer assigned to text entry by default. Existing saved bindings stay yours.
- Brightness retains its correct percentage when reopening Video preferences
  or changing display settings. Keyboard/controller adjustments use useful
  five-percentage-point steps; mouse adjustment remains precise.

### Reliability and known limits

Fixed VR hook ownership during shutdown, with map travel, save/load and weapon
firing regression checks passing. The production menu no longer includes
developer test fixtures. These changes do not claim an FPS increase.

**Known issue:** losing and regaining desktop focus can still cause recurring
VR stutter. Rift CV1 with Oculus Touch is the validated VR setup; remote-client
VR firing and other headset/controller combinations are not supported claims.

[Installation, optional tuning and compatibility](docs/release-0.8.0.md)

## 0.7.0 - 2026-09-16

This update gives you more control over how Unreal feels in seated VR, adds
protection when you lean into walls, and fixes how bundled mutators are built,
installed and made available in the game.

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

### Bundled mutators now work correctly

Bundled mutators are now built, installed and registered correctly, so they can
appear in the **New Game** mutator list and join the game when selected.
**Old Weapons** is included as the first bundled mutator and was used to verify
the complete path from installation to activation. Normal games remain
unchanged when **Use Mutators** is disabled.

### A lighter pawn-shadow option

Removed **Realtime Ultra Res** from the pawn-shadow choices because it caused
frame drops and frame-time spikes. If you previously selected it, opening Video
preferences moves you to **Realtime High Res**. This keeps detailed character
and creature shadows while avoiding the unstable Ultra setting.

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

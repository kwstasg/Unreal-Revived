# Game features and improvements

This guide describes the player-facing features currently implemented in the
repository source. Released binaries may lag the source tree. This guide
separates supported improvements from roadmap work and does not treat an
implemented but unvalidated path as a confirmed compatibility claim. See
[`current-state.md`](current-state.md) for the precise validation and release
boundary.

## Rendering and image quality

The source also includes the user-accepted [VR HUD/menu milestone](vr-ui-recovery-design.md):
complete desktop-like layout on a shared fixed panel, stable distance/scale
controls in VR Preferences, and explicit recenter without menu-transition jumps.
The 0.6.1 release also includes accepted head tracking, gaze-aligned gamepad
movement, quick recenter bindings, corrected VR UI colors, and a spatial VR HUD
for Return to Na Pali. Rift CV1 is the validated headset; broader
runtime/gameplay compatibility remains ongoing.

| Feature | Description |
| --- | --- |
| Native Direct3D 12 renderer | Runs Unreal Gold through `D3D12Drv.D3D12RenderDevice` without using XOpenGL as the primary rendering path. |
| Corrected visual effects | Correctly displays OldUnreal 227 HD lightmaps, high-precision RGB10A2 textures, and alpha-blended geometry without the corruption found during the renderer port. |
| Smooth Brute encounters | Uses inexpensive blob shadows instead of UE227's pathological per-object realtime shadow maps and preloads the Brute projectile effect graph before combat. |
| Multisample antialiasing | Offers Off, 2x, 4x, and 8x MSAA modes with fallback when the requested mode is unavailable. |
| World-only post-processing | Exposes bloom, chromatic aberration, vignette, animated film grain, and output-pixel CRT scanlines through Video preferences. A shared world/UI composition path keeps HUD and menu drawing untouched by these effects. |
| Live image controls | Brightness, contrast, saturation, and related Video settings update the rendered scene and persist through the normal profile. |
| Configurable VSync | Allows synchronized or uncapped presentation and reports the active state in the optional statistics overlay. |
| High-refresh gameplay | Supports high and uncapped frame rates; validated Xbox controller movement and look retain the intended 60 FPS response at about 240 FPS and above 1000 FPS. |

## Display and presentation

| Feature | Description |
| --- | --- |
| Modern resolutions and 4K rendering | Supports native and lower logical resolutions, including validated logical 2560x1440 and 3840x2160 rendering through MSAA 8x. Physical 4K output remains unvalidated on the current 1080p desktop. |
| Unified display modes | Offers Fullscreen, Borderless, and Windowed in one live selector; D3D12 Alt+Enter switches between Windowed and Borderless and updates the menu immediately. |
| Monitor-aware borderless mode | Sizes borderless presentation to the monitor containing the game window rather than assuming a single desktop. |
| Aspect-preserving letterboxing | Presents lower or differently shaped logical resolutions without stretching the rendered image. |
| Correct menu coordinates | Maps mouse coordinates through presentation scale and letterbox offsets so menus remain aligned with the pointer. |
| Configurable field of view | Installs a 90-degree gameplay default while retaining the normal configurable field-of-view path. |
| Configurable GUI scale | Retains OldUnreal GUI scaling and ships a validated 1.5x default for the refreshed menus. |

## Menus and usability

| Feature | Description |
| --- | --- |
| Refreshed menu package | Adds ModernMenu as a separate UnrealScript package without replacing the network-sensitive stock `UMenu.u` package. |
| Focused preferences | Provides dedicated Video, Input, and Bindings pages with obsolete or irrelevant legacy controls removed from the normal flow. |
| Consistent control layout | Aligns checkboxes, sliders, values, reset actions, and labels for easier scanning and adjustment. |
| Persistent FPS statistics | Adds a Video checkbox and F11 command for a compact FPS, average, low, high, resolution, and VSync overlay that persists across maps. |
| Keyboard focus visibility | Uses a solid two-pixel gold outline to show the active interactive control without outlining its label or dropdown contents. |
| Mouse-wheel navigation | Scrolls every Preferences tab without requiring the pointer to first focus a specific control. |
| Live game view behind menus | Provides a persistent, default-enabled HUD option that shows the paused game world behind the menu and previews the choice immediately. |
| HUD scaling controls | Provides Crosshair Scale and HUD Scale sliders with live values, reset controls, and validated 1.5x defaults. |
| Controller menu navigation | Supports menu toggle, directional focus, activation, return, tab switching, scrolling, combo boxes, slider reset, and binding capture. |
| Controller-aware dialogs | Supports controller traversal and activation in message boxes, New Game, Load, and Save, including wrapping and scrolling through slots. |
| Original campaign launch path | Starts the selected campaign through the stock New Game action while exposing every visible action in controller order. |

## Keyboard, mouse, and controller input

| Feature | Description |
| --- | --- |
| Broad mapped-controller support | Uses SDL3 Gamepad support to normalize Xbox, DualShock 4, DualSense, and other mapped devices into Unreal's existing controls. See the [supported controller guide](controllers.md) for device-specific status. |
| Recovery input paths | Retains dynamically loaded system XInput, WinMM fallback, and the stock WinDrv package for compatibility and recovery. |
| Automatic controller selection | Selects an available mapped controller and can resume input after a validated Xbox disconnect and reconnect. |
| USB and Bluetooth | Xbox Series and DualShock 4 v2 controllers have been manually validated over both transports without Steam Input or DS4Windows. |
| Complete standard controls | Maps sticks, D-pad, face and shoulder buttons, triggers, Share or View, Options or Menu, and stick clicks into gameplay and menus. |
| Safe disconnect handling | Releases held buttons and neutralizes all joystick axes before fallback, preventing stuck movement or fire in validated Xbox Series disconnect tests. |
| Adjustable stick dead zones | Provides independent 0-50% left- and right-stick sliders with visible percentages and 25% defaults. |
| Adjustable sensitivities | Provides independent 20-300% movement and look controls with quadratic stick response, live percentage labels, reset actions, and aligned 100% defaults. |
| Independent look inversion | Applies controller look inversion to the right stick without reversing left-stick movement or menu navigation. |
| Frame-rate-independent axes | Separates raw menu axes from elapsed-time-normalized gameplay axes for consistent control at about 240 FPS and above 1000 FPS. |
| Preserved keyboard dodge | Prevents analog movement from entering Unreal's double-tap detector while retaining keyboard double-tap dodge. |
| Three assignments per action | Allows up to three visible keyboard, mouse, or controller bindings for each action, with automatic replacement of the oldest input when full, plus clear, cancel, and reset. |
| Responsive Bindings page | Keeps the binding list responsive by updating changed rows and drawing only the visible portion of the list. |

## Game content and compatibility

| Feature | Description |
| --- | --- |
| Smoother BSP traversal | Uses a canonical 32-unit player step height and briefly narrows the local collision cylinder after a confirmed standalone world-geometry obstruction, with pawn-clearance guards that prevent collision expansion from crushing NPCs. |
| Both campaigns | Discovers and launches Unreal and Return to Na Pali through their localized campaign registrations. |
| Unified campaign branding | Shows the transparent Unreal Revived wordmark at the original campaign-preview size for both Unreal and Return to Na Pali. |
| Multiplayer support | Retains the multiplayer and server packages required by the supported 227k_15 host. |
| Dedicated server | Retains the x64 `System64/UCC.exe` dedicated-server entry point and required native and script packages. |
| Bundled languages | Retains all languages supplied by the pinned host and mirrors required localized registrations into the paths used at runtime. |
| Save-game support | Retains normal saves and protects an existing save-only installation directory during reinstall. |
| Renderer recovery | Registers Direct3D 12 for normal use while retaining standard OpenGL and XOpenGL as recovery renderers. |
| Modern audio path | Uses ALAudio with bundled OpenAL Soft as the supported audio engine instead of deprecated Galaxy or experimental SwFMOD. |
| Canonical installed startup | Launches the installed product from `System64\Unreal.exe` with standard `Unreal.ini` and `User.ini` profiles and no development arguments. |

## Installation and maintenance

| Feature | Description |
| --- | --- |
| Fully offline installer | Packages the pinned OldUnreal 227k_15 host and Unreal Revived components so installation does not require downloading the patch at install time. |
| No original game files included | Unreal Revived provides no original Unreal Gold maps, textures, music, sounds, or other game assets. Players must supply them from their own installation. |
| Side-by-side installation | Creates a separate Unreal Revived directory under `C:\Games\Unreal Revived` by default and never writes to the selected original game directory. |
| Source acquisition and selection | Uses OldUnreal's full-game installer as the primary acquisition path, detects `C:\Unreal`, retains legacy Steam detection for existing owners, and allows any valid original-game directory. |
| Filtered original-game copy | Copies required original assets while excluding historical installers, copied state, and unsupported legacy renderer and audio binaries. |
| No unnecessary elevation | Installs without requesting administrator rights when the selected destination does not require them. |
| First-run defaults | Starts with Direct3D 12, XInputWinDrv, ALAudio, ModernMenu, validated display settings, and practical keyboard, mouse, and controller bindings. |
| Existing-install handling | Opens the branded uninstall dialog when Setup finds a current Unreal Revived installation; canceling leaves the existing copy unchanged. |
| Interactive uninstall | Uses one branded confirmation before standard uninstall progress, removes only Unreal Revived, and explicitly leaves the source Unreal Gold installation and OldUnreal downloads unchanged. |
| Save preservation policy | Retains saves by default and backs up saves, desktop/VR profiles, controls and weapon calibration before removal. The isolated silent lifecycle verifies exact preservation and retained-save reinstall; it does not automate clicks in the interactive confirmation dialog. |
| Reinstall protection | Accepts a retained save-only destination and prevents original-game saves from overwriting those retained files. |
| Installed shortcuts | Creates a Start Menu shortcut and offers an optional desktop shortcut; both launch the canonical installed profile without development arguments. |
| Project credits | Displays the Unreal Revived banner above the preserved original, OldUnreal, driver, author, and project-link credits. |

## Recovery and quality assurance

| Feature | Description |
| --- | --- |
| Automated regression coverage | Exercises representative campaign maps, renderer settings, display modes, menu states, and deterministic screenshot comparisons without changing the player's normal configuration. |
| Recovery mode | Provides a recovery shortcut and localized early-startup recovery resources for restoring a usable renderer or input configuration. |
| Renderer and input fallbacks | Retains OpenGL, XOpenGL, stock WinDrv, system XInput, and WinMM paths when the primary D3D12 or SDL3 configuration needs recovery. |
| Original installation safety | Development and installation workflows copy from the original game and reject deployment into unmarked or original installations. |

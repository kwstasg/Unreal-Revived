# Configuration

## Renderer selection

Select the renderer in the active Unreal INI file:

```ini
[Engine.Engine]
GameRenderDevice=D3D12Drv.D3D12RenderDevice
```

Keep test profiles under the ignored disposable runtime, for example
`local/game/System64/D3D12Test.ini`. Do not commit personal resolution, audio,
input, or save settings.

## Launch syntax

The installed product starts from `System64\UnrealRevived.exe` for desktop or
`System64\UnrealRevivedVR.exe` for VR, without shortcut arguments. They select
`Unreal.ini` and `UnrealVR.ini` respectively and share `User.ini` and saves. Both
engine profiles select `Unreal.unr?Game=ModernMenu.ModernIntro` through `LocalMap`
and 227's `AltLocalMap`, including when Return to Na Pali is installed. See
[branded launchers](branded-launchers.md).

The verified development-runtime command line remains:

```powershell
.\Unreal.exe Unreal.unr?Game=ModernMenu.ModernIntro ini=D3D12Test.ini userini=D3D12TestUser.ini
```

The map token must precede the bare `ini=` arguments. With this 227 executable,
starting the command line with `ini=D3D12Test.ini` parses the value as a network
URL, while `-ini=` is not honored as the intended profile override. `Unreal.unr`
is the normal shell map and does not force the player into a campaign level.
The explicit game class selects the Unreal Revived intro HUD before the player
HUD is spawned, preventing frames from the original flyby HUD from appearing
first.

## Game controller input

Fresh Unreal Revived development and installed profiles select the side-by-side
Windows viewport and enable the gamepad backend:

```ini
[Engine.Engine]
ViewportManager=XInputWinDrv.WindowsClient

[XInputWinDrv.WindowsClient]
UseJoystick=True
UseXInput=True
XInputFallbackToWinMM=True
XInputControllerIndex=-1
```

The `UseXInput` and `XInputControllerIndex` names are retained for compatibility
with existing profiles. SDL3 Gamepad is now the primary backend and normalizes
Xbox, DualShock 4, DualSense, and other mapped controllers into the existing
Unreal joystick keys. Direct system XInput remains available as a fallback.

`XInputControllerIndex=-1` automatically selects the first connected SDL
gamepad and retains it until disconnect. Values `0` through `3` select a fixed
enumerated gamepad. Automatic selection checks disconnected devices at most
once per second. When the gamepad backend is disabled or has no controller,
`XInputFallbackToWinMM=True` permits the inherited Windows multimedia joystick
path. **Options > Preferences > Input > Controller Enabled** remains the master
`UseJoystick` switch. That page also configures automatic or fixed controller
selection, movement and look dead zones, movement and look sensitivity, and
vertical-look inversion. Legacy mouse and joystick calibration settings are
hidden. The Controller section appears before Mouse, and visible checkbox
controls share the same right-edge alignment as the Video page. **Bindings**
retains the engine's existing binding persistence while displaying all assigned
controller buttons alongside the stock keyboard and mouse slots. Left-click,
Enter, Space, and controller A add a binding. When three are already assigned,
the new input replaces the oldest; the row displays oldest to newest.
Right-click, Delete, and controller X clear the action immediately. There is
no separate replacement mode, and middle-click has no editing action.
Escape and controller B cancel capture without changing the action. The page's
Reset button restores Unreal Revived's shipped defaults, including crouch on
`Ctrl`, `C`, and left-stick click. See the [key binding guide](key-bindings.md)
for steps and special cases.
PlayStation Cross/Circle/Square/Triangle map to the same physical positions as
A/B/X/Y.

| Control | Unreal input | Action |
| --- | --- | --- |
| Left stick | `JoyX`, `JoyY` | Strafe and move during gameplay |
| Left stick | `JoyZ`, `JoyR` | Menu navigation only |
| Right stick | `JoyU`, `JoyV` | Turn and look |
| A | `Joy1` | Jump |
| B | `Joy2` | Unbound |
| X | `Joy3` | Activate inventory item |
| Y | `Joy4` | Next inventory item |
| LB / RB | `Joy5`, `Joy6` | Previous / next weapon |
| View | `Joy7` | Previous inventory item |
| Menu | `Joy8` | Open or close the menu |
| Left stick click | `Joy9` | Crouch |
| RT / LT | `Joy11`, `Joy12` | Fire / alternate fire |
| D-pad | `JoyPov*` | Existing direct weapon shortcuts |

While UWindow is open, the D-pad and left stick move focus, A activates the
focused control, B returns or cancels binding capture, and LB/RB switch
Preferences tabs. The Menu button opens and closes UWindow; normal standalone
pause and unpause behavior is preserved. Escape and Menu initially show the
menu shell; A or any D-pad direction opens its first pull-down. B closes an
active pull-down without leaving the shell. A opens and commits combo-box
choices, and resets a focused Video or HUD slider directly. Binding rows accept
controller focus, and A starts capture without consuming the next keyboard,
mouse, or controller input. Escape or B cancels capture. Message boxes take
exclusive controller focus: every direction cycles
their visible buttons, A selects the outlined button, and B cancels. Menu is
reserved and cannot be captured. Rumble, controller glyph
artwork, and simultaneous multi-controller gameplay are not implemented.
The shared input pipeline uses adjustable radial stick dead zones and independent digital trigger
thresholds. The Input preferences page exposes 0–50% left- and right-stick
dead-zone sliders; 0% disables the corresponding compatibility gate. Movement
sensitivity and look sensitivity each span 20–300% and independently scale a
quadratic stick response curve. Both provide finer low- and mid-stick control,
reach the established natural output at 100% and full deflection, and permit
lower or higher maximum movement and camera speeds when desired.
`DeadZoneXYZ`, `DeadZoneRUV`, `LeftStickDeadZonePercent`,
`RightStickDeadZonePercent`, `ScaleXYZ`, `ScaleRUV`, and `InvertVertical` remain
configurable in the cloned viewport section. For SDL and native XInput,
`InvertVertical` affects only right-stick look; left-stick movement direction
is unchanged. Gameplay stick axes are normalized against elapsed poll time with
the existing 60 FPS feel as their baseline, so movement and look do not scale
with frame rate. The offline installer writes these client settings and the
complete button and stick bindings into both `System` and `System64` default
profile templates as well as the dedicated Unreal Revived launch profile. Raw
Raw `JoyZ` and `JoyR` samples remain available to the
menu, while normalized gameplay movement uses the proven `JoyX` and `JoyY`
binding path. ModernConsole
suppresses UE1's double-tap dodge detector only while those stick axes are
active; keyboard double-tap dodge remains available when the stick is centered.

ModernConsole also applies a canonical player `MaxStepHeight` of 32 across map
travel and save loads. In standalone play, if walking input remains blocked for
0.08 seconds and a forward collision trace confirms world geometry, it
temporarily reduces the local player's collision radius by 8 units, with an
absolute minimum radius of 8. The assist is suppressed near every colliding
pawn, and the normal radius is restored only when the full cylinder cannot
overlap one. This lets UE1's native movement clear problematic legacy BSP seams
without manually moving the player, changing map geometry, crushing pawns,
affecting crouched or airborne movement, or operating in network play.

Fresh development and installed profiles explicitly default to automatic
controller selection, 25% left-stick and 25% right-stick dead zones, movement
and look sensitivity `100`, inverted vertical controller look, raw mouse input, mouse sensitivity
`3`, mouse smoothing disabled, non-inverted mouse look, and always-mouselook. Existing user
profiles are not migrated automatically.

Fresh disposable-runtime generation writes the same Unreal Revived menu,
renderer, display, input, network, and HUD defaults to `Default.ini` and the
shortcut's `D3D12Test.ini`. It likewise writes the same user defaults to
`DefUser.ini` and `D3D12TestUser.ini`, so rebuilding the runtime or using a
profile fallback does not restore the stock OldUnreal menu settings.

Existing profiles and their `Joy*` bindings are not migrated. Stock
`WinDrv.WindowsClient` remains available as a manual input fallback. The
development recovery shortcut generates a separate `D3D12Recovery.ini` using
`XInputWinDrv.WindowsClient` and reapplies the validated controller defaults so
gamepad navigation and the complete Input page remain available.

## FPS display

After deploying `ModernMenu`, open **Options > Preferences > Video** and use
**Show FPS Statistics** directly below **Display Mode**. The checkbox
controls Unreal Revived's compact statistics overlay and remains synchronized
when the Video page is reopened. It displays the latest one-second frame rate
as **FPS**, average frame rate as **AVG**, and the observed one-second **Low**
and **High**, all to one decimal place. Additional rows show
the current rendered **Res** and the active renderer's **VSync** state. The
process-wide console owns the counter, so it remains available across maps and
HUD classes and remains visible over open menus without enabling TimeDemo
benchmarking or flyby control. The overlay renders the large font at half the
configured HUD scale with an explicit smoothed-text polygon override and a
sixteen-pixel left inset. Menu windows and dropdowns render above the overlay,
so they occlude it normally. Overlay drawing restores UWindow's Canvas state.
Its
`bShowFPS` value is saved in the active engine profile and restores the overlay
when the game starts or restarts.

F11 toggles the statistics overlay instead of changing brightness. The shortcut
uses the same saved `bShowFPS` value as the Video Preferences checkbox, so both
controls immediately update each other and remain synchronized across restarts.
Installed and disposable runtime generation also writes this binding to
`DefUser.ini` for newly derived user profiles.

`ModernConsole` also keeps the stock Brute projectile's smoke, explosion,
child-smoke, and decal classes in the startup asset graph. These dynamically
spawned effects would otherwise first become resident during combat. Unreal
Revived also leaves actor shadows enabled but selects the engine's inexpensive
blob-shadow path. UE227's realtime silhouette path regenerates and uploads many
unique shadow maps while projectiles and decorations are active, causing the
same severe encounter stalls on D3D12, OpenGL, and XOpenGL. Projectile visuals,
sounds, dynamic lights, decals, physics, AI, damage, and spawn rates remain
unchanged.

**Display Mode** replaces the separate fullscreen and borderless checkboxes.
It offers **Fullscreen**, **Borderless**, and **Windowed** when supported, and
uses the host's live `GetScreenMode` and `SetScreenMode` commands. The selected
value refreshes while the page is visible, so Alt+Enter changes are reflected
immediately. With D3D12Drv active, Alt+Enter switches between Windowed and
Borderless, or exits Fullscreen to Windowed. Fullscreen remains available as
an explicit combo selection.

The same Video page exposes the D3D12 renderer's existing **Antialiasing** row
as **Off**, **2x**, **4x**, and **8x**. Changing it updates `AntialiasMode` and
flushes the renderer immediately. Unsupported sample counts automatically fall
back to the highest lower count supported by the scene color, hit, and depth
formats.

The inherited **Anisotropic Filtering** row is also available for D3D12 and
offers **Off**, **2x**, **4x**, **8x**, and **16x**. It updates the renderer's
scene samplers immediately and persists through `MaxAnisotropy`; Off uses
ordinary linear filtering. Profiles without an explicit value use the
renderer-registered 4x default.

**Saturation** displays a percentage instead of the renderer's stored integer:
0% is grayscale, 100% is normal color, and 200% is the maximum boosted
setting. Reset restores 100%.

The **Video Driver** list contains only the supported Direct3D 12, OpenGL, and
XOpenGL renderers. Legacy registered renderers are not selectable. If a profile
already names another active renderer, the inherited unavailable marker remains
visible without adding that renderer back to the list. Video Driver receives
initial keyboard focus when Preferences opens. Selecting a different renderer
immediately opens the existing **Save Settings and Restart...** confirmation;
accepting it saves the selected driver and relaunches with the active profile.

D3D12 **Contrast** and **Saturation** sliders appear immediately below the
built-in Brightness control. Contrast clamps its stored value to raw `64`
through `170` and displays 50% through 100% neutral to 200% maximum. Saturation
uses `128` through `383`, from 0% grayscale
through 100% normal to 200% boosted. Changes update the active renderer
immediately and persist to the active engine profile. The controls are disabled
when a different render device is selected. Brightness displays a percentage
from 50% through 200%, with the `0.5` default represented as 100%. Brightness
and Contrast move in 1% increments. Contrast is rounded to its legacy byte
renderer value when applied, while ModernMenu also saves the exact selected
percentage so values such as 115% remain unchanged after restart. If the raw
renderer value changes independently, the menu derives and saves its nearest
percentage instead. D3D12 reads Brightness every frame, so
live changes do not require flushing renderer resources. The Video sliders use
8-pixel handles for easier selection. Dragging any Video or HUD slider with the
mouse updates its displayed value and setting continuously instead of waiting
for the handle to be released. Every Video slider has a compact reset button
fitted inside its
original row width. Reset restores Brightness to `0.6`, GUI override to enabled
with Scaling at `1.5x`, Lightmap LOD to `8`, Contrast to `128`, Saturation to
`281`, and Bloom Amount to `154`, applying and saving
the result immediately. The buttons match combo-box arrow positioning and are
intentionally blank because the active skins provide no reset icon.

Color Depth and GUI Mouse Speed are not shown on the Video page. Their
underlying host settings remain untouched for configuration compatibility.

The currently keyboard-focused menu control has a solid two-pixel gold
outline around only its interactive widget: slider track, checkbox box, combo
edit area, edit field, or button. Labels remain outside the indicator, and
pulldown menus and open combo lists are not outlined. The outline is clipped to
every visible parent, so a focused control cannot draw a detached frame after
it scrolls outside the page viewport. The same treatment applies across
ModernMenu and inherited UMenu dialogs without changing mouse behavior.

The HUD page provides reset buttons for all four sliders. HUD Layout and
Crosshair Style reset to index `0`; Crosshair Scale and HUD Scale reset to the
Unreal Revived default of `1.5`, with values displayed beside their labels to
one decimal place. All sliders use 8-pixel handles. Their tracks are shortened
so each button's right edge remains aligned with the row's original endpoint,
minus the same 2-pixel right inset used by combo-box arrow buttons. Reset
buttons remain vertically centered on their slider handles. The page also exposes
**Show Game Behind Menus**,
aligned with the other checkbox controls and enabled by default. During active
gameplay, Escape and Preferences show the paused 3D world behind UWindow so
visual settings can be previewed live. It also removes the branded background
from the normal shortcut's `Unreal.unr` intro and main-menu scene, leaving that
live 3D scene visible beneath UWindow. In the disposable development runtime,
bare `System64/UnrealEd.exe` always leaves its editor viewports visible; the
gameplay checkbox does not hide editor content.

The D3D12-only **Bloom Amount** slider uses the renderer's complete byte range
from `0` to `255` and appears directly below Saturation. Its label maps that
range to 0% through 100%. Setting it to `0` disables bloom; any positive amount
enables bloom and controls blur spread, highlight extraction, and additive intensity.
The extraction threshold falls from `1.0` to `0.5`. Additive gain follows a
progressive curve, reaching about 6x at the midpoint and 16x at the maximum.
The current percentage is shown in the slider label and reloads
from the active engine profile when Video Preferences is reopened. Changes are
applied directly to the active D3D12 render device and saved to the profile, so
they are visible immediately and survive restart. Bloom uses the shared world
image captured by `D3D12 BEGINUIPASS`; the dedicated UI mask keeps subsequent
HUD, menu, and intro pixels out of world-only post-processing.

The D3D12-only **Vignette**, **Film Grain**, and **CRT Scanlines** sliders follow
Chromatic Aberration. Each uses the renderer byte range from `0` through `255`,
shown as 0% through 100%, and defaults to 0% (disabled). Vignette darkens the
world toward the screen corners, Film Grain adds animated monochrome noise, and
CRT Scanlines draw a dark output-pixel row, a softer shoulder, and two subtly
lifted phosphor rows. Changes apply live,
persist in the active profile, and use the shared world/UI composition path.

The custom Preferences **Restart** action saves the open pages and relaunches
with `Unreal.unr?Game=ModernMenu.ModernIntro ini=D3D12Test.ini
userini=D3D12TestUser.ini`. This preserves
the disposable D3D12 profile instead of falling back to `Unreal.ini`. Restart
does not reapply the Game tab's transient console-combo default. The custom
Game page locks the disabled **Console** field to **Standard Unreal Console**
(`ModernMenu.ModernConsole`) because the Browser and deprecated Gold consoles replace
the windowed UMenu interface.

Installer profiles configure the same action to relaunch with the canonical
`Unreal.ini` and `User.ini` profiles. The restart profile names are stored under
`[ModernMenu.ModernOptionsClientWindow]`, so the shared `ModernMenu.u` package
preserves the active environment instead of opening First-Time Configuration
or falling back to OldUnreal defaults. Installed profiles select
`ModernMenu.ModernIntro` through `[URL] LocalMap` and `AltLocalMap`, and omit
the nonexistent `EntryIII.unr` startup entry, avoiding its rotating failed-load
fallback.

## Renderer settings

Settings belong under:

```ini
[D3D12Drv.D3D12RenderDevice]
```

Defaults are registered by `UD3D12RenderDevice::StaticConstructor`.

| Setting | Default | Values or purpose |
| --- | ---: | --- |
| `UseVSync` | `False` | Synchronize presentation to the display. |
| `UsePrecache` | `True` | Precache renderer resources. |
| `EnableVR` | `False` | Legacy default for direct executable launches. Use normal `-novr` / VR `-vr` shortcuts; explicit switches override this setting. No startup checkbox is exposed in Preferences. |
| `VRHUDDistance` | `1.75` | Shared UI panel distance in metres, clamped to 0.50-5.00; live changes retain the captured anchor. |
| `VRHUDScale` | `1.0` | Shared UI panel physical scale, clamped to 0.50-2.00; independent of distance. |
| `AntialiasMode` | `MSAA_4x` | `Off`, `MSAA_2x`, `MSAA_4x`, or `MSAA_8x`. |
| `GammaMode` | `D3D9` | `D3D9` or `XOpenGL` response. |
| `GammaOffset` | `0.0` | Global gamma offset. |
| `GammaOffsetRed` | `0.0` | Red-channel gamma offset. |
| `GammaOffsetGreen` | `0.0` | Green-channel gamma offset. |
| `GammaOffsetBlue` | `0.0` | Blue-channel gamma offset. |
| `LinearBrightness` | `128` | Linear brightness control. |
| `Contrast` | `128` | Contrast control. |
| `Saturation` | `281` | Saturation control (120% in Video Preferences). |
| `GrayFormula` | `1` | Grayscale conversion formula. |
| `LightMode` | `Normal` | `Normal`, `OneXBlending`, or `BrighterActors`. |
| `LODBias` | `0.0` | Texture level-of-detail bias. |
| `MaxAnisotropy` | `4` | Anisotropic filtering level; `0` disables it and the Video menu offers `2`, `4`, `8`, or `16`. |
| `Hdr` | `False` | Enable HDR output where supported. |
| `HdrScale` | `128` | HDR intensity scale. |
| `Bloom` | `True` | Enable bloom; synchronized by the Bloom Amount slider. |
| `BloomAmount` | `154` | Bloom intensity from `0` through `255`; shown as 60% in Video Preferences. |
| `ChromaticAberration` | `0` | World-only chromatic aberration from `0` (off) through `255` (maximum); shown as 0–100% in Video Preferences. |
| `VignetteIntensity` | `0` | World-only vignette intensity from `0` (off) through `255` (maximum); shown as 0–100% in Video Preferences. |
| `FilmGrainAmount` | `0` | World-only animated monochrome grain from `0` (off) through `255` (maximum); shown as 0–100% in Video Preferences. |
| `ScanlineStrength` | `0` | World-only output-pixel CRT scanlines from `0` (off) through `255` (maximum); shown as 0–100% in Video Preferences. |
| `OccludeLines` | `False` | Occlude line rendering on the 227 build. |
| `GammaCorrectScreenshots` | `True` | Apply gamma correction to screenshots. |
| `UseDebugLayer` | `False` | Enable the Direct3D 12 debug layer. |

`-vr` overrides the default or stored false value and requests detection.
`-novr` overrides a stored true value and wins if both command-line
switches are present. Disabled launches never query `openxr_loader.dll`.
Requested launches create an OpenXR instance, query the active runtime and
head-mounted-display system, validate the D3D12 adapter and feature level, and
attempt to create a session. When compatible, they allocate two eye swapchains,
begin the session, locate the runtime views, and render independently culled
eye cameras with runtime pose, IPD, asymmetric FOV, and tracked head movement.
Spatial UI, recenter, head collision, gaze/motion aiming and gaze-directed
walking/swimming/flying have CV1 owner acceptance. Balanced now renders at the
runtime-recommended eye resolution, with live 75/100/125/150% presets. Other
headsets and controller profiles require hardware reports. See
[VR quality](vr-render-quality.md) and [controller compatibility](vr-controller-compatibility.md).

The 227 adapter fixes `MaxTextureSize` at 4096, disables the engine lightmap
atlas, disables masked-font requirements, and advertises the renderer as
certified. These are renderer capabilities rather than user-facing INI options
for this target.

## Resolution behavior

In borderless fullscreen, the engine keeps the selected logical resolution
while the renderer presents to the physical resolution of the monitor that
contains the game window. The renderer always offers 2560x1440 and 3840x2160
as logical modes, letterboxes or downsamples the image to the selected monitor,
and maps mouse coordinates back into logical menu space. On a physical 4K
monitor or a 4K DSR mode, presentation uses the monitor's 3840x2160 dimensions.
Do not treat `Viewport->SizeX/SizeY` and `Viewport->PhysicalSizeX/PhysicalSizeY`
as interchangeable when changing this code.

## Installer profile defaults

Menu rebuilds preserve existing graphics, VR and user video preferences; defaults
are seeded during fresh runtime creation and installer staging.

The offline installer creates desktop `Unreal.ini`, VR `UnrealVR.ini`, shared
`User.ini` and `ModernVRWeapons.ini` calibration profiles
from the pinned host defaults. It applies the following initial preferences
without changing the original game installation or preventing the player from
changing them later:

| Setting | Initial value |
| --- | ---: |
| Display mode | Fullscreen |
| Fullscreen resolution | `1920x1080` |
| Field of view | `90` |
| World texture detail | High |
| Skin detail | High |
| Brightness | `0.600000` (120%) |
| Contrast | `128` (100%) |
| Saturation | `281` (120%) |
| Anisotropic filtering | `4x` |
| Bloom | Enabled |
| Bloom amount | `154` (60%) |
| FPS statistics | Enabled |
| Minimum desired frame rate | `60.000000` |
| Lightmap LOD | `8` |
| Skybox fog detail | `FOGDETAIL_High` |
| Override automatic GUI scaling | `True` |
| GUI scaling factor | `1.500000` |
| GUI skin | Gold (`UMenuMetalLookAndFeel`) |
| Decals | Enabled |
| Dynamic lighting | Enabled |
| Specular lights | Enabled |
| Weapon flash | Enabled |
| Pawn shadows | Blob shadows |
| Decoration shadows | Enabled |
| Shadow draw distance | Ultra (`8x`) |
| Mesh flat shading | Disabled |
| Content precaching | Enabled |
| Trilinear filtering | Disabled |
| NoSmooth view filtering | Disabled |
| HD textures | Enabled |
| Antialiasing | `MSAA_4x` |
| Network speed | `50000` |
| LAN speed | `20000` |
| VSync | `False` |
| Realtime-shadow detail resolution | `256` (inactive with blob shadows) |
| HUD mode | `0` |
| Crosshair | `0` |
| HUD scale | `1.500000` |
| Crosshair scale | `1.500000` |

These are installer profile choices, not changes to the render device's
registered defaults. Existing profiles retain their saved values during normal
game use; reapplying the installer specifically migrates realtime silhouette
shadows back to blob shadows to prevent the encounter-time performance defect.
The shared profile generator writes matching 4x AA/anisotropy, disabled VSync,
enabled precaching, and disabled trilinear-filter preferences for D3D12,
OpenGL, and XOpenGL where each renderer exposes the corresponding option.

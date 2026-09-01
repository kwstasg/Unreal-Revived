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

A verified normal-start command line is:

```powershell
.\Unreal.exe Unreal.unr ini=D3D12Test.ini userini=D3D12TestUser.ini
```

The map token must precede the bare `ini=` arguments. With this 227 executable,
starting the command line with `ini=D3D12Test.ini` parses the value as a network
URL, while `-ini=` is not honored as the intended profile override. `Unreal.unr`
is the normal shell map and does not force the player into a campaign level.

## FPS display

After deploying `ModernMenu`, open **Options > Preferences > Video** and use
**Show FPS Statistics** directly below **Display Mode**. The checkbox
controls 227's built-in `TIMEDEMO` statistics overlay and remains synchronized
when the Video page is reopened. Its `bShowFPS` value is saved in the active
engine profile and restores the overlay when the game starts or restarts.

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
original row width. Reset restores Brightness to `0.5`, GUI override to enabled
with Scaling at `1.5x`, Lightmap LOD to `8`, Contrast to `128`, Saturation to
`255`, and Bloom Amount to `128`, applying and saving
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
they are visible immediately and survive restart. Bloom extraction uses the 3D
scene captured before 227 begins `RenderOverlays`, so HUD and menu pixels do
not become bloom emitters. When UWindow is active, the renderer also captures
before its first menu tile. The custom intro HUD explicitly marks its world/UI
boundary before drawing text and logos because that 227 path does not expose a
reliable native overlay transition.

The custom Preferences **Restart** action saves the open pages and relaunches
with `Unreal.unr ini=D3D12Test.ini userini=D3D12TestUser.ini`. This preserves
the disposable D3D12 profile instead of falling back to `Unreal.ini`. Restart
does not reapply the Game tab's transient console-combo default. The custom
Game page locks the disabled **Console** field to **Standard Unreal Console**
(`UMenu.UnrealConsole`) because the Browser and deprecated Gold consoles replace
the windowed UMenu interface.

Installer profiles configure the same action to relaunch with
`Unreal.unr ini=UnrealRevived.ini userini=UnrealRevivedUser.ini`. The restart
profile names are stored under `[ModernMenu.ModernOptionsClientWindow]`, so the
shared `ModernMenu.u` package preserves the active environment instead of
opening First-Time Configuration or falling back to OldUnreal defaults.

## Renderer settings

Settings belong under:

```ini
[D3D12Drv.D3D12RenderDevice]
```

Defaults are registered by `UD3D12RenderDevice::StaticConstructor`.

| Setting | Default | Values or purpose |
| --- | ---: | --- |
| `UseVSync` | `True` | Synchronize presentation to the display. |
| `UsePrecache` | `True` | Precache renderer resources. |
| `AntialiasMode` | `Off` | `Off`, `MSAA_2x`, `MSAA_4x`, or `MSAA_8x`. |
| `GammaMode` | `D3D9` | `D3D9` or `XOpenGL` response. |
| `GammaOffset` | `0.0` | Global gamma offset. |
| `GammaOffsetRed` | `0.0` | Red-channel gamma offset. |
| `GammaOffsetGreen` | `0.0` | Green-channel gamma offset. |
| `GammaOffsetBlue` | `0.0` | Blue-channel gamma offset. |
| `LinearBrightness` | `128` | Linear brightness control. |
| `Contrast` | `128` | Contrast control. |
| `Saturation` | `255` | Saturation control. |
| `GrayFormula` | `1` | Grayscale conversion formula. |
| `LightMode` | `Normal` | `Normal`, `OneXBlending`, or `BrighterActors`. |
| `LODBias` | `0.0` | Texture level-of-detail bias. |
| `Hdr` | `False` | Enable HDR output where supported. |
| `HdrScale` | `128` | HDR intensity scale. |
| `Bloom` | `False` | Enable bloom; synchronized by the Bloom Amount slider. |
| `BloomAmount` | `128` | Bloom intensity from `0` through `255`; `0` disables bloom in Video Preferences. |
| `OccludeLines` | `False` | Occlude line rendering on the 227 build. |
| `GammaCorrectScreenshots` | `True` | Apply gamma correction to screenshots. |
| `UseDebugLayer` | `False` | Enable the Direct3D 12 debug layer. |

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

The offline installer creates dedicated `UnrealRevived.ini` and
`UnrealRevivedUser.ini` profiles from the pinned host defaults. It applies the
following initial preferences without changing the original game installation
or preventing the player from changing them later:

| Setting | Initial value |
| --- | ---: |
| Fullscreen resolution | `1920x1080` |
| Brightness | `0.550000` (110%) |
| Minimum desired frame rate | `60.000000` |
| Lightmap LOD | `8` |
| Skybox fog detail | `FOGDETAIL_High` |
| Override automatic GUI scaling | `True` |
| GUI scaling factor | `1.500000` |
| Antialiasing | `MSAA_4x` |
| Bloom | `True` |
| Bloom amount | `128` |
| Network speed | `50000` |
| LAN speed | `20000` |
| VSync | `False` |
| Shadow detail resolution | `1024` |
| Shadow draw distance | Unlimited (`0.000000`) |
| HUD mode | `0` |
| Crosshair | `0` |
| HUD scale | `1.500000` |
| Crosshair scale | `1.500000` |

These are installer profile choices, not changes to the render device's
registered defaults. Existing profiles retain their saved values during normal
game use.

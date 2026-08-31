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
**Show FPS Statistics** directly below **Show Fullscreen**. The checkbox
controls 227's built-in `TIMEDEMO` statistics overlay and remains synchronized
when the Video page is reopened. Its `bShowFPS` value is saved in the active
engine profile and restores the overlay when the game starts or restarts.

The same Video page exposes the D3D12 renderer's existing **Antialiasing** row
as **Off**, **2x**, **4x**, and **8x**. Changing it updates `AntialiasMode` and
flushes the renderer immediately. Unsupported sample counts automatically fall
back to the highest lower count supported by the scene color, hit, and depth
formats.

D3D12 **Contrast** and **Saturation** sliders appear immediately below the
built-in Brightness control and use the renderer's existing `0` through `255`
config ranges. Contrast is neutral at `128`; saturation is normal at `255` and
reaches grayscale near `128`. Changes update the active renderer immediately
and persist to the active engine profile. The controls are disabled when a
different render device is selected.

The D3D12-only **Bloom Amount** slider uses the renderer's complete byte range
from `0` to `255`. Setting it to `0` disables bloom; any positive amount enables
bloom and controls blur spread, highlight extraction, and additive intensity.
The extraction threshold falls from `1.0` to `0.5`. Additive gain follows a
progressive curve, reaching about 6x at the midpoint and 16x at the maximum.
The current numeric value is shown in the slider label and reloads
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
| Brightness | `0.600000` |
| Minimum desired frame rate | `60.000000` |
| Lightmap LOD | `8` |
| Skybox fog detail | `FOGDETAIL_High` |
| Network speed | `50000` |
| LAN speed | `20000` |
| VSync | `False` |
| Shadow detail resolution | `1024` |
| HUD mode | `0` |
| Crosshair | `0` |
| HUD scale | `1.500000` |
| Crosshair scale | `1.500000` |

These are installer profile choices, not changes to the render device's
registered defaults. Existing profiles retain their saved values during normal
game use.

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
| `AntialiasMode` | `Off` | `Off`, `MSAA_2x`, or `MSAA_4x`. |
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
| `Bloom` | `False` | Enable bloom. |
| `BloomAmount` | `128` | Bloom intensity. |
| `OccludeLines` | `False` | Occlude line rendering on the 227 build. |
| `GammaCorrectScreenshots` | `True` | Apply gamma correction to screenshots. |
| `UseDebugLayer` | `False` | Enable the Direct3D 12 debug layer. |

The 227 adapter fixes `MaxTextureSize` at 4096, disables the engine lightmap
atlas, disables masked-font requirements, and advertises the renderer as
certified. These are renderer capabilities rather than user-facing INI options
for this target.

## Resolution behavior

In borderless fullscreen, the engine keeps the selected logical resolution
while the renderer presents to the physical desktop resolution. The renderer
letterboxes the image and maps mouse coordinates back into logical menu space.
Do not treat `Viewport->SizeX/SizeY` and `Viewport->PhysicalSizeX/PhysicalSizeY`
as interchangeable when changing this code.

# OldUnreal 227 renderer port

The renderer originates from the authorized UT99VulkanDrv Direct3D 12 backend
at repository `https://github.com/dpjudas/UT99VulkanDrv`, revision
`a29e9ac0df1c60ad302d91bc3a51ab026c1a307c`. This immutable identity is retained
here after the obsolete standalone provenance files were removed.

This document records the compatibility work required for the OldUnreal
227k_15 Windows x64 host. Keep host-specific behavior behind `UNREAL_227` where
practical so upstream renderer structure remains recognizable.

## Development model and source limitations

This project does not have the complete native Unreal Engine 1 or OldUnreal
engine source. The renderer is possible because Unreal loads render devices as
native plugins through the ABI published by the 227 SDK:

```text
Unreal.exe
	-> Engine.dll
	-> URenderDevice ABI
	-> D3D12Drv.dll
	-> Direct3D 12
```

The implementation is grounded in four available sources of information:

- the open-source UT99VulkanDrv Direct3D 12 renderer;
- 227 SDK headers defining engine types, virtual methods, callbacks, and texture
	structures;
- 227 x64 import libraries used to link against `Core.dll`, `Engine.dll`, and
	`Render.dll`;
- available UnrealScript sources, runtime logs, controlled probes, and visual
	testing of the disposable game installation.

This is sufficient for work contained within the render-device interface,
including texture upload, presentation, resolution handling, renderer
capabilities, and callback-based coordinate mapping. It does not permit
arbitrary or reliable modification of private native engine behavior.

When undocumented behavior matters, prefer a narrow test through a published
SDK or UnrealScript interface. The campaign metadata investigation, for
example, used a disposable UnrealScript commandlet to call the same
`IntDescIterator` API as the New Game menu. Do not infer private layouts or add
binary hooks unless the required behavior cannot be implemented through a
supported interface and the exact host version has been independently
verified.

## Build and ABI adaptation

`D3D12Drv/CMakeLists.txt` builds against the 227 Core, Engine, and Render x64
libraries with C++17. `Precomp.h` includes the 227 Render SDK without defining
the unrelated `OLDUNREAL469SDK` compatibility path.

On 227, `UD3D12RenderDevice` derives directly from `URenderDevice`. The adapter
supplies `DrawGouraudPolyList`, which converts the 227 polygon-list call into
triangle fans accepted by the renderer's existing Gouraud polygon path. This
satisfies the 227 render-device vtable without changing the upstream drawing
architecture.

The 227 constructor capability setup:

- disables `UseLightmapAtlas` because the inherited atlas path is incompatible;
- sets `MaxTextureSize` to 4096;
- disables `NeedsMaskedFonts`;
- adds `RDDESCF_Certified`;
- advertises HD lightmaps and modern texture compression support.

## Texture compatibility

227 exposes modern texture names such as `TEXF_BC1`, `TEXF_BC2`, `TEXF_BC3`,
and `TEXF_BGRA8_LM`. `TextureUploader.cpp` and `UploadManager.cpp` select those
enums under `UNREAL_227`, including the correct minimum block dimensions for BC
uploads.

`TextureManager.cpp` uses the 227 texture `RenderTag` to invalidate realtime
textures. Older upstream hosts use `RealtimeChangeCount`, which does not exist
on the 227 texture type.

`TextureUploader_RGB10A2_LM` reads 227's packed lightmap source correctly,
normalizes its 9-bit lighting channels into the renderer's 16-bit upload
format, and supplies the expected alpha. This removed the black and magenta BSP
lightmap corruption seen during the initial port.

The normalized and unsigned-integer RGB10A2 uploaders also read each packed
pixel from the source row and decode 227's `R/G/B/A` fields from bits
`0/10/20/30`. Reading the destination pointer and using the reversed field
layout produced nondeterministic colors and invalid alpha.

227 `PF_AlphaBlend` geometry uses a dedicated standard-alpha pipeline. It does
not gain `PF_Occlude`, and Gouraud vertices retain `FTransTexture::Light.W` as
their alpha. This prevents alpha-blended meshes from becoming opaque black
depth occluders.

## Borderless presentation

227 distinguishes logical viewport dimensions from physical presentation
dimensions. During borderless fullscreen, `SetRes` preserves the selected
logical resolution and sets `Viewport->PhysicalSizeX/PhysicalSizeY` to the
resolution of the monitor containing the game window. Monitor placement uses
the monitor rectangle as well as its dimensions, so secondary monitors with
nonzero or negative origins are handled. `GetRes` always includes 2560x1440
and 3840x2160 as logical rendering choices even when the physical display does
not advertise those modes.

WinDrv emits a synthetic windowed resize while borderless mode is being
established. `IgnoreBorderlessResize`, together with the existing `SetRes`
call lock, suppresses that one re-entrant resize so a lower logical resolution
is not promoted back to desktop size.

### Alt+Enter mode routing

WinDrv consumes Alt+Enter in its native window procedure and normally calls
`ToggleFullscreen` before UWindow can process the key. The 227 D3D12 adapter
subclasses the active viewport window and handles only that key combination by
calling WinDrv's published `SetScreenMode` command. It selects Borderless from
Windowed, and Windowed from Borderless or Fullscreen. Fullscreen remains
available as an explicit Video Preferences selection.

The adapter associates its renderer instance with the viewport HWND, forwards
all unrelated window messages to the original procedure, ignores key-repeat
toggles, and restores the original procedure during renderer exit only when
its own procedure is still installed.

## Startup background

D3D12 initialization paints the viewport client black before device and swap
chain setup begins, replacing the host window's initial white client frame.
After the renderer installs its viewport procedure, background erase requests
also fill black until normal frame presentation covers the client.

## Multisample antialiasing

`AntialiasMode` supports Off, 2x, 4x, and 8x MSAA. Before scene resources or
pipeline states are rebuilt, the renderer checks the requested sample count
against the RGBA16F scene color, R32_UINT hit, R8 UI mask, and D32 depth
formats. It steps
down through lower sample counts if any required format is unsupported and
logs the requested and effective values when buffers resize.

The hit-resolve pipeline targets R32_UINT, matching the single-sample hit
buffer used for readback. The UI mask resolves independently to R8_UNORM for
presentation. Post-processing and presentation remain single-sample after the
world image and UI mask resolves.

## Performance telemetry

The renderer has opt-in present-cadence telemetry for automated performance
checks. `UNREAL_REVIVED_MEASURE_PERFORMANCE` enables it only for the launched
test process; ordinary launches do not allocate samples or query the frame
timer. After 30 warmup presents, the renderer emits cumulative summaries every
120 frames with average, median, p95, p99, and maximum frame time plus average
FPS.

Samples span consecutive completed `Unlock(Blit)` submissions. They therefore
measure end-to-end engine, D3D12 submission, and pacing behavior rather than
GPU-only duration. The runtime harness owns the environment switch and parses
the latest summary into its evidence CSV.

## Present color controls

The final present shader applies the renderer's existing contrast and
saturation correction before gamma correction. `Contrast` clamps stored and
live values to raw 64 through 170, mapping those endpoints to 50% and
approximately 200% while raw 128 remains neutral at 100%.
`Saturation` is an integer that maps 255 to normal color, approximately 128 to
grayscale, and 383 to 2x saturation. The renderer clamps active values to 128
through 383, so stale configuration cannot select inverted chroma. ModernMenu
presents that range as 0% through 200%, persists both settings, and sends
`D3D12 CONTRAST` or `D3D12 SATURATION` so the active renderer changes without
a restart.

## Bloom postprocessing

`BloomAmount` controls blur radius, highlight extraction, and final additive
gain. With normalized amount `n`, gain follows `8n(1+n)`: no contribution at 0,
about 6x gain at the midpoint, and 16x gain at 255. The extraction threshold
falls from 1.0 to 0.5 so ordinary SDR highlights can bloom. The renderer skips
the bloom pass when either `Bloom` is disabled or
the amount is zero, so the Video Preferences slider's off position has no bloom
cost. The `D3D12 BLOOM <0-255>` renderer command updates the active instance;
ModernMenu uses it for immediate slider changes while persisting the profile.

## Shared world/UI post-process composition

UE1 exposes no reliable native flag that identifies every world tile versus
every HUD or UWindow tile. `Canvas.bZRangeHack`, tile depth, view angle, and
viewport mouse state are not valid substitutes and must not be used to infer
that boundary.

The renderer instead has one explicit, effect-independent contract. At the
start of `HUD.PostRender`, ModernGameHud and ModernIntroHud send `D3D12
BEGINUIPASS`. `BeginUIPass` flushes pending world batches, captures the
completed 3D scene in `PPI_WorldScene`, sets `WorldSceneCaptured`, and marks
later tiles, 2D lines, and 2D points while `UIPassActive`. Those draws
accumulate coverage in a dedicated R8 UI mask render target; hit testing is a
separate attachment and has no post-process responsibilities. Both the capture
and state reset on the next renderer `Lock`, so the contract is strictly
per-frame and works with both single-sample and MSAA scene buffers.

Every world-only post-process effect reads and modifies `PPI_WorldScene`.
`PPI_FinalFrame` separately preserves the completed frame containing the HUD
and menus, while `PPI_Screenshot` is reserved for gamma-correct screenshot
output and is never also sampled by the same pass. The present pass selects the
untouched final-frame pixel wherever the resolved UI mask has coverage and the
processed-world pixel everywhere else. It never
tries to recover translucent UI by subtracting the original scene from an
already blended pixel; that reconstruction is mathematically incomplete and
causes colored streaks and transparency artifacts.

This composition path is shared by bloom, chromatic aberration, vignette,
animated monochrome film grain, CRT scanlines, and future world-only effects.
The three retro effects use independent `0` through `255` strengths and are
fully disabled at zero. Scanlines draw one dark row, a softer shoulder, and two
subtly lifted phosphor rows in output-pixel coordinates. Their balanced pattern
limits average brightness loss to about 13% at maximum, with a square-root
strength response that keeps the pattern legible at middle slider values. Film grain
uses a non-repeating per-pixel integer
hash with a soft particle distribution and varies it once per 24 Hz animation
step independently of the rendered frame rate. New effects must
use `IsWorldPostProcessEnabled`,
`BeginUIPass`, `PPI_WorldScene`, and `ResolveUICompositionMask` rather than add
their own HUD detection, capture, or compositing logic. A custom HUD must send
`D3D12 BEGINUIPASS` exactly once after its last world draw and before its first
UI draw. If it omits the command, the renderer bypasses world-only effects for
that frame instead of guessing and accidentally processing its UI.

## Menu coordinate mapping

The present shader scales and centers lower logical resolutions inside the
physical desktop image. UWindow still receives desktop-space mouse positions,
which originally displaced menu hit targets.

The 227 adapter installs `FD3D12ViewportCallback` around the viewport's existing
`FViewportCallback`. `FViewportOutputAccessor` provides the narrowly scoped
access needed to replace the protected callback pointer. The wrapper forwards
all callback behavior but applies `MapMenuCoordinates` to click and mouse-move
positions, inverting the presentation scale and letterbox offset.

Callback ownership is strict:

1. Save the original callback during renderer initialization.
2. Install the wrapper only for the active viewport.
3. Forward every callback not explicitly transformed.
4. During exit, restore the original only if the wrapper is still installed.
5. Delete only the wrapper owned by the renderer.

Changing this lifecycle risks dangling callbacks during renderer switches or
shutdown.

## Campaign discovery integration

The renderer itself does not own the New Game menu, but the disposable x64
runtime exposed a 227 metadata-path issue while validating normal startup.
`UMenuNewGameClientWindow` uses `IntDescIterator` with
`UnrealShare.SinglePlayer`. Direct engine probing showed that the iterator reads
campaign registrations from `System/`, not only from the configured localization
paths.

The deployment target therefore mirrors localized `UnrealShare.int` and
`UPak.int` into `System/`. The iterator then returns the descriptors for Unreal
and Return to Na Pali in the required
`StartingMap;Screenshot;Campaign name` format.

## Scope remaining

The renderer has an OpenXR detection boundary, not a VR renderer. Normal and
`-novr` launches never query the loader. `-vr` or `EnableVR=True` loads the
bundled Khronos `openxr_loader.dll`, creates a core OpenXR 1.0 instance without
graphics extensions, reports runtime and HMD system properties, and remains on
the existing flat-screen D3D12 path. The instance is destroyed before the
loader is released during renderer shutdown. Missing runtimes, sleeping or
disconnected HMDs, and API failures are diagnosed without failing D3D12.

OpenXR session creation, stereo rendering, VR input, and comfort options are
not implemented and must not be described as supported features.
RTX support and a Vulkan driver are also future work; their order and status
are tracked in
[`roadmap.md`](roadmap.md).

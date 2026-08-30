# OldUnreal 227 renderer port

The renderer originates from the authorized UT99VulkanDrv Direct3D 12 backend.
The tracked provenance and immutable upstream revision are recorded in
[`../THIRD_PARTY.md`](../THIRD_PARTY.md) and
[`../provenance/components.yml`](../provenance/components.yml).

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
desktop resolution used by the swap chain.

WinDrv emits a synthetic windowed resize while borderless mode is being
established. `IgnoreBorderlessResize`, together with the existing `SetRes`
call lock, suppresses that one re-entrant resize so a lower logical resolution
is not promoted back to desktop size.

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

The current implementation targets flat-screen Direct3D 12 parity. OpenXR
stereo rendering, VR input, comfort options, and the portable launcher are not
implemented and must not be described as supported features.

# VR render quality and headset compatibility

## Current baseline and rollback

The owner accepted immediate quality switching, context-sensitive F11 statistics,
bloom correction, gaze swimming/flying, and mouse/load/remount/recenter pitch
recovery on CV1 on 24 September 2026. Commit `df6921c` preserves that accepted
implementation before optional HUD sharpness and the removal of Epic.
These are development changes, not a published release.

After owner acceptance, Balanced (`VRRenderQuality=2`) is now the default.
Current profile is removed from the menu. The original 1024-square UI texture remains. VR logical layout stays locked to 1280 x 1024,
as requested after larger logical resolutions caused distortion. Distance,
scale, panel anchor, tracking, projection, aiming and anti-aliasing defaults
are unchanged. Desktop and VR launchers retain separate profiles.

To inspect the baseline without disturbing current work, create a separate
checkout: `git worktree add --detach ../Unreal-Revived-CV1-baseline df6921c`.
Runtime DLLs/menu packages must be rebuilt from a checkout to use that version;
a Git checkout alone does not replace the deployed binaries. Do not use a hard
reset over unrelated local work.

## Player settings

Video resolution labels use `Width × Height (Aspect Ratio)`. Familiar ratios
include 4:3, 5:4, 16:9 and 16:10; 1366x768 correctly displays 16:9 despite pixel
rounding. Other valid modes use a readable decimal ratio (3440x1440 is 2.39:1)
instead of an unwieldy exact fraction. Custom and monitor modes remain available.
The requested ten desktop resolutions remain included, with raw engine values
separate from labels and the existing ten-second confirmation/revert preserved.
Borderless retains automatic desktop sizing and its disabled resolution control.
VR launches retain their 1280x1024 logical lock; `-novr` retains desktop behavior.

Preferences -> VR -> VR Render Quality:

| Setting | Saved value | Scene per eye | OpenXR output per eye |
| --- | --- | --- | --- |
| Performance - 75% | 1 | 75% of recommended width and height | Same as scene |
| Balanced - 100% (Default) | 2 | Runtime recommendation | Same as scene |
| Quality - 125% | 3 | 125% of recommended width and height | Same as scene |
| Ultra - 150% | 4 | 150% of recommended width and height | Same as scene |

Epic 200% is removed. Unsupported quality values use the default; no retired-
setting migration is retained. Values outside 1 through 4 use Balanced. Ultra costs 2.25 times Balanced's pixels. Runtime supersampling may
already be included in the recommendation; percentages do not set refresh rate.
For the tested CV1 recommendation of 1344x1600, optional outputs are 1008x1200,
1344x1600, 1680x2000 and 2016x2400. Recommendations may change with runtime settings.

Changes apply at the next frame boundary without restarting. Replacement eye
swapchains and scene buffers are allocated before retiring the working pair.
Failed live allocations keep the previous resources and display a failure.
Startup allocation failure retains the internal recovery path: runtime-sized
eye output with original scene buffers. It is not a selectable quality preset.
Failure of recovery allocation or the device is not recoverable through this fallback.

### HUD/menu texture

The optional sharpness feature was removed at the owner's request. HUD and menu
rendering retain the original fixed 1024x1024 texture, layout, size and anchor.
There is no HUD quality setting or pending visual-acceptance task for that feature.
Installation seeds fresh settings; uninstall/reinstall retains saves without
migrating settings. Development rebuilds still preserve the local testing profiles.

### F11

The shared overlay covers intro, gameplay, Return to Na Pali and menus. Active
VR counts completed stereo submissions once per frame, not once per eye; it is
application FPS, not compositor/reprojected FPS. `Res:` shows only one eye's scene
resolution. `VSync: On` means OpenXR frame synchronization, not guaranteed refresh-
rate performance. When the runtime reports an inactive/unfocused headset, the
overlay uses desktop counters, canvas resolution and desktop VSync On/Off.
Sampling resets on transitions. No redundant resolution lines were added.

## Compatibility contract

Runtime view recommendations and limits determine allocations independently for
each eye. Uniform clamping preserves proportions. Equal-size eyes share cached
scene buffers; unequal eyes have separate caches. Logical viewport coordinates
map into the complete raster target. No panel specifications, advertised FOVs,
IPD or lens-distortion corrections are hardcoded by headset model.

The projection audit found independent eye poses in `OPENXRPOSE`, asymmetric
FOV projection in `SetSceneNode`, and the corresponding poses/FOVs submitted in
`FinishOpenXRFrame`. Eye projection/submission remain unchanged. Runtime lens correction
does not excuse incorrect application projections. Canted optics and very wide
FOV still require hardware checks; the existing conservative culling FOV has a
170-degree cap. Canted-eye head orientation now uses the runtime VIEW space with a two-eye
midpoint fallback; parallel-eye CV1 behavior is preserved. See the
[controller/headset compatibility contract](vr-controller-compatibility.md).

Compatibility targets include Quest 2/3/3S/Pro, Index, Vive Pro/Pro 2/Cosmos,
Beyond/Beyond 2, Crystal/Crystal Light and PS VR2 through their PC OpenXR runtimes.
They are targets, not hardware-certified support. The research table below is
context; no advertised panel size is used as a render target. Controller mappings,
eye tracking, foveated rendering and standalone Android are separate capabilities.

## Headset research (23 September 2026)

Valve's [August 2026 Steam hardware survey](https://store.steampowered.com/hwsurvey/)
reports Quest 2 at 26.97%, Quest 3 at 26.01%, Quest 3S at 11.50% and Index at
11.07% of its VR-headset category. This is an optional Steam survey, not the
entire VR market; it supports prioritizing these families rather than assuming
that the most expensive headsets are the most common.

Specifications below are display context, **not hardcoded rendering sizes**.
Refresh-rate availability depends on the selected PC connection/runtime mode.
All listed families await project hardware testing; CV1 is the accepted baseline.

| Family | Published panel resolution per eye | Published refresh rates/context | PC compatibility route to validate |
| --- | --- | --- | --- |
| Quest 2 | 1832 x 1920 | 72/80/90/120 Hz | Meta Link OpenXR |
| Quest 3 | 2064 x 2208 | 72/80/90/120 Hz | Meta Link OpenXR |
| Quest 3S | 1832 x 1920 | Check active Link mode | Meta Link OpenXR |
| Valve Index | 1440 x 1600 | 80/90/120/144 Hz; displays canted outward 5 degrees | SteamVR OpenXR |
| Vive Pro 2 | 2448 x 2448 | 90/120 Hz; wireless limitations | SteamVR OpenXR |
| PS VR2 | 2000 x 2040 | 90/120 Hz | Windows PC adapter + SteamVR |
| Bigscreen Beyond / Beyond 2 | 2560 x 2560 | 75/90 Hz; transport scaling differs by mode | SteamVR OpenXR |
| Pimax Crystal Light | 2880 x 2880 | Main product page lists 72/90/120 Hz | Pimax OpenXR / SteamVR |
| PICO 4 Ultra | 2160 x 2160 | Up to 90 Hz | PICO Connect + SteamVR; candidate only |

Primary sources:

- [Meta Quest 2/3 specifications](https://developers.meta.com/horizon/resources/device-optimization-comparison/),
  [Meta panel versus render sizes](https://developers.meta.com/horizon/essentials/render-scale/),
  [Link support and OpenXR setup](https://developers.meta.com/horizon/documentation/unity/unity-link/).
- [Valve Index display, refresh rates and canted optics](https://www.valvesoftware.com/en/index/headset).
- [Vive Pro 2 specifications](https://www.vive.com/eu/product/vive-pro2/specs/),
  [Vive PC OpenXR runtime guidance](https://developer.vive.com/resources/openxr/unity/overview/?site=au).
- [Sony PS VR2 display specifications](https://blog.playstation.com/2022/01/04/playstation-vr2-and-playstation-vr2-sense-controller-the-next-generation-of-vr-gaming-on-ps5/),
  [PC setup](https://www.playstation.com/en-ie/support/hardware/pc-ps-vr2-set-up/).
- [Bigscreen display transport](https://bigscreenvr.com/displays/),
  [Beyond 2 SteamVR/OpenXR support](https://bigscreenvr.com/experiences/enterprise/),
  [refresh rates](https://beyond.bigscreenvr.com/).
- [Pimax Crystal Light specifications](https://www.pimax.com/product/crystal-light),
  [OpenXR guidance](https://pimax.com/blogs/blogs/how-to-run-openxr-on-the-pimax-crystal).
- [PICO 4 Ultra specifications](https://www.picoxr.com/es/products/pico4-ultra),
  [PICO Connect SteamVR support](https://www.picoxr.com/es/software/pico-link).

Khronos specifies the runtime's [recommended and maximum view dimensions](https://registry.khronos.org/OpenXR/specs/1.1/man/html/XrViewConfigurationView.html)
and [per-eye projection pose/FOV contract](https://registry.khronos.org/OpenXR/specs/1.0/man/html/XrCompositionLayerProjectionView.html).
These values, not advertised FOVs or panel dimensions, drive the renderer.
Controller mappings, eye tracking, foveated rendering and standalone Android
builds are not established by resolution support.

## Validation and remaining acceptance

Automated checks:

```powershell
cmake --build local/build --config Release --target D3D12Drv
cmake --build local/build-vr-tests --config Release
ctest --test-dir local/build-vr-tests -C Release --output-on-failure
powershell -NoProfile -File scripts/test-video-preferences.ps1
powershell -NoProfile -File scripts/test-vr-render-quality.ps1 -Qualities 2
powershell -NoProfile -File scripts/check-repository.ps1
```

Build the development menu and deploy the fresh renderer to `local/game` before
gameplay tests; preserve player INIs when running the menu build script.
Fixtures use disposable INIs. The live quality test requires an available
OpenXR runtime and checks 75% -> 150% -> Balanced
switches in one process. Initialization alone does not establish optical quality.

Native tests cover unequal runtime sizes, all presets, small through high-resolution
recommendations, uniform limits/overflow, logical viewport mapping,
allocation failures and rollback. WARP tests exercise descriptor capacity through
200 replacements, asymmetric UI-mask lookup, weapon occlusion and bloom scissor
coverage, including an oversized stress case beyond the remaining presets.
Preferences tests exercise labels, saved settings and desktop
resolution selection/confirmation/revert. Shared production quaternion/vector helpers now also test independent rotated
eye orientations, cant, coordinate conversion, orthonormality and equivalent
quaternion signs. This validates the math, not runtime head-center semantics.
Pitch, locomotion and panel tests retain
the previously accepted baseline. Synthetic tests do not certify any headset model.

Other headset owners should compare stereo geometry, nearby objects, panel bounds,
wide-FOV edge visibility, head rotation/translation, runtime timing and fallback.
Record headset/runtime version, refresh rate, runtime resolution and actual eye sizes.

Remaining: hardware reports for other headsets (especially canted/wide-FOV devices).
The owner closed the focus-loss stutter task on 24 September 2026. The planned code/settings work,
automated rotated-eye coverage, documentation and Git checkpoints are complete.
No cross-headset optical guarantee is claimed.

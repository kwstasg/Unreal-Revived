# VR render quality and headset compatibility

## Preserved baseline

The owner confirmed on 23 September 2026 that Current profile in the first
updated build behaves like the original on Oculus Rift CV1. They also tested
the other presets in gameplay, reporting little visible world-detail difference
and changes mainly in menu text. After the output-sizing revision they reported
150% may look cleaner than 75%, with no perceived performance problems or
distortion. Increasing the logical video resolution did cause letterboxing and
fisheye distortion; the subsequent layout lock below addresses that report.
Automated tests are not optical or comfort certification.

No installer/profile defaults are changed. `VRRenderQuality=0` (also the default
when the key is absent) uses the original 1280 x 1024 scene resolution.
VR launches now enforce that logical layout even with customized profile dimensions,
as requested after the owner's tests. HUD distance,
HUD scale, world scale, aiming, anti-aliasing, tracking, eye transforms, projection
and the 1024 x 1024 UI swapchain retain their existing defaults/behavior.

## Player settings

Preferences -> Video/Graphics displays `Width × Height (Aspect Ratio)` while
passing the original `WidthxHeight` value to the engine. The D3D12 resolution list
includes (on desktop) 1024x768, 1280x720, 1280x1024, 1600x900, 1600x1200, 1600x1280,
1920x1080, 1920x1536, 2560x1440 and 3840x2160, plus enumerated display modes.
D3D12's existing Fullscreen mode uses a desktop-sized window and letterboxes
the logical game image, so these options are valid there as well as in Windowed
mode. It does not switch to an exclusive monitor mode. The current selection
remains visible. Borderless retains desktop sizing and the disabled resolution control.
The existing ten-second confirmation/revert dialog is preserved. Other video
drivers keep their own mode enumeration, with the same improved labels.

Preferences -> VR adds these modes:

| Mode | Saved value | Scene width/height | Pixels relative to Balanced |
| --- | --- | --- | --- |
| Current profile (Default) | 0 | 1280 x 1024 | Depends on runtime |
| Performance - 75% | 1 | 0.75 x runtime recommendation | 56.25% |
| Balanced - 100% | 2 | Runtime recommendation | 100% |
| Quality - 125% | 3 | 1.25 x runtime recommendation | 156.25% |
| Ultra - 150% | 4 | 1.50 x runtime recommendation | 225% |
| Epic - 200% | 5 | 2.00 x runtime recommendation | 400% |

Changes apply at the next frame boundary, with a brief allocation pause, and
are saved for future launches. Both replacement eye swapchains and scene buffers
are prepared before replacing the active pair. Allocation or image-enumeration
failure retains the previous active quality and reports the failure in Preferences.
Switching leaves the session, tracking reference and UI anchor intact.
The first live-switch CV1 attempt exposed the original 64-slot RTV heap limit:
profile, active and replacement render targets coexist during the transaction.
The heap now reserves 256 CPU-only RTV descriptors. A D3D12 WARP regression
reproduces exhaustion at 64 and exercises 200 replacement/rollback cycles each
for shared and independent eye buffers at the new capacity, checking descriptor
usage returns to its baseline after every cycle and zero after teardown.
Runtime supersampling can already be included in the reported
recommendation. Performance is relative to Balanced and can still cost more
than the legacy profile. This setting does not change the refresh rate.

The desktop and VR launchers have separate profiles. Changing the desktop
profile does not set VR quality. Inside a VR launch, the logical viewport is
locked to 1280 x 1024 (5:4), including startup, console SetRes and window resizing.
GetRes advertises only that size and the video resolution control is disabled
with help pointing to VR Render Quality. The quality presets choose scene pixel
dimensions independently; they do not resize that viewport. The -novr override
retains desktop behavior even when EnableVR is saved.

F11 uses the shared ModernConsole overlay for intro, Unreal, Return to Na Pali
and menus. In VR it reports application FPS measured with a monotonic wall clock,
counting once after successful xrEndFrame with both eye images released. It does
not count each eye or claim compositor/reprojected FPS. Average and extrema use
the same source; extrema are approximately one-second samples. F11 resets the
statistics; a submission gap of two seconds makes the current FPS zero. Current
The overlay falls back to the existing desktop FPS/average/low/high counters
when the runtime reports loss of focus, a stopped session, or shouldRender=false
(including headset removal as reported by the runtime). Wearing the headset
again automatically selects VR counters and eye resolution. While inactive,
the overlay shows desktop canvas resolution and desktop VSync On/Off. During
active VR, VSync reads On for OpenXR frame synchronization; this does not imply
that the application achieves the headset refresh rate.
State transitions reset sampling so wearing the headset again starts fresh.
The existing `Res:` line shows only the left eye's scene dimensions. No second
eye, output dimensions or explanatory text is added to F11. Desktop retains the
existing FPS source and display.

Validation of the layout/statistics revision: renderer build and script compile
passed, all six native tests passed, desktop preferences passed, and the VR-mode
gameplay fixture confirmed startup and both oversized SetRes requests remain at
1280 x 1024. OpenXR initialization returned runtime-unavailable (-51), so live
VR FPS and overlay appearance across the three HUDs still need a CV1 check.

## Rendering implementation

VR pitch recovery suppresses the standard MouseY look-axis event during active
first-person VR while preserving pointer-position/delta events for menus and
desktop mouse input. Loaded interactions have a transient initialization flag:
the first active VR view levels saved software pitch/roll and clears pending
vertical input, preserving yaw. Right-stick recenter retains its existing
leveling and now also clears queued vertical input. Remount recovery uses
[XR_EXT_user_presence](https://registry.khronos.org/OpenXR/specs/1.1/man/html/XrEventDataUserPresenceChangedEXT.html)
when the runtime and system support it; otherwise a hidden/stopped session must
precede returning to focus. Ordinary visible-overlay focus transitions do not
count as remounts. Physical head pose and facing direction are not reset by
automatic pitch recovery. Native recovery-policy tests and gameplay pitch/yaw
checks pass. On 24 September the owner tested the recovery changes on CV1 and
reported them perfect, accepting this development baseline. Other headset
runtime behavior remains unverified.

Bloom explicitly restores a full scene scissor before its passes. The preceding
VR UI pass sets 1024 x 1024 bounds; inheriting those clipped the bloom composite
as quality increased. A WARP regression renders the production bloom shader at
all six CV1 preset sizes, reproduces the inherited-scissor failure, and verifies
the far corner is covered with scene-sized bounds. Bloom settings stay unchanged.

Head-gaze swimming, flying and CheatFlying use hooks on the stock PlayerMove
state functions. Acceleration uses composed head pitch/yaw/roll; body turning,
stock per-state input scales, explicit vertical controls and move replication
retain their stock paths. Walking remains on its existing yaw-based input path.
For ordinary right-stick look bindings, VR swimming/flying and CheatFlying now
suppress stick pitch just like walking; head pitch supplies vertical look.
Only walking/falling rotate the left-stick input, avoiding a second gaze
rotation on top of the swimming/flying state hooks. Desktop input is unchanged.
State functions are resolved natively, as with the weapon hooks, because the
script FindFunction path did not resolve these state-local functions. The
game regression drives the real state dispatch with a deterministic head pose,
checks forward/backward and up/down gaze in all three states, base-view
preservation, and inactive-VR fallback. Both fixes still need CV1 visual testing.

- The default path keeps its existing scene buffers. No optional eye buffers
  are allocated unless a non-default preset is active in a valid stereo frame.
- Optional scene buffers use each runtime view's dimensions, uniformly clamped
  against the view's reported maxima and the D3D12 2D texture size limit.
  Rounding is downward to whole pixels. Invalid preset values select the
  current profile; invalid dimension recommendations retain profile sizing.
- Sequential eye passes share a cached buffer set when their sizes match.
  Different-size eyes get independent cached sets, avoiding reallocations
  between eyes on every frame. The profile buffers are retained for fallback.
- Logical UE1 viewport coordinates map to the full raster target, including
  inset viewports. Projection, culling, poses and submitted FOVs are unchanged.
- Current profile retains the runtime-recommended OpenXR output size. In the
  optional presets, both the scene and the submitted eye swapchain use the
  scaled dimensions. The scene takes its dimensions from the accepted
  swapchain, avoiding an intermediate reduction to the fixed recommended size
  before the runtime performs lens correction. FOVs and eye poses do not change.
- If either optional eye swapchain cannot be created, the partial pair is
  destroyed and both eyes retry at their original runtime recommendations with
  Current profile scene rendering. This avoids mixed quality between eyes.
- UI uses its existing logical layout and physical panel geometry. Its fixed
  output texture remains unchanged; a separate optional UI sharpness feature
  is deferred until the CV1 comparison succeeds.
- Screenshot readback retains the engine's logical dimensions and reads the
  most recent eye buffers when appropriate.
- Optional allocation failures release partial quality buffers and use the
  current profile for that session, with a menu status and log message. The
  saved preference is retained for the next launch. Device removal or failure
  of the baseline allocations cannot be recovered by this fallback.
- Logs record preset, actual scene size, runtime recommendation and profile/UI
  layout size. `D3D12 VRQUALITYSTATUS` reports `ready`, `restart` or `fallback`.
  `D3D12 VRRENDERSIZE 0` and `1` report each eye's active scene and output sizes;
  these appear in Preferences -> VR, independently of the pending menu selection.

## CV1 investigation and output-sizing revision

The owner's `Unreal.log` from 20:18 on 23 September records Oculus runtime
1.207.0, a 1344x1600 eye recommendation and Ultra rendering at 2016x2400 with
4x MSAA, followed by travel into Vortex2. No quality-allocation fallback was
reported. The preset did apply; the first implementation still reduced its
scene to a 1344x1600 output texture. That is a confirmed limitation, not proof
that it alone explains the subjective similarity.

The revised optional presets retain their full resolution through submission.
With the same runtime recommendation and sufficient runtime limits:

| Mode | Scene per eye | OpenXR output per eye |
| --- | --- | --- |
| Current profile | 1280x1024 | 1344x1600 |
| Performance | 1008x1200 | 1008x1200 |
| Balanced | 1344x1600 | 1344x1600 |
| Quality | 1680x2000 | 1680x2000 |
| Ultra | 2016x2400 | 2016x2400 |

The update does not replace game textures or headset panels. Compare fine
geometry/edge shimmer at the same viewpoint, not only broad wall textures.
The size readouts provide an objective check that the active preset changed.

Validation of the revision: renderer build and menu compilation succeeded;
all five C++ tests and the in-game preferences/revert test passed. The new
swapchain test uses mock OpenXR callbacks to verify the actual creation
requests, independent eye limits, and first/second-eye allocation failure
cleanup. A live smoke test was attempted, but Oculus reported the active
runtime unavailable (`-51`), so new CV1 output sizes remain hardware-unverified.

## Headset research (23 September 2026)

Valve's [August 2026 Steam hardware survey](https://store.steampowered.com/hwsurvey/)
reports Quest 2 at 26.97%, Quest 3 at 26.01%, Quest 3S at 11.50% and Index at
11.07% of its VR-headset category. This is an optional Steam survey, not the
entire VR market; it supports prioritizing these families rather than assuming
that the most expensive headsets are the most common.

Specifications below are display context, **not hardcoded rendering sizes**.
Refresh-rate availability depends on the selected PC connection/runtime mode.
All rows other than the pre-change CV1 baseline await project hardware testing.

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

## Projection audit and remaining hardware validation

The existing code already obtains independent eye orientations and positions
in `OPENXRPOSE`, uses asymmetric FOV bounds in `SetSceneNode`, and submits the
same `OpenXRViews` poses/FOVs in `FinishOpenXRFrame`. These paths were left intact.
The conservative UE1 culling FOV still has its existing 170-degree cap; extreme
wide-FOV modes need edge-visibility testing before claiming support. Published
specifications cannot prove absence of optical distortion or stereo discomfort.

Automated checks:

```powershell
cmake --build local/build-feature --config Release --target D3D12Drv
cmake -S D3D12Drv/tests -B local/build-vr-tests "-DOPENXR_INCLUDE_DIR=$PWD/local/build-feature/_deps/openxr-src/include"
cmake --build local/build-vr-tests --config Release
ctest --test-dir local/build-vr-tests -C Release --output-on-failure
powershell -NoProfile -File scripts/build-modern-menu.ps1 -GameRoot local/game
powershell -NoProfile -File scripts/test-video-preferences.ps1
```

The preferences test requires the freshly built renderer in the disposable
`local/game/System64` runtime. It uses temporary engine/user INIs, checks the
default and saved quality choices, all ten windowed resolutions, formatted
labels, actual mode selection, the ten-second confirmation and rejection/revert.
CPU sizing tests cover custom profile preservation, every preset, unequal eye
sizes, clamping/overflow, and normalized inset/full viewport coordinates.
Existing GPU UI occlusion tests also cover asymmetric eye FOV mask lookup.

With the Oculus software running and CV1 connected/awake, the optional live
startup check is:

```powershell
powershell -NoProfile -File scripts/test-vr-render-quality.ps1
```

It launches a short gameplay test for each preset with disposable INIs, checks
both runtime output dimensions, exercises live 75% -> 150% -> default switching
within the same process, and reports whether a stereo frame was
rendered. Initialization alone does not establish visual correctness. It does
not change the player's chosen quality or profile dimensions.

CV1 acceptance before release:

1. Start with Current profile and the same map, graphics settings and runtime
   settings as the prior build. Confirm unchanged world scale, stereo, HUD and
   menu placement, aiming, and frame timing.
2. Select Balanced and inspect the immediately updated scene/runtime dimensions.
   Check straight edges, nearby and distant objects, UI text, menu selection,
   weapon/UI occlusion, head rotation/translation and view recentering.
3. Repeat at 75%, 125% and 150% where GPU memory/performance permits. Check
   that quality changes never move the optical centre or resize the UI panel.
4. Return to Current profile without restarting. Confirm original dimensions and
   appearance at the locked 1280 x 1024 logical resolution.
5. Check screenshots, map travel, tracking loss/recovery and exit/relaunch.
   Record headset, runtime version, refresh rate, runtime resolution setting,
   effective eye dimensions and frame-time results with each report.

Other headset owners can use the same checklist. Until those reports exist,
describe these as compatibility targets, not certified or visually verified
headsets. No automatic default-quality increase is planned.

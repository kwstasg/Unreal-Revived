# VR UI milestone and maintenance contract

## Accepted milestone - 2026-09-10

Historical log paths below are provenance only. Obsolete logs and experiment
archives were removed at the owner's request on 25 September 2026.

The user validated and accepted the complete VR menu, desktop-like UI/HUD
placement, shared panel geometry, stable slider adjustment, meaningful distance,
and explicit recenter behavior on the existing Oculus Rift CV1 setup. This is a
source milestone, not a GitHub release or a claim of universal headset support.

The accepted implementation and binaries were preserved before cleanup in
`local/backups/vr-ui-accepted-milestone-20260910-212645/`. Local backups and binaries stay
ignored. The committed implementation is the baseline for future work; do not
restore the older visible-but-clipped `f767139c` experiment.

## One canvas, one panel

- Use the existing desktop UWindow layout, GUI scale, clipping and pointer
  coordinates. Menus span the full canvas, Preferences retains desktop centering,
  and the cursor, hover, click, drag and controller focus agree with painting.
- Preserve desktop intro artwork and gameplay HUD placement and HUD scaling.
  Do not add VR-only root shrinking, per-widget offsets or a second HUD inset.
- Include console messages, translator/MOTD and statistics in the VR canvas pass.
  Keep the world weapon and gaze crosshair on the eye canvas.
- HUD, menu and intro use the same panel dimensions and pose. Opening or closing
  menus must not change position, size or orientation.
- The initial anchor is upright at eye height, using horizontal heading only.
  Explicit Recenter VR View now also captures horizontal heading only, keeping
  the panel level when recentering while looking up/down or tilting sideways.
  It stays fixed; menu transitions and sliders do not recapture it. The low-level
  UI-only reset still uses an upright anchor and retains heading near vertical gaze.

## Projection ownership: the decisive fix

Canvas vertices are constructed from the symmetric game FOV. Inside
`BEGINVRUIPASS`, `SetSceneNode` must use that matching symmetric projection.
OpenXR then applies the asymmetric eye projection to the completed panel once.
Applying eye FOV while rasterizing canvas vertices shifts and scales the source
before it ever reaches the panel; increasing panel width cannot recover clipped
source content.

`SetSceneNode` flushes pending batches before changing projection constants.
Entering a VR UI pass selects canvas projection; leaving it flushes the UI and
restores eye projection. Scene-node changes within a pass obey the same rule.
Do not bypass that flush or leak canvas projection into world rendering.

The whole source is sampled into the UI swapchain. Physical width/height matches
the source aspect ratio. The square intermediate texture alone does not imply
stretching: source aspect is restored on the physical quad. Preserve the working
sampling, shaders, alpha and composition unless new evidence identifies a defect
at that specific boundary.

The 2026-09-21 weapon-over-HUD change addresses composition order, not panel
placement: the same panel is submitted using eye-specific array slices and
left/right visibility. Each slice cuts out the corresponding eye's weapon
coverage, keeping pose, physical size, source layout and input coordinates
unchanged. Collision fade leaves recovery UI unobscured. Pixel tests cover the
composition math; the owner accepted stock/UPak weapon/HUD overlap on September 21.

## Settings and physical geometry

Preferences > VR controls distance, scale and Recenter VR View. Startup uses
normal/VR shortcuts; the redundant next-launch checkbox was removed on 2026-09-11.
Settings persist in `[D3D12Drv.D3D12RenderDevice]`.

| Setting | Default | Range | Meaning |
| --- | --- | --- | --- |
| `VRHUDDistance` | 1.75 m | 0.50-5.00 m | Move along the saved anchor's forward direction |
| `VRHUDScale` | 1.0 | 0.5-2.0 | Resize the physical panel about its center |

Width = `2 * 1.75m * tan(32 degrees) * scale`; height = width times source
height/width. At 100%, width is approximately 2.187 m. It spans 64 degrees at
1.75 m, 40.1 degrees at 3 m, and 24.7 degrees at 5 m. Distance must not enlarge
the panel to compensate: that would hide its apparent distance effect again.
User preference and headset checks determine comfort; defaults are a starting point.

`D3D12 VRHUDDISTANCE <metres>` and `D3D12 VRHUDSCALE <factor>` update and save
settings without invalidating the anchor. `D3D12 RESETVRUIANCHOR` explicitly
recenters the UI only. The Preferences button now uses `D3D12 RECENTERVR` to level
software view tilt, adopt horizontal gaze as forward and refresh both view/UI
references between frames. User testing accepted yaw but found that the upright
panel appeared oppositely pitched/rolled. Full head orientation for the HUD panel
was accepted on 2026-09-11 together with quick bindings and UI colors. On September
25 the owner confirmed the world horizon fix but reported the remaining HUD tilt;
explicit panel recenter now uses heading only too. This supersedes full-pose panel
capture; size, distance, shared layout and explicit anchoring remain. Script
callers use plain `BEGINVRUIPASS`/`ENDVRUIPASS`; old suffixes
are harmless compatibility input and no longer select a separate layout.

The world reference is independent of that panel anchor. The September 25
[horizon-lock audit](vr-horizon-lock.md) changed world capture to heading only,
so recentering with head tilt cannot store pitch/roll in the environment. Natural
head pitch/roll remains tracked. The owner confirmed the world fix; upright HUD
recenter now awaits CV1 validation.

## Rules for future changes

1. Start from this accepted milestone and preserve a recoverable source/binary
   baseline before experiments. Do not combine unrelated fixes in one test build.
2. Identify the failing boundary: logical canvas, raster projection, texture
   mapping, physical size, or anchor pose. Log values in their actual units.
3. Keep logical canvas/input conversions together and exact. Do not apply a
   paint-only transform or independently reposition menu children.
4. Fix one boundary per diagnostic build. Require a specific expected result,
   compare at identical settings, and discard changes that do not improve it.
5. Never use opacity, depth, flipping, curvature or logo work as a substitute
   for diagnosing a positioning problem when the menu already appears.
6. Validate flyby and playable maps, menu open/closed, and desktop mode. Ordinary
   desktop mirrors are not proof of the OpenXR composition layer's visibility.
7. Keep recenter explicit, size independent of distance, and all UI on the same
   panel. These are user-accepted requirements, not optional comfort experiments.
8. Record observed headset results separately from build or smoke-test results.
   Update current documentation when behavior changes; archive superseded advice.

## Validation and limits

The user accepted the final shared-panel build in the headset. Release renderer
builds and ModernMenu compilation passed; ModernMenu compiled with zero warnings.
Desktop flyby/gameplay lifecycle evidence is in
`local/logs/automated-20260910-211332/` and preceding entries in `progress.md`.
Automated checks do not prove headset comfort, mouse accuracy at every resolution,
or broad headset/runtime compatibility. No new release or tag accompanies this
milestone. Historical failed approaches are recorded in
[the investigation archive](vr-ui-investigation.md).

After removing redundant script mode dispatch, ModernMenu rebuilt with zero
warnings and desktop flyby/gameplay smoke checks passed at
`local/logs/automated-20260910-213012/`. User profiles were preserved. Cleanup
does not change the accepted geometry or projection.

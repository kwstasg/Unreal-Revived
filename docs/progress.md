# Engineering progress

This log records meaningful implementation milestones, why they were needed,
and how they were validated. Keep current behavior documented in the focused
technical guides; use this file for the chronological record.

## 2026-08-30

### Established a reproducible 227k_15 host

- Pinned the OldUnreal 227k_15 Windows x64 runtime and SDK with immutable archive
  and module hashes in `manifests/hosts/`.
- Kept the original Steam installation untouched and created an ignored,
  disposable runtime under `local/game/`.
- Added CMake validation for the required Core, Engine, and Render headers and
  x64 import libraries.
- Validated the runtime and SDK inputs against their recorded hashes.

### Imported and attributed the Direct3D 12 renderer

- Imported the authorized D3D12 backend from UT99VulkanDrv at the immutable
  revision recorded in `THIRD_PARTY.md` and `provenance/components.yml`.
- Preserved upstream structure while adding an explicit `UNREAL_227` host path.
- Added the applicable upstream notices under `LICENSES/`.
- Validated that the repository safety check excludes local references,
  downloads, binaries, SDK files, and game content.

### Ported the renderer to the 227 x64 ABI

- Added the CMake x64 DLL target and linked it to the 227 Core, Engine, and
  Render libraries.
- Adapted the render-device base class, capability flags, SDK includes, texture
  format enums, realtime texture invalidation, and `DrawGouraudPolyList` vtable
  entry for 227.
- Added the deployment target for `D3D12Drv.dll` and `D3D12Drv.int`.
- Validated a successful build, deployment, native D3D12 load, and absence of
  XOpenGL fallback.

### Corrected 227 HD lightmaps

- Fixed `TextureUploader_RGB10A2_LM` to read the packed source correctly,
  normalize the lighting channels, and provide the expected alpha.
- Removed black and magenta corruption from BSP lightmaps.
- Validated representative gameplay surfaces in the disposable runtime.

### Corrected RGB10A2 source reads

- Fixed the normalized and unsigned-integer RGB10A2 uploaders to decode each
  source pixel instead of reading uninitialized destination upload memory and
  corrected the 227 packed channel positions to `R/G/B/A` bits `0/10/20/30`.
- Added a dedicated `PF_AlphaBlend` pipeline permutation, excluded alpha-blended
  geometry from automatic depth writes, and retained Gouraud vertex alpha.
- Reverted separate upload-ordering, clipping, and chunking experiments after
  focused runtime checks exposed performance or precache regressions.
- Validated Debug and Release compilation, Debug deployment, successful
  precaching, and the `Unreal.unr` flyby. The previously black content rendered
  correctly and the reflected scene remained visible at the reported angle.

### Corrected borderless resolution behavior

- Preserved the selected logical resolution while presenting at the physical
  desktop resolution.
- Suppressed the synthetic WinDrv resize that promoted lower logical
  resolutions back to desktop size.
- Added callback-based mouse coordinate mapping that inverts presentation scale
  and letterbox offsets for UWindow.
- Preserved and restored the original viewport callback during renderer startup
  and shutdown.
- Validated menu hover and click alignment at native and lower resolutions.

### Restored normal startup and campaign selection

- Removed the forced campaign-map startup behavior.
- Established the working command form
  `Unreal.unr ini=D3D12Test.ini userini=D3D12TestUser.ini`; the leading map token
  prevents `ini=` from being parsed as a network URL.
- Traced the empty New Game combo through
  `UMenuNewGameClientWindow.IntDescIterator` with a disposable UnrealScript
  commandlet.
- Confirmed that 227 discovers campaign registrations from `System/`, then
  updated deployment to mirror localized `UnrealShare.int` and `UPak.int` into
  that directory.
- Validated that the iterator returns both `Unreal` and `Return to Na Pali` and
  that the D3D12 runtime remains responsive without fallback.

### Restored recovery dialog localization

- Updated deployment to mirror the complete 227 `Startup.int` from
  `SystemLocalized/int/` into both `System/` and `System64/`.
- Confirmed the existing `Unreal Gold D3D12` desktop shortcut already targets
  the disposable x64 executable with the correct map, INI arguments, and
  working directory, so no shortcut mutation was needed.
- Triggered recovery mode through the actual desktop shortcut and verified the
  window title resolves to `Unreal Recovery Mode`; normal cancellation removed
  the temporary recovery marker.

### Added an FPS checkbox to Video preferences

- Added a standalone `ModernMenu` UnrealScript package that preserves the 227
  Video preferences page and inserts **Show FPS Statistics** directly below
  **Show Fullscreen**.
- Routed the disposable D3D12 console through a custom root window without
  rebuilding or replacing the network-sensitive `UMenu.u` package.
- Added `deploy-modern-menu` to compile with the disposable x64 `UCC.exe`,
  deploy `ModernMenu.u`, and maintain the required test-profile entries.
- Validated clean package compilation with zero warnings, clean visual layout,
  and runtime activation of the engine's `TimeDemo` object.
- Persisted the FPS preference in the active engine profile and restored
  TimeDemo during menu-root startup; validated that the checkbox remains
  checked after the actual Preferences Restart flow.
- Updated the Preferences Restart action to save normally and relaunch with the
  explicit D3D12 engine and user profiles instead of losing them to 227's bare
  `RELAUNCH` behavior.
- Prevented Restart from applying stale Game-tab console selection state, which
  had replaced the windowed UMenu with `UPakConsole` or `UBrowserConsole`.
  Restored `UMenu.UnrealConsole` and validated it remains selected after the
  actual Restart flow.
- Replaced the stock Game preferences page with a compatible subclass that
  displays and locks **Standard Unreal Console**. Validated that the selector
  cannot open, Restart retains both custom INI arguments, all three disposable
  engine profiles remain on `UMenu.UnrealConsole`, and normal shutdown leaves
  no `Running.ini` marker.
- Promoted the current ignored D3D12 engine and user profiles to the disposable
  x64 runtime defaults after backing up the prior defaults under `local/`.

### Added project documentation

- Replaced the planning-stage README with the implemented renderer status,
  build entry point, documentation index, and honest roadmap.
- Added build, configuration, renderer-port, testing, and repository-layout
  documentation.
- Added workspace-wide and renderer-scoped Copilot instructions so future work
  follows the established safety, provenance, compatibility, and validation
  rules.
- Added `current-state.md` as a session-independent resume point containing the
  supported boundary, verified commands, critical invariants, and next
  priorities.
- Documented how the renderer plugin can be developed without full native
  engine source, including the SDK ABI, import libraries, available evidence,
  and limits on private engine modification.

## Entry template

Add new entries in this form:

```markdown
## YYYY-MM-DD

### Short milestone name

- Change: what behavior or code changed.
- Reason: the failure, requirement, or evidence that motivated it.
- Validation: the focused build, test, runtime check, or artifact inspected.
- Remaining: known limitations or follow-up work, when applicable.
```

Do not record a feature as complete until its focused validation has passed.
Do not use this log as a substitute for updating current-state technical docs.

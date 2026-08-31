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
  revision `a29e9ac0df1c60ad302d91bc3a51ab026c1a307c`.
- Preserved upstream structure while adding an explicit `UNREAL_227` host path.
- Retained applicable component notices beside vendored third-party code.
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

## 2026-08-31

### Added repeatable D3D12 runtime smoke automation

- Added `scripts/test-d3d12-runtime.ps1` to launch representative maps with a
  temporary renderer profile, request normal shutdown, preserve per-case logs,
  reject known renderer failure signatures, and verify that the normal profile
  is not changed by the harness.
- Kept direct-map arguments isolated to automation. The normal shortcut still
  launches `Unreal.unr` with `D3D12Test.ini` and `D3D12TestUser.ini`.
- Validated the normal launch, main menu, Unreal campaign start at `Vortex2`,
  D3D12 bind/unbind cycle, and clean shutdown without XOpenGL fallback.
- Validated automated content smoke runs for `NyLeve`, `DmDeck16`, `Chizra`,
  `Vortex2`, `Dug`, and `Terraniux`.
- Validated automated setting runs for MSAA 2x/4x, precache disabled, VSync,
  both alternate lighting modes, XOpenGL gamma, positive and negative LOD bias,
  bloom, and line occlusion. These runs establish startup, frame presentation,
  log health, and clean shutdown, not visual correctness.
- Manually confirmed `NyLeve` and `DmDeck16` showed no reported lightmap,
  texture, fog, flicker, input, or stability problem.
- Added automated temporary-profile coverage for FPS enabled and disabled,
  1280x720 and 1024x768 fullscreen profiles, and 1600x1024 windowed startup.
- Confirmed external click automation is not deterministic for this UWindow
  UI: controls expose no Windows UI Automation elements and ignore background
  Win32 input messages. Retained screenshots remain the evidence for menu
  layout and mouse alignment rather than repeatedly requesting manual checks.

### Cleaned disposable development artifacts

- Removed the duplicate ignored `out/` CMake tree while retaining
  `local/build/` as the canonical incremental build directory.
- Corrected the VS Code search and watcher exclusions to match the runtime's
  `directx9c/` directory.
- Organized 27 unique historical menu screenshots under ignored `local/logs/`
  with a hash manifest and removed three byte-identical duplicate aliases.
- Removed superseded runtime logs and the regenerable ModernMenu class staging
  copy after preserving relevant validation evidence.
- Retained roadmap placeholders, upstream Visual Studio project metadata,
  recovery and compatibility assets, host archives, SDK files, backups,
  provenance records, and reference sources.
- Validated a Release configure, build, and deployment; matched the built and
  deployed DLL hashes; matched the pinned 227k_15 host hashes; and passed the
  repository safety check.

### Added screenshot regression testing

- Extended `scripts/test-d3d12-runtime.ps1` with explicit screenshot capture,
  baseline update, and comparison modes. Captures and baselines remain under
  ignored `local/logs/` storage and do not alter the normal shortcut or INIs.
- Captured the exact Unreal window from the desktop after map settlement,
  validated image dimensions and non-uniform sample pixels, and preserved each
  image beside its case log and effective test profile.
- Added tolerant sampled-pixel comparison with separate mean-channel and
  changed-sample thresholds. Dynamic title/FPS and lower HUD bands are excluded
  from comparison.
- Verified that F9, `EXEC=SHOT`, and direct `LEVACT_SaveScreenshot` requests do
  not produce an image on this 227k_15 host, so desktop window capture is the
  documented supported path.
- Created and reviewed ignored local baselines for all six content maps. Fresh
  comparisons passed for `NyLeve`, `DmDeck16`, `Chizra`, `Dug`, and
  `Terraniux`. `Vortex2` remains capture-only and is explicitly reported as
  `SkippedDynamic` because its scripted intro changes camera and player state.

### Added logical 4K and capability-checked MSAA 8x

- Extended `AntialiasMode` with MSAA 8x and selected the highest supported
  sample count across the scene color, hit, and depth formats before rebuilding
  resources and pipeline states.
- Corrected the hit-resolve pipeline target to R32_UINT to match its resolved
  render target and readback path.
- Made borderless placement and swap-chain sizing follow the monitor containing
  the Unreal window, including secondary-monitor origins, while preserving the
  logical and physical viewport split.
- Added 2560x1440 and 3840x2160 to the renderer's resolution list regardless of
  physical display modes and exposed Off/2x/4x/8x through the existing Video
  preferences Antialiasing row when D3D12Drv is active.
- Added automated MSAA 8x, logical 1440p, logical 4K, and logical 4K plus MSAA
  8x cases. Release builds and the Settings and MenuDisplay runtime suites
  passed; logs confirmed effective 8x at 1920x1080 and 3840x2160 on the RTX
  3060. ModernMenu compiled with zero warnings.
- Physical 4K presentation is implemented but not validated because the
  current desktop is 1920x1080 and no 4K DSR mode was active.
- Final screenshot comparison passed for the four deterministic content maps.
  `Terraniux` was changed to capture-only after retained images confirmed its
  player yaw varies between runs; `Vortex2` remains capture-only for the same
  class of nondeterminism.

### Added a fully offline side-by-side installer

- Added CMake staging and packaging targets that verify and extract the pinned
  OldUnreal 227k_15 Windows archive at build time, then embed its file tree with
  the D3D12 renderer, ModernMenu, host manifest, permissions record, installer
  engine, and generated payload hash manifest. The ZIP is not embedded.
- Added the Unreal Revived Inno Setup package that discovers Steam App ID
  13250, copies the user's game assets into `C:\Games\Unreal Revived` by
  default, applies the bundled patch, creates dedicated Unreal Revived profiles and
  shortcuts, and leaves the Steam source untouched.
- Added an **Original Game** wizard page that prefills the detected Steam path,
  permits another source folder, validates `System\Unreal.exe`, prevents a
  destination inside the source, and confirms the selection on the Ready page.
- Split original-game copying into a hidden pre-install helper, then made Inno
  install all 2,010 extracted patch files directly through its native file and
  progress system. Runtime ZIP extraction was removed; final hashes and profile
  generation remain hidden with no PowerShell window.
- Added uninstall-time backup of saves and dedicated profiles to Documents.
- Added rerun maintenance detection for machine-wide and per-user App ID
  registrations. Setup now offers uninstall-and-exit, repair/update, or cancel
  before opening the normal installation wizard.
- Removed unnecessary administrator elevation after a medium-integrity
  write/delete probe passed under `C:\Games`. Avoiding the UAC process handoff
  also prevents Setup from opening behind the previously active application;
  a fresh launch confirmed the wizard's window handle matched the foreground
  window handle.
- Set `[FirstRun] FirstRun=227` in the generated engine profile after a pristine
  patch launch exposed the otherwise active startup wizard.
- Built `UnrealRevived-Setup-0.1.0.exe`, verified the bundled patch
  and all five pinned x64 module hashes, launched the installed copy through
  `D3D12Drv.dll`, and observed a clean bind/unbind cycle without fallback.
- Completed a silent uninstall with exit code 0, confirmed save/profile backup,
  complete destination removal, and no Unreal Revived marker in the original
  Steam installation.

### Added one-command development bootstrap

- Pinned structured runtime and SDK asset URLs, sizes, and SHA-256 values in the
  host manifest and added an artifact manifest for the optional
  `UnrealRevived-DeveloperBundle-227k_15-v1.zip`.
- Added verified original-source archive acquisition with cache reuse and
  partial-download cleanup. Owner-controlled MEGA links provide manual recovery
  mirrors, while local/USB developer bundles remain optional.
- Added Steam App ID 13250 discovery, full physical runtime copying, verified
  host and SDK extraction, generated D3D12 test profiles, and a development
  marker that deployment and runtime automation enforce.
- Added idempotent prerequisite detection and automatic winget installation for
  Git, CMake, Visual Studio 2022 C++ Build Tools, and Inno Setup 6.
- Added `scripts/bootstrap-dev-environment.ps1` to compose setup, configure,
  build, deploy, and optional smoke testing from a fresh clone.
- Consolidated shared INI and integrity helpers, moved public CMake deployment
  targets into `cmake/`, excluded generated/vendor trees from VS Code indexing,
  and removed only four verified-empty obsolete scaffold directories.
- Built a 150,277,460-byte developer bundle with SHA-256
  `82AAA8E19ABB94BE648AADEAA0C8BF92026EC4CD243D8EAA52054C0AF67D6777`.
  Validated explicit-file and cache acquisition, Steam discovery, isolated
  runtime/SDK provisioning, unmarked-tree rejection, an idempotent offline
  bootstrap rerun, Release renderer deployment, and zero-warning ModernMenu
  compilation. The fresh-runtime six-map Content suite passed after profile
  stabilization, and the offline installer rebuilt with SHA-256
  `03A901E5147E40816CD2982B5EA560455DE8B14F65A7184ED4C488A47B56ABF8`.
  The generated developer bundle remains an optional local artifact.

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

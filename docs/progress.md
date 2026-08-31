# Engineering progress

This log records meaningful implementation milestones, why they were needed,
and how they were validated. Keep current behavior documented in the focused
technical guides; use this file for the chronological record.

## 2026-08-31

### Began evidence-based installer content auditing

- Added a read-only effective-runtime inventory that compares each installed
  path with the original Unreal Gold source and extracted pinned 227k_15 patch.
- Recorded per-file hashes, sizes, origin, conservative classification,
  rationale, and matching engine package or localization search path.
- Reconciled all 2,382 files and 867,626,440 bytes in the latest disposable
  runtime snapshot. Classified 150 files totaling 130,055,289 bytes as
  candidates for later reversible quarantine testing; no exclusions were
  approved or applied, and 165 unknown files remain retained by default.
- Extended runtime smoke-test failure detection to reject missing-file,
  missing-package, package-not-found, and failed-load diagnostics.
- Validated report reconciliation and representative `Maps`, `System`, and
  `SystemLocalized` search-path evidence, then passed a focused `NyLeve` D3D12
  launch with the strengthened failure detector.

### Applied conservative installer content pruning

- Added a shared tracked content manifest consumed during original-game copy
  and patch staging. It excludes historical DirectX/setup media, manuals,
  release notes, setup artwork, copied logs, source profiles, and linker cache
  state while retaining `Help/Logo.bmp`, which runtime evidence proved is used.
- Kept editor tools, 32-bit host modules, alternate patch renderers, both
  campaigns, multiplayer/server and web-admin support, all languages, and
  XOpenGL recovery pending broader feature-specific evidence.
- Quarantined the complete 150-file candidate set in a separate disposable
  runtime and passed all 26 automated content, setting, menu, and display cases.
- Applied only the conservative 102-file subset totaling 92,638,383 bytes in
  the measured source snapshot, built the filtered final tree from exact staged
  inputs, and passed all six representative content cases on that tree.

### Removed obsolete renderer payloads

- Removed 66 audited D3D7, D3D9, Glide, software, Metal, and ICBINDx11 renderer
  binaries and companion shader/cache assets from `System` and `System64`.
- Retained D3D12 as the primary renderer plus XOpenGL and standard OpenGL for
  recovery. An explicit temporary XOpenGL profile loaded `NyLeve`, completed a
  clean bind/unbind cycle, and logged no missing content.
- Passed all six D3D12 content cases before policy changes and again on a fresh
  final installation assembled through the updated copy and patch-stage rules.
- Increased the measured total exclusion set to 168 paths and 100,893,743
  bytes. The rebuilt installer is 94,207,979 bytes.
- Removed the obsolete renderer `.int` registrations that still populated
  Video Preferences and filtered their descriptions from all ten localized
  recovery files while preserving UTF-8 BOM encoding.
- Assembled a fresh final tree and verified its complete render-device
  registration set contains exactly Direct3D 12, OpenGL, and XOpenGL, with no
  stale descriptions in localized or mirrored recovery metadata.

### Removed unused x86 host and editor/setup files

- Confirmed from PE headers that all 42 direct `.dll` and `.exe` files under
  `System` are x86 and omitted them from the supported x64 installer while
  retaining all architecture-independent `.u` packages and registrations.
- Removed end-user UnrealEd/setup executables, duplicated editor resources,
  editor splash/config assets, and the original install manifest. Retained x64
  `Editor.dll` because Chizra and Dug load it during normal gameplay.
- Retained `System64/UCC.exe` and validated the actual dedicated-server entry
  point on `DmDeck16`: it bound `IpDrv`, `UWebAdmin`, and port 7778. The only
  missing package was `UnrealIntegrity`, reproduced identically in the full
  runtime baseline.
- Passed all 26 automated content, renderer-setting, menu, and display cases on
  the quarantine tree and all six content cases on a fresh policy-built final
  tree. The additional pass removes 113 paths and 31,177,744 bytes, bringing
  the measured total to 281 paths and 132,071,487 bytes.

### Standardized on ALAudio

- Retained ALAudio as the sole supported audio engine with OpenAL Soft 1.24.3,
  EFX initialization, and HRTF capability. PE import inspection confirmed its
  required codec chain includes `libxmp`, `sndfile`, `mpg123`, and
  `libmp3lame`, so all remain packaged.
- Removed deprecated Galaxy, experimental SwFMOD, FMOD Ex 4.44.57, and their
  English and localized registrations and recovery descriptions. Galaxy also
  imported Visual C++ debug runtimes, making it unsuitable as a general
  distribution fallback.
- Passed all six representative content cases on a fresh policy-filtered tree;
  every case bound `ALAudio.dll` and initialized the subsystem. This removes
  another 24 files and 2,713,159 bytes, bringing the measured total to 305
  paths and 134,784,646 bytes.

### Branded first-time configuration and shortcuts

- Added D3D12 recommendation text to all ten localized `Startup.*` files and
  set both generic default profiles to D3D12, in addition to the existing
  dedicated Unreal Revived profile defaults.
- Restored the host-required 343x84 `SetupLogo.bmp` that the content policy had
  incorrectly removed.
- Added original project-owned `Logo.bmp`, `SetupLogo.bmp`, and a seven-frame,
  16-through-256-pixel shortcut icon under the tracked `branding/` directory.
  Packaging copies these files directly and no longer derives artwork from the
  user's original installation.
- Added `scripts/build-unreal-revived-branding.ps1` as the editable,
  deterministic source for regenerating the tracked baseline artwork.
- Validated the exact 719x200 and 343x84 bitmap dimensions, all seven icon
  frames, byte-for-byte deterministic regeneration, and byte-identical staged
  copies. Rebuilt the offline installer with SHA-256
  `A1008CB9AD5452143830DDF9FE8F04E60F7E1A739DC2A7CDA404E42B90B53387`.
- Made desktop shortcut creation unconditional during install and repair, and
  changed the installed icon path so Explorer refreshes the icon instead of
  retaining a cached image from the old path.
- Completed a fresh installer run and confirmed the desktop shortcut was
  recreated with the versioned icon path, the installed icon matched the
  tracked asset by SHA-256, and uninstall metadata used the same icon. The
  corrected installer SHA-256 is
  `C647B1B449E4B9EA64B9BC30D0E43E9A2076D3930AA0E2A40920B6B91D4A9334`.
- Validated the native first-time window selects Direct3D 12. The exact engine
  localization lookup and native selection-change notification display the new
  D3D12 description.

### Unreal Revived menu background

- Replaced the inherited OldUnreal Edition menu desktop with original tracked
  Unreal Revived artwork generated as a 1280x720 source and twelve UE1-compatible
  256x256 bitmap tiles.
- Updated the ModernMenu build to stage package textures and embedded them in
  `ModernMenu.u` without changing the original Steam installation.
- Compiled 430 UnrealScript lines with zero warnings, opened the menu through
  the disposable D3D12 runtime, and captured a seamless rendered background
  with the menu and status bars intact. Rebuilt the offline installer with
  SHA-256
  `B503CD9F6EDBB9A5D321310755081CEF789E50976E9BBB55FF3BBD16490C72CF`.
- Replaced placeholder-specific mirrored edges with generic centered cover
  scaling. Native 16:9 artwork remains proportional and fills arbitrary
  viewports through predictable cropping rather than stretching.
- Added `-MenuBackgroundSource` for importing non-generated 1280x720 PNG, BMP,
  or JPEG artwork without touching other branding. Validated same-path import,
  twelve-tile regeneration, unchanged logo/icon hashes, and rejection of wrong
  dimensions before modifying the canonical background.
- Imported the supplied 1280x720 JPEG, changed tile generation to resample the
  complete image before extraction, and compiled 425 UnrealScript lines with
  zero warnings. A 1365x768 D3D12 capture filled the viewport with the source's
  original proportions and no black bars, stretching, or tile seams.
- Extended source import to accept exact 16:9 artwork and produce a 3840x2160
  canonical master. Added optional source-derived branding that crops the
  circular crest into all seven ICO frames with transparent corners and the
  lower wordmark into the 719x200 setup banner while leaving `SetupLogo.bmp`
  independent. Validated both bitmap dimensions and the complete ICO frame
  table. Rebuilt the offline installer, verified all staged branding payloads
  byte-for-byte, and confirmed its checksum sidecar matches SHA-256
  `C2A4C37AEE58DA6A97B35E814A1EA46ADC5D448ACD03AE53F17F24C670C0E374`.
- Replaced the fixed installed icon version with a SHA-256-derived filename
  carried through the payload manifest and Inno Setup definition. This gives
  every changed ICO a new Explorer cache key while install-time validation,
  desktop shortcuts, Start Menu shortcuts, and uninstall metadata all use the
  same exact asset name. Rebuilt the installer with SHA-256
  `567E256E310E9FB79B396746C134230D9A6473AF1415A11B204AB1B9D1B46203`,
  completed a silent repair, and verified the desktop shortcut, installed icon
  hash, and uninstall metadata all reference
  `UnrealRevived-Icon-1c272b56e343.ico`.
- Extended ModernMenu deployment to refresh the same tracked branding in the
  disposable runtime. Verified `local/game/Help/Logo.bmp` and `SetupLogo.bmp`
  byte-for-byte, and recreated both local development shortcuts against the
  matching hash-derived circular ICO.

### Established installer profile defaults

- Added explicit initial fullscreen, brightness, frame-rate, visual-detail,
  network, VSync, and shadow-detail preferences to the dedicated profiles
  created by the offline installer.
- Kept the preferences isolated from the original game installation and
  editable after installation.
- Validated profile generation in an ignored staged host tree and asserted all
  15 generated INI values, including the user-profile network and HUD values
  that the host otherwise creates from runtime defaults.

### Preserved installer profiles across Preferences Restart

- Replaced the development-only profile names hardcoded in ModernMenu's
  Restart action with config-backed engine and user profile names.
- Configured development deployment to retain `D3D12Test.ini` and
  `D3D12TestUser.ini`, while installer profiles use `UnrealRevived.ini` and
  `UnrealRevivedUser.ini`.
- Validated a zero-warning ModernMenu compile and asserted both development and
  production restart-profile configuration values.

### Added opt-out save preservation during uninstall

- Added an interactive **Keep save games** checkbox that is checked by default;
  silent maintenance uninstall uses the same keep behavior.
- Moved the save directory atomically outside the deletion root after the
  existing Documents backup, then restored it under the former installation
  path after uninstall so a future reinstall can reuse it.
- Preserved the timestamped Documents backup regardless of the checkbox choice
  and made backup failure stop removal instead of silently deleting user data.
- Removed forced silent flags from Setup's maintenance uninstall so the checked
  save-retention option is visible, accepted a retained save-only destination
  on reinstall, and excluded original-game saves when retained saves exist.
- Made the save-options form the sole uninstall confirmation by suppressing
  Inno's redundant prompt in maintenance and registered uninstall commands.
- Replaced the standalone options form with controls embedded in
  `UninstallProgressForm`; the native window collects the choice, then
  transitions in place to standard uninstall progress.
- Validated the reinstall copy path with an isolated sentinel save: the retained
  file was unchanged, source saves were excluded, and other game files copied.
- Validated the complete Inno Setup definition with compiler version 6.7.3;
  isolated end-to-end uninstall behavior remains to be exercised.

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
  partial-download cleanup. Explicit local archives and local/USB developer
  bundles remain available for offline use.
- Added Steam App ID 13250 discovery, full physical runtime copying, verified
  host and SDK extraction, generated D3D12 test profiles, and a development
  marker that deployment and runtime automation enforce.
- Added idempotent prerequisite detection and automatic winget installation for
  Git, CMake, Visual Studio 2022 C++ Build Tools, and Inno Setup 6.
- Added `scripts/bootstrap-dev-environment.ps1` to compose setup, configure,
  build, deploy, and optional smoke testing from a fresh clone.
- Reworked the root README as a first-time visitor guide with an honest feature
  boundary, complete bootstrap and launch paths, archive acquisition policy,
  installer behavior, safety constraints, repository map, and documentation
  index.
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

### Added reproducible development shortcuts

- Added tracked normal and recovery launchers and made bootstrap create
  `Unreal Revived.lnk` and `Unreal Revived Recovery.lnk` in the disposable
  game root.
- Kept both shortcuts marker-gated and scoped to the disposable runtime. The
  recovery launcher refuses to run while that runtime's executable is active.
- Parsed all changed PowerShell scripts and inspected both generated shortcuts
  through `WScript.Shell`; targets, profile arguments, working directories,
  icons, and current-clone paths matched the intended runtime.

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

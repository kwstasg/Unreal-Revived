# Engineering progress

This log records meaningful implementation milestones, why they were needed,
and how they were validated. Keep current behavior documented in the focused
technical guides; use this file for the chronological record.

## 2026-09-07

### Prepared version 0.5.0 installer metadata

- Increased the active installer and rebuild artifact version from 0.4.0 to
  0.5.0 while retaining the existing application identity for upgrades.
- Added Kwstasg - Kostas Giannakakis as the installer publisher and Windows
  version-information company, plus direct GitHub project, support, release,
  product-version, description, and copyright metadata.
- Rebuilt the fully offline installer successfully. The 88,405,162-byte
  `UnrealRevived-Setup-0.5.0.exe` has SHA-256
  `1CC8678256FDCEEBB0E9C68642E279F0320D3EE35F5FE8629A7B235DA1B8A643`;
  its embedded Windows metadata reports file version 0.5.0.0, product version
  0.5.0, and company `Kwstasg - Kostas Giannakakis`.

### Added project authorship headers

- Added consistent author and project URL headers to all Unreal Revived-owned
  ModernMenu, localization, automation, packaging, and build configuration
  code.
- Credited Kwstasg - Kostas Giannakakis as the Greek translation author in all
  78 Greek campaign, intermission, package, and ModernMenu localization files.
- Added the Unreal Revived Project header to the D3D12 renderer and XInput
  integration while preserving their documented provenance and excluding
  third-party sources with their own license notices.
- Rebuilt the Release D3D12 and XInput drivers, compiled ModernMenu with zero
  warnings, passed the English and Greek save-localization commandlets, and
  successfully rebuilt the fully offline 0.4.0 installer after the attribution
  changes.
- The D3D12 and supported-renderer GUI smoke harnesses remain blocked by the
  existing first-run startup-localization state: the generated profile either
  ignores the normal close request or exits at the missing
  `Startup.IDDIALOG_WizardDialog` lookup before loading the requested map. This
  is not a renderer, ModernMenu, or localization-file validation failure, but
  interactive visual checks remain required.

### Added Unreal Revived project credits

- Preserved the stock About Unreal window and all original, OldUnreal, and
  renderer credits while replacing its client with a ModernMenu subclass.
  The subclass appends a left-aligned Unreal Revived section after one empty
  row below the existing entries, with the project creator identity and
  repository.
- Made the repository credit a mouse hyperlink with hover feedback. Replaced
  the Help menu's Technical Support caption with OldUnreal and added an Unreal
  Revived item directly below it; both open their respective project sites.

### Added optional retro post-processing controls

- Added world-only vignette, animated monochrome film grain, and physical
  output-pixel CRT scanlines to the D3D12 present shader.
- Added D3D12-only 0–100% Video sliders backed by independent 0–255 renderer
  settings. All three default and reset to 0%, apply live, persist in the active
  profile, and avoid world-scene capture cost while every world effect is off.
- Built the Release D3D12Drv target successfully and compiled ModernMenu with
  zero warnings. The automated runtime harness could not pass the environment's
  first-time localization state, so final visual tuning used direct 1920x1080
  in-game comparisons supplied from the development runtime.
- Follow-up visual feedback at uncapped frame rates showed the initial
  per-present, one-pixel grain averaging into a tonal shift and the scanlines
  reading too faintly. Grain now uses two-pixel particles animated at a
  frame-rate-independent 24 Hz in display space, and maximum scanline darkness
  was increased from 65% to 90%; UI masking remains unchanged.
- Replaced the visibly tiled 2x2 grain cells and sine hash with independent
  per-pixel integer hashes, a softer two-sample particle distribution, and a
  subtle midtone response. Changed scanline spacing from alternating rows to
  one dark row followed by two clear rows so the gaps remain visible at 1080p.
- Strengthened the scanline signature after visual review: its four-row pattern
  now contains a strong line, a softer shoulder, and two clear rows, with a
  square-root slider response and 95% maximum darkening.
- Rebalanced that pattern after direct 0%/100% comparison showed excessive
  darkening: maximum multipliers are now 0.50 for the core, 0.82 for its
  shoulder, and 1.08 for both phosphor rows, limiting average brightness loss
  to about 13% while preserving a clearly recognizable scanline structure.

### Prepared release 0.4.0

- Updated installer and rebuild metadata from 0.3.0 to 0.4.0 for the
  world-only retro post-processing controls and pawn-safe BSP seam assistance.
- Completed the non-destructive full rebuild: native renderer and input DLLs,
  ModernMenu, offline installer, developer bundle, and repository guard all
  passed. The 88,412,583-byte `UnrealRevived-Setup-0.4.0.exe` has SHA-256
  `40CBD381CD07172D26C74E0B369C5682F1F10B08481AAB28249E725E4D36829A`;
  the 150,277,514-byte developer bundle has SHA-256
  `5C327EB52EDEE52E77B6BC4E8CC02A8F59F9667DD7F3B0C66C13F55A44AD3BC0`.

### Pawn-safe BSP seam assistance

- Restricted the collision-radius seam workaround to confirmed world-geometry
  obstructions after a sustained 0.08-second block. Added full-cylinder pawn
  clearance checks before shrinking and restoring the radius so UE1 pawn
  encroachment cannot gib enemies or friendly NPCs when the player presses
  against them.

### Consolidated world-only post-processing

- Replaced the earlier overlay and menu-tile inference experiments with one
  explicit `D3D12 BEGINUIPASS` boundary shared by bloom, chromatic aberration,
  and future world-only effects. Removed the old command aliases and all
  executable inference paths.
- Added distinct final-frame, world-scene, screenshot, hit-test, and R8 UI-mask
  resources. HUD tiles, 2D lines, and 2D points now mark the composition mask;
  the present pass selects untouched final-frame pixels for UI instead of
  reconstructing transparency from color subtraction.
- Added a 0–100% Chromatic Aberration Video slider backed by the renderer's
  0–255 setting, with 0 as the installer and renderer default. Normal campaign
  travel and old saves receive the boundary through `ModernGameHud`, while
  custom HUD subclasses remain untouched.
- Rebuilt and deployed D3D12Drv, compiled ModernMenu with zero warnings, and
  passed all 27 Settings-suite cases, including aberration off/max and combined
  bloom plus aberration under 8x MSAA. Evidence is under
  `local/logs/automated-20260907-150459/`.

## 2026-09-05

### Preserved established defaults across development rebuilds

- Corrected disposable-runtime generation to write the configured Unreal
  Revived system profile to both `Default.ini` and the shortcut's
  `D3D12Test.ini` instead of leaving the fallback template at stock OldUnreal
  values.
- Aligned development menu wiring, network values, and HUD defaults with the
  installed profile path, including the game-behind-menus preference.
- Forced a fresh bootstrap with in-game tests skipped. The generated system
  profiles were byte-identical, required user defaults were present in
  `DefUser.ini`, ModernMenu compiled with zero warnings, and no Unreal process
  remained running.
- Rebuilt and checksum-verified the 88,314,841-byte offline installer with
  SHA-256 `A767DF77789F1834FEE9FD5CE3CD1F5E82F5042497DD87B0315FCBCC65991DC8`
  and the 150,277,515-byte developer bundle with SHA-256
  `74AA224094F09EB532FE944281C1F216D831B26F1CF5212DA5F90A60ED3F10F7`.

### Validated bootstrap from an isolated clean clone

- Created an isolated clone with no inherited `local/downloads`, runtime, SDK,
  build, or package state, then applied the exact current tracked source diff.
- Installed Unreal Gold through the official signed OldUnreal Windows full-game
  installer and ran `scripts/bootstrap-dev-environment.ps1` with no arguments.
  Bootstrap automatically discovered `C:\Unreal`, downloaded both pinned
  OldUnreal archives into the clone, and created the runtime, SDK, and CMake
  build tree without an explicit source override or reused download cache.
- Built and deployed D3D12Drv and XInputWinDrv, compiled ModernMenu with zero
  warnings, and passed all six default content smoke cases. Evidence is under
  `local/clean-clone-validation/local/logs/automated-20260905-182719/`.
- Built the clean-clone offline installer at 88,310,390 bytes with SHA-256
  `9C1130C6F7CD29A190AD4302B5239866B9FB8B8376DBDBD6AFAAC34C78405E74`
  and the 150,277,515-byte developer bundle with SHA-256
  `1B1B82AFDAD846F4C8756BD9022EE51B6BE85B17D92705F9371FA64773FE2EF0`.
  Both checksum sidecars matched, and no Unreal process remained afterward.

### Validated a clean developer bootstrap and distribution rebuild

- Removed only the marked disposable runtime and ignored SDK, build, and
  package outputs while preserving cached verified archives and all source
  changes, then exercised bootstrap as a new developer deployment.
- Confirmed the new missing-source guard stops before toolchain installation
  and provides the OldUnreal installer URL. The previously detected Steam
  source was no longer complete, so the supported `-OriginalGameRoot` override
  was validated with an unmarked preserved full-content source.
- Fixed fresh-bootstrap smoke tests by generating `D3D12TestUser.ini` with the
  trailing blank line OldUnreal otherwise writes on its first launch. The
  original run completed all six content cases before detecting that two-byte
  normalization; a focused rerun passed, followed by a second from-empty
  bootstrap that rebuilt the runtime, SDK, native modules, and ModernMenu with
  zero UnrealScript warnings and passed all six content cases. Final evidence
  is under `local/logs/automated-20260905-181149/`.
- Rebuilt and checksum-verified the offline installer at 88,309,733 bytes with
  SHA-256 `F26229B80173BD47A66E11C672A85334B36B587C30E6E62CCC3D21A02BE573BC`.
  Rebuilt the 150,277,515-byte developer bundle with SHA-256
  `DBD0918ABB32DE1FC7AE69F09CF7E82F1CD8FB56074B608CF5AA4CCC225E4067`.

### Added guided original-game acquisition

- Extended the offline installer's source page to detect both `C:\Unreal` and
  registered Steam libraries, open OldUnreal's official full-game installer
  page when no source exists, and detect the new installation after the player
  returns without restarting Unreal Revived Setup.
- Clarified in the interactive uninstaller that removal affects only Unreal
  Revived; the source Unreal Gold installation and OldUnreal downloads remain
  unchanged. Save retention remains enabled by default.
- Compiled the complete Inno Setup package successfully with Inno Setup 6.7.3.
  The guided external-installer interaction has not yet been manually exercised.
- Aligned the developer bootstrap with the player installer: automatic source
  discovery now checks `C:\Unreal` before Steam, and a missing source reports
  the official OldUnreal installer URL plus explicit rerun and override guidance
  before developer-tool installation begins.
- Added separate player and developer README walkthroughs with links to the
  official OldUnreal full-game installer page and direct Windows installer,
  presented as three-step quick starts at the beginning of each audience section.

### Removed verified dead renderer and migration code

- Removed the unreferenced table-based half-float conversion implementation
  and reverse float conversion helpers while retaining the active inline
  half-to-float decoder used by texture upload.
- Removed the unused UTF-16-to-UTF-8 helper and the obsolete recurring cleanup
  for the retired `ModernMenu.ModernIntroTweak` server actor. No remaining
  source, project, script, or current generated-profile references were found.
- The focused Release `D3D12Drv` target rebuilt and linked successfully, and
  the updated ModernMenu build script passed PowerShell parser validation.
  A subsequent clean full rebuild completed through the new non-destructive
  wrapper, including all deployments, the offline installer, and developer
  bundle. All 41 automated D3D12 runtime cases passed, followed by all 18
  supported-renderer cases across D3D12, OpenGL, and XOpenGL. Evidence is under
  `local/logs/automated-20260905-152536/` and
  `local/logs/supported-renderers-20260905-153128/`.

### Added quiet full-rebuild orchestration

- Added a single non-destructive command that recreates only the ignored CMake
  build tree, compiles and deploys all development components, builds both
  distribution packages, verifies the expected artifacts, and runs the
  repository guard without resetting or cleaning source files.
- Redirected verbose command output to timestamped logs under
  `local/logs/rebuild/`, with an opt-in live-output mode and concise stage
  timing in the default console view.
- PowerShell parser validation passed, and the logging parameters were checked
  against the active Windows PowerShell 5.1 command surface. The underlying
  rebuild stages had completed successfully immediately before adding the
  wrapper; the wrapper itself was not used to repeat that expensive rebuild.

## 2026-09-04

### Standardized the preferred Video settings as global defaults

- Centralized the complete Video Preferences preset used by development,
  installed, recovery-derived, and packaged default profiles: fullscreen
  1920x1080, 120% brightness, 100% contrast, 120% saturation, 60% bloom,
  1.5x Gold UI, 60 minimum FPS, High textures/fog, Lightmap LOD 8, enabled
  decals/dynamic/specular lighting/weapon flash/precaching/HD textures, 4x
  anisotropy and antialiasing, and disabled VSync/trilinear/NoSmooth/flat
  shading.
- Kept pawn shadows on the blob path despite the captured Realtime Medium
  selection, preserving the Brute-encounter performance fix. Decoration
  shadows remain enabled and their draw-distance multiplier is now 8x.
- Aligned the D3D12 renderer's intrinsic fallback values and the custom slider
  reset buttons with the same preset. Existing personal profiles are not reset
  during repair, apart from the required realtime-shadow safety migration.

### Removed the Brute-encounter shadow-map stall

- Traced the renderer-independent collapse to UE227's optional realtime
  silhouette shadows, rather than Brute AI, physics, or the animated fire skin.
  During the reproduced encounter, the engine generated 20-47 full shadow-map
  uploads on each slow frame, frequently taking 20-43 ms.
- Kept shadows enabled but restored the inexpensive blob-shadow path in the
  engine profile used by new installs and disposable runtimes. Existing
  canonical profiles are migrated when the installer is reapplied. Added
  startup references for the stock Brute projectile effect graph to avoid
  first-use class and texture residency work during combat.
- On the same saved movement-and-encounter path, frames above 10 ms fell from
  149 to 3 (the remaining frames were isolated startup/streaming work), p99
  dropped from 23.854 ms to 1.716 ms, and average throughput rose from 585.32
  to 859.29 FPS. Brute projectiles, smoke, explosions, dynamic lights, decals,
  sounds, AI, physics, damage, and spawn rates were unchanged.

### Fixed D3D12 anisotropic filtering preferences

- Registered the renderer's `MaxAnisotropy` config property so the inherited
  Video Preferences control offers Off, 2x, 4x, 8x, and 16x instead of showing
  the setting as unavailable.
- Replaced the fixed sampler state with the selected, clamped value, using
  linear filtering for Off and rebuilding cached samplers when the setting
  changes. Profiles without the property use the current 4x global default.
- Added focused runtime cases for Off and 16x plus requested/effective setting
  validation. The Release renderer build and deployment succeeded, and the
  complete automated D3D12 settings suite passed, including both new cases.

### Consolidated the clean full-rebuild workflow

- Added one destructive, step-by-step guide covering prerequisite checks,
  source and build cleanup, native compilation, all development deployments,
  offline installer staging and compilation, developer bundle creation, and
  final artifact verification.
- Replaced the overlapping manual rebuild sections in the README and command
  reference with links to the authoritative workflow while retaining the
  detailed target explanations in the building guide.

### Corrected fresh mouse and recovery controller defaults

- Changed fresh development, staged installer, and installed user profiles to
  default mouse look to non-inverted while preserving existing user profiles.
- Changed development recovery to use the SDL/XInput viewport and explicitly
  reapply its controller defaults. Stock WinDrv remains available as a manual
  fallback, but no longer causes the recovery Input page to show Controller 1
  and zero dead zones because XInput-only properties are unavailable.
- Standardized development, recovery, staged, and installed input profiles on
  automatic controller selection, 25% movement and look dead zones, 85%
  movement and look sensitivity, inverted controller look, mouse sensitivity
  3, raw mouse input enabled, mouse smoothing disabled, and non-inverted mouse
  look. Controller slider reset actions and native no-INI fallbacks now use the
  same values.
- PowerShell parser validation passed for all four changed profile scripts,
  ModernMenu compiled with zero warnings, and XInputWinDrv rebuilt after its
  source patch was restaged successfully. The installed and development
  profiles passed focused value checks. Rebuilt the offline installer and
  verified both staged profile trees; the resulting installer SHA-256 is
  `7246BF13F72483CA313C0B4E8805DC5215F95C62A509A6100FF111A19482BC8A`.
  Rebuilt the developer bundle with the current permissions record; its
  SHA-256 is
  `1A68FF3CF708DBC0A60F244DAD1A525A8A6F107A7689D51BD4B31FFB3D70B107`.
  Interactive controller validation was not run.

## 2026-09-03

### Refreshed the public documentation

- Updated the README to surface the validated SDL3 controller backend, menu
  navigation, adjustable dead zones, three-binding workflow, deployment target,
  and repository location.
- Expanded the opening player guidance with the retained game experience,
  ownership and hardware requirements, side-by-side installation behavior,
  save handling, controller validation, and current limitations before the
  developer workflow.
- Replaced the README feature bullets with an organized player-benefit overview
  and added a detailed feature reference covering rendering, display, menus,
  input, content, installation, reliability, and recovery.
- Reorganized the README to lead with game features and improvements, followed
  by the preserved original experience, safe installation, and availability;
  moved technical project status under the developer section and removed the
  limitations section.
- Rewrote the introduction to explain the product, its OldUnreal 227k_15
  foundation, the Unreal Revived components layered onto it, and the hardware,
  original-game, and storage requirements for players.
- Added a supported-controller guide separating manually validated Xbox Series
  and DualShock 4 configurations from DualSense and broader SDL-mapped device
  support, with controls, features, transports, and fallback paths.
- Made the README and feature guide explicitly state that Unreal Revived
  provides no original Unreal Gold maps, textures, music, sounds, or other game
  assets and requires files supplied from the player's own installation.
- Corrected the project layout's stale XInput-only backend description and
  aligned the testing guide's focus-outline expectation with the implemented
  solid two-pixel treatment.

### Completed the three-binding workflow and optimized its menu

- Aligned keyboard, mouse, and controller binding capture around additive,
  replacement, clear, and cancel actions, with a strict maximum of three
  assignments per action and all three assignments visible after restart.
- Replaced stock per-frame Bindings layout and text rebuilding with cached,
  event-driven updates and viewport culling. Manual comparison improved the
  Bindings page from about 193 FPS to 524 FPS in the disposable runtime.
- Added focus-independent mouse-wheel scrolling to every Preferences tab;
  wheel input now hides the focus outline until keyboard or controller input
  resumes without changing the internally focused control.
- Standardized crouch defaults and the Bindings Reset action on `Ctrl`, `C`,
  and left-stick click (`Joy9`), clearing the former `Joy2`, `Shift`, and
  numpad assignments. ModernMenu compiled and deployed with zero warnings.
- Rebuilt `UnrealRevived-Setup-0.1.0.exe`; Inno Setup completed successfully
  and produced SHA-256
  `F7502A095FD78B530FDEAAAF1A980AC4C859576B72FA2888CDAD7D0B4ED1D105`.

### Added a unified SDL3 gamepad backend

- Pinned SDL 3.4.16 by release archive hash and linked it statically into
  `XInputWinDrv.dll`, with a tracked provenance and redistribution record.
- Added SDL Gamepad polling as the primary normalized source for Xbox,
  DualShock 4, DualSense, and other mapped controllers while retaining direct
  system XInput fallback and the existing WinMM recovery path.
- Preserved the existing `Joy*` bindings, radial dead-zone percentages,
  sensitivity values, trigger hysteresis, vertical inversion, raw menu axes,
  and elapsed-time-normalized gameplay axes. The focused Release target built
  successfully and deployed to the disposable runtime.
- On Windows build 19045.6466, manually validated a DualShock 4 v2
  (`VID_054C`, `PID_09CC`) over Bluetooth and USB with Steam and DS4Windows
  closed. SDL identified it as `PS4 Controller`; standard menu and gameplay
  controls behaved correctly, and both sessions ended with clean driver unloads
  and no crash signatures. Hotplug, binding persistence, and DS4-specific
  output or sensor features were not tested.
- Regression-tested an Xbox Series controller over Bluetooth and USB on the
  same host. SDL identified the transports as `Xbox Series X Controller` and
  `Xbox One Controller`; standard menu and gameplay controls, both sticks,
  D-pad, face and shoulder buttons, stick clicks, and independent triggers
  remained correct. Both sessions ended with clean driver unloads and no crash
  signatures.
- Corrected controller-loss handling to preserve held button state until Unreal
  receives release events and to submit neutral values for all six joystick
  axes. Manually validated Xbox disconnect/reconnect over USB and Bluetooth,
  switching between transports while the game remained open, and disconnecting
  while holding gameplay input. Movement and fire did not remain latched, input
  resumed after reconnection, the log captured each transition, and shutdown
  remained clean.

### Corrected Bindings capture and reset behavior

- Kept binding capture active after keyboard or controller activation releases,
  allowing the next keyboard, mouse, or controller input to be captured.
- Displayed active controller assignments omitted by the stock two-slot view,
  replaced an action's prior controller assignment when rebinding, and made the
  Reset button restore Unreal Revived's shipped controller layout in addition
  to the stock keyboard defaults.
- ModernMenu compiled and deployed successfully with 5,266 lines, 587
  statements, and zero warnings. Interactive behavior remains to be manually
  validated.

### Added adjustable controller dead zones

- Replaced the fixed left- and right-stick dead-zone checkboxes with live
  0–50% sliders, percentage labels, controller reset actions, and 24%/27%
  defaults matching XInput's standard thresholds.
- Added reflected native percentage settings while retaining the existing
  dead-zone booleans as compatibility gates. XInputWinDrv built successfully;
  ModernMenu compiled and deployed with 5,016 lines, 556 statements, and zero
  warnings.

### Restored Input checkbox alignment

- Applied the Video preferences alignment mode to the inherited controller and
  mouse checkboxes, placing every Input checkbox in the shared value column.
- Focused editor diagnostics reported no errors in the updated UnrealScript.

### Matched Input sliders to Video controls

- Updated movement and look sensitivity sliders to use the Video page's wider
  handles, live updates, inline percentage labels, aligned reset buttons, and
  controller A reset behavior. Both now reset to the aligned default of 100.
- ModernMenu compiled and deployed successfully with 4,906 lines, 554
  statements, and zero warnings.

## 2026-09-02

### Focused New Game Start by default

- Made each newly opened New Game dialog focus its Start button once after the
  stock controls are created, without stealing focus after the user navigates.
- ModernMenu compiled and deployed successfully with 4,777 lines, 542
  statements, and zero warnings.

### Adopted manually authored launch and setup banners

- Adopted the manually updated 952x295 `Logo.bmp` and resized the manual
  `SetupLogo.bmp` proportionally into the host-required 343x84 canvas.
- Deployed both files byte-for-byte to the marked disposable runtime and the
  current offline-installer staging tree. SHA-256 comparisons confirmed all
  four active copies match their tracked sources.
- Rebuilt `UnrealRevived-Setup-0.1.0.exe` with the current banners and icon.
  The latest 87,514,048-byte installer has SHA-256
  `9317781cf480fbcfde139e94526bbdff9e68cf9ea29628e4ce83a7a5212866a0`;
  its sidecar matches, and all three staged branding files match their tracked
  sources.

### Embedded controller defaults in the offline installer

- Updated offline package staging to configure `XInputWinDrv.WindowsClient`
  in both `Default.ini` templates and to write the complete Xbox button and
  stick bindings into both `DefUser.ini` templates.
- Made right-stick `JoyU` and `JoyV` look bindings explicit in installer and
  disposable-runtime profile generation instead of relying on upstream
  template values.
- Rebuilt the installer and verified both staged engine templates select
  XInput, both user templates contain the complete controller mapping, the
  packaged install script contains explicit right-stick bindings, and the
  installer checksum sidecar matches.

## 2026-09-01

### Rebuilt setup and shortcut branding from transparent PNG sources

- Replaced generated placeholder logo artwork with transparent `Logo.png` and
  `SetupLogo.png` derivatives of `branding/UnrealRevivedLogo.png`, while retaining the
  24-bit BMP compatibility copies hardcoded by the OldUnreal 227k host. Those
  opaque GDI banners are composited onto the standard Win32 wizard background
  because the host does not render bitmap alpha.
- Rebuilt the seven-frame `UnrealRevived.ico` directly from
  `branding/icon..png`, preserving source alpha instead of cropping artwork
  from the menu background.
- Added a branding-only generator mode that leaves the menu background and
  texture tiles untouched. Verified both PNG outputs use ARGB with alpha from
  0 through 255, both BMP outputs have their required dimensions, and the ICO
  contains 16, 24, 32, 48, 64, 128, and 256 pixel 32-bit frames.

### Extended controller focus across stock game dialogs

- Normalized New Game controller traversal to its visual order and admitted
  stock small buttons into controller focus. Start now uses the stock Space
  click path and successfully launches the selected campaign.
- Unified visible Save and Load slots into one ordered ring, appending Restart
  to Load. Manual controller testing confirmed traversal, wrapping, scrolling,
  and activation across New Game and Load/Save.
- Added compiled first-pass support for Advanced combo arrays, page switching,
  Start/Close ring stitching, and Mutator list selection and transfer. These
  two dialogs still need additional controller work and remain explicitly
  unvalidated.
- ModernMenu compiled and deployed with 4,742 lines, 538 statements, and zero
  warnings after the complete dialog-navigation build.

### Stabilized controller UI and frame-rate-independent gameplay

- Aligned movement and look sensitivity to independent 20–300% ranges with
  100% defaults. The XInput backend applies the same signed quadratic response
  to both sticks in the engine's expected axis units, providing finer low- and
  mid-stick control while preserving natural full-deflection output at 100%.
  Frame-time-normalized movement uses the
  host-proven `JoyX`/`JoyY` binding path, while unbound raw `JoyZ`/`JoyR`
  samples drive menu navigation. `XInputWinDrv.dll` built and deployed
  successfully; ModernMenu compiled 5,936 lines and 671 statements with zero
  warnings. Both artifacts were deployed to the disposable runtime and the
  side-by-side installed product with matching SHA-256 hashes; all current
  launch and recovery profile sections were aligned to 100% sensitivity. The
  complete offline installer rebuilt successfully with aligned 100% WinDrv and
  XInput defaults; its 88,311,277-byte executable matched SHA-256
  `46D21B23BE126F91F3367963BF1788F2EFB43AA5E51D6BAB4BB348F224CE9DC0`.
- Added exclusive message-box controller routing with immediate default focus,
  a visible gold selection outline, four-direction button cycling, A confirm,
  and B cancel. Physical controller testing confirmed the completed flow.
- Reordered Input Preferences to place Controller before Mouse and aligned all
  visible checkboxes in the same single-column pattern as Video.
- Normalized gameplay stick samples by elapsed poll time against the existing
  60 FPS feel. Physical testing confirmed consistent movement and look at about
  240 FPS with VSync and above 1000 FPS uncapped.
- Separated raw `JoyZ`/`JoyR` menu samples from normalized `JoyX`/`JoyY`
  gameplay movement. ModernConsole now suppresses dodge only while the analog
  movement stick is active, preserving keyboard double-tap dodge when centered.
  Stick movement/strafe, controller-only dodge suppression, keyboard dodge,
  and restored mouse look were manually confirmed.
- Slowed held-stick focus traversal while giving focused sliders an independent
  0.20-second initial delay and 0.04-second one-increment repeat. Physical
  controller testing confirmed smooth movement without losing fine adjustment.
- Made the current controller and mouse options explicit in installed and
  disposable profile generation. Both provisioning scripts passed PowerShell
  parser validation, ModernMenu compiled with zero warnings, and XInputWinDrv
  built and deployed successfully.

### Added modern input pages and controller menu routing

- Corrected native XInput vertical inversion so the Input page's look-invert
  option affects only right-stick look, never left-stick movement or menu
  navigation. Rebuilt and deployed `XInputWinDrv.dll` successfully.
- Replaced the stock Controls and Input Preferences pages with focused Input
  and Bindings tabs. Input exposes current mouse and XInput settings while
  hiding legacy calibration controls; Bindings preserves stock persistence and
  labels the existing `Joy*` keys as Xbox controls.
- Added controller-first UWindow routing: Menu toggles the paused menu, D-pad
  and normalized left-stick input traverse visible controls, A activates, B
  returns, and LB/RB switch Preferences tabs with wrapping. Held-stick input
  uses a 0.55 threshold, 0.35-second initial delay, and 0.10-second repeat.
- Made binding rows focusable and routed controller capture through the stock
  `ProcessMenuKey` path. B cancels capture and Menu remains reserved.
- Added on-demand pull-down recovery so A or D-pad cannot leave the menu shell
  in a controller dead state. Combo boxes support open, selection, and commit;
  A directly resets focused Video and HUD sliders without visiting their small
  mouse reset buttons.
- Built and deployed ModernMenu successfully after the completed widget pass:
  3,844 lines, 455 statements, and zero warnings. Manual Xbox controller checks
  passed for menu open/close and pause, pull-down navigation and recovery,
  combo interaction, and direct slider reset. Full binding persistence,
  gameplay mapping, hotplug, USB, and Bluetooth coverage remains pending.

### Established the side-by-side input package baseline

- Added reproducible generated-source staging for the pinned 227k_15 WinDrv
  source. The tracked patch renames package ownership to `XInputWinDrv` and
  replaces the resource compiler's optional MFC include with the Windows SDK
  equivalent without modifying files under `local/sdk/`.
- Added a CMake x64 DLL target linked against the pinned Core, Engine, and
  Window import libraries, plus a marked-runtime deployment target that keeps
  the stock `WinDrv.dll` intact.
- Configured CMake and built the `XInputWinDrv` Release target successfully.
  A temporary automation profile completed clean XInputWinDrv and D3D12 bind
  and unbind cycles.
- Added documented system-XInput loading, automatic or fixed controller-slot
  selection, reconnect scanning, radial stick dead zones, independent trigger
  events, focus resets, and WinMM fallback. Fresh generated profiles select the
  package and use a modern Xbox gameplay layout; existing profiles are not
  migrated.
- Repeated the temporary-profile runtime check with XInput enabled and verified
  that `xinput1_4.dll` loaded and controller slot 0 was detected. Physical
  controller behavior was not tested, so USB, Bluetooth, mappings, hotplug, and
  trigger behavior remain unvalidated.
- Staged the hash-verified offline payload with `XInputWinDrv.dll`; ModernMenu
  compiled 2,270 lines and 293 statements with zero warnings. The repository
  safety check passed with 120 commit candidates.

### Corrected FPS overlay scale and menu visibility

- Replaced the medium-font approximation with the large font rendered at an
  exact `0.5` canvas scale, and restored the scale after drawing.
- Added a post-`RenderUWindow` draw path so enabled statistics render above
  open menus instead of being covered by UWindow's later paint pass. This was
  subsequently moved between menu background and client painting so dropdowns
  correctly occlude intersecting statistics.
- Overrode `DrawText`'s default `PF_NoSmooth` flags for the half-scale glyphs
  and moved the overlay to a sixteen-pixel left inset for cleaner edges and
  spacing. The font scale now follows half the configured HUD scale so it can
  remain legible at 4K.
- Fixed a bloom-isolation regression caused by the overlay's Canvas reset
  leaking smoothed drawing state into subsequent menu clients. The overlay now
  restores the prior font, scale, style, color, smoothing, and Z state before
  UWindow resumes painting. ModernMenu compiled 2,252 lines and 289 statements
  with zero warnings.

### Reassigned F11 to FPS statistics

- Added a persistent `ToggleFPSStatistics` console command and changed F11 from
  brightness cycling to the statistics overlay. The command updates the same
  saved setting as the Video Preferences checkbox.
- Centralized application and persistence so F11 immediately updates an open
  Video Preferences checkbox and the checkbox performs the identical saved
  toggle behavior.
- Applied the binding through ModernMenu development deployment, installed and
  disposable runtime generation, and their customized `DefUser.ini` output so
  newly derived profiles inherit it. ModernMenu compiled 2,270 lines and 293
  statements with zero warnings.

## 2026-08-31

### Set installed brightness default to 110%

- Changed the offline install profile's `WinDrv.WindowsClient Brightness` from
  `0.500000` to `0.550000`, making the initial Video Preferences brightness
  value and active rendering default to 110%.
- Standardized the complete captured Video Preferences state across installer
  and disposable-runtime profile generation: fullscreen 1920x1080, 90-degree
  FOV, High textures and skins, 100% contrast, 120% saturation, 65% bloom,
  fixed 1.5x Gold GUI, 60 FPS target, enabled decals/dynamic/specular lighting
  and weapon flash, realtime 1024 pawn shadows, and decoration shadows.

### Simplified FPS statistics formatting

- Replaced the stock five-row raw-float TimeDemo rendering with a compact
  four-row overlay: `FPS`, `AVG`, `Low`, and `High`, each rendered to exactly
  one decimal place.
- Moved sampling into the process-wide custom console so statistics persist
  across maps and HUD classes without TimeDemo's flyby interpolation changes,
  benchmark lifecycle, per-frame RMS calculation, or stock respawn after level
  changes. The disabled Game-tab console field retains this class on Restart.
- Added rendered resolution plus once-per-second active-renderer VSync status
  rows without per-frame configuration queries. The overlay was initially
  reduced by selecting the medium font; this was later replaced with exact
  canvas scaling.

### Removed stock intro frames and failed entry lookup

- Added a minimal `ModernIntro` game class whose default HUD is
  `ModernIntroHud`, and updated normal shortcuts plus Preferences Restart to
  select it in the startup URL. This chooses Unreal Revived's HUD at player
  spawn instead of replacing `IntroNullHud` after the root window is created.
- Removed the nonexistent rotating `EntryIII.unr` entry from generated install
  and disposable-runtime profiles, preventing its failed lookup and fallback
  during affected starts. ModernMenu deployment also repairs existing local
  development profiles.
- Compiled 2,017 UnrealScript lines and 244 statements with zero warnings and
  refreshed the disposable development shortcut. Runtime visual validation was
  not run.

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
- Restored the Help menu's missing **Technical Support** caption when legacy
  localization replaces it with a separator, eliminating the consecutive
  duplicate separator without replacing the host menu classes.
- Added an intro-only HUD replacement that retains the original cinematic
  branding but omits dynamic OpenAL and PhysX driver-credit logos. Validated
  both changes in 1366x768 D3D12 captures and passed the normal `NyLeve`
  gameplay smoke case with its standard HUD path unchanged. Rebuilt and
  installed the offline installer with SHA-256
  `F064CF414E2EDBC0C85BD0A53737A3A562915E1FBB39983DDE8122854655343A`;
  the tested, staged, and installed `ModernMenu.u` hashes are identical.
- Added a transparent NVIDIA mark in the former PhysX bottom-right intro slot.
  Preserved the high-resolution official newsroom source separately from its
  generated 256x256 UE1 texture, and recorded immutable hashes, transformation,
  trademark notices, and the project owner's written-permission confirmation
  in `manifests/provenance/nvidia-intro-logo.json`. The improved source compiled
  into ModernMenu with zero warnings and rendered in D3D12 without a white box
  or opaque internal cutouts. Rebuilt and installed the offline installer with
  SHA-256
  `0BA3ADC7B5166A0470258B15EB6BD14020062A8E0AB6FC8A28C5DA816657C57E`;
  the tested, staged, and installed ModernMenu packages are byte-identical.

### Established installer profile defaults

- Added explicit initial fullscreen, brightness, frame-rate, visual-detail,
  network, VSync, and shadow-detail preferences to the dedicated profiles
  created by the offline installer.
- Kept the preferences isolated from the original game installation and
  editable after installation.
- Validated profile generation in an ignored staged host tree and asserted all
  15 generated INI values, including the user-profile network and HUD values
  that the host otherwise creates from runtime defaults.

### Added automated frame-cadence measurement

- Added opt-in D3D12 present-to-present telemetry and integrated average,
  median, p95, p99, maximum frame time, sample count, and average FPS into the
  runtime harness evidence CSV. Ordinary launches retain no sampling overhead.
- Repeated NyLeve and DmDeck16 three times at 1024x768. Both held 239.49-239.53
  FPS, p95 remained 4.40-4.46 ms, and the worst observed interval was 7.20 ms.
- Exercised the complete settings and display matrices. Bloom, 2x/4x/8x MSAA,
  2560x1440, 3840x2160, and 3840x2160 with effective 8x MSAA all retained the
  host's approximately 240 FPS ceiling; the 4K 8x case recorded 4.65 ms p95,
  4.82 ms p99, and 6.07 ms maximum over 600 measured intervals.
- Found no sustained throughput loss or material frame-time spikes in these
  static automated cases. The metric includes engine and pacing time and does
  not establish isolated GPU headroom while the host ceiling is active.
- Rebuilt the offline installer with the measured renderer; its SHA-256 is
  `99B4D0997A62091050E98F87B46CB149E43DD6A63B8E36F58428346C2F75494E`.

### Unified setup branding

- Changed source-derived branding to resize the current 719x200 wordmark banner
  into the host-required 343x84 setup logo, replacing the older independent
  Unreal Revived panel and preventing it from returning on future regeneration.
- Deployed the corrected setup logo byte-identically, compiled ModernMenu with
  zero warnings, and rebuilt the offline installer with SHA-256
  `5CEBBD32B2EED484D76BFB87440EBE1F858E56C7AA2F2B5BD97F6EAFFDB319C3`.

### Added bloom strength to Video Preferences

- Added a D3D12-only Bloom Amount slider using the renderer's native 0-255
  range. Zero disables the bloom pass; positive values enable it and persist
  both `Bloom` and `BloomAmount` in the active engine profile.
- Matched the control width, left edge, and track width to the built-in
  Brightness slider. Changed the renderer amount from blur-radius-only behavior
  to linear additive gain reaching 8x at 255 and lowered highlight extraction
  from 1.0 to 0.5 across the range, making SDR light sources visibly bloom.
- Compiled 652 UnrealScript lines with zero warnings and passed the complete
  renderer settings suite, including explicit bloom-off and maximum endpoint
  cases, without script warnings or renderer failure signatures.
- Captured bloom-off and bloom-maximum at identical NyLeve framing. Mean frame
  luminance increased from 13.90 to 16.76, with visibly broader red light spill.
- Corrected live menu behavior after runtime testing showed that `set ini:`
  persisted bloom for the next renderer initialization without reliably
  addressing the active viewport renderer. The slider now sends `D3D12 BLOOM`
  through the renderer command path while retaining the profile writes.
- Proved live updates in one NyLeve process by sending amount 0 and 255 through
  the game console. The renderer logged both transitions, captured output shows
  a broad localized halo around the ceiling light at 255, and the process
  completed a clean D3D12 bind/unbind cycle. Evidence is under
  `local/logs/live-bloom-20260831-223337/`.
- Passed all 13 renderer settings cases on the final live command, threshold,
  and gain mapping. Evidence is under
  `local/logs/automated-20260831-223509/`.
- Superseded experiment: isolated bloom extraction from HUD rendering by
  resolving the 3D scene when 227 marks the start of `RenderOverlays`, then using that world-only image as
  the bloom source while compositing over the completed frame. A same-process
  NyLeve capture retained a sharp HUD while the ceiling-light region changed by
  a mean 29.45 RGB levels between bloom 0 and 255. Evidence is under
  `local/logs/live-bloom-hud-20260831-224518/`.
- Passed all 13 renderer settings cases after HUD isolation, including 2x, 4x,
  and 8x MSAA resolve paths. Evidence is under
  `local/logs/automated-20260831-224625/`.
- Superseded experiment: added a separate inferred UWindow boundary because full-screen menus can render
  without first entering `RenderOverlays`. The renderer captures immediately
  before the first mouse-visible, no-smoothing `Z=1` menu tile. This inference
  has been removed in favor of the explicit shared UI pass. In same-process
  Escape-menu captures at bloom 0 and 255, the bright logo and menu bar had zero
  pixel difference and the full frame mean RGB delta was 0.099. Evidence is
  under `local/logs/live-bloom-menu-20260901-011229/`.
- Passed all 13 renderer settings cases and all eight menu/display cases after
  UWindow isolation, including logical 4K plus MSAA 8x. Evidence is under
  `local/logs/automated-20260901-011329/` and
  `local/logs/automated-20260901-011516/`.
- Reproduced bloom on the `Unreal.unr` intro logos and found that this
  canvas-only path did not expose the assumed native overlay marker at a usable
  renderer callback. The failed paused comparison is preserved under
  `local/logs/live-bloom-intro-20260901-012748/`.
- Added the explicit renderer UI-pass boundary and invoked it at the start of
  `ModernIntroHud.PostRender`, before all intro UI. In the corrected paused
  comparison, the NVIDIA badge had zero pixel difference between bloom 0 and
  255, **Press ESC to begin** had no changed samples, and the vendor logos no
  longer generated halos. Evidence is under
  `local/logs/live-bloom-intro-20260901-012925/`.
- Passed all 13 renderer settings cases and all eight menu/display cases with
  the explicit intro boundary, including bloom endpoints, logical 4K, and MSAA
  8x. Evidence is under `local/logs/automated-20260901-013407/` and
  `local/logs/automated-20260901-013608/`.
- Rebuilt the offline installer with the active-renderer command, final
  threshold/intensity mapping, and explicit HUD/UWindow/intro bloom isolation;
  its SHA-256 is
  `D708FE827B77E211F4EC4E8F3A24891DE13184334E2262269477A73D43893CC4`.
- Expanded the existing slider's upper range with progressive `8n(1+n)` gain,
  reaching about 6x at amount 128 and 16x at 255 while retaining the existing
  radius and extraction-threshold mappings. Same-process frozen NyLeve captures
  at 0, 128, and 255 showed a controlled midpoint, a substantially stronger
  maximum fixture halo without whole-frame washout, and sharp HUD overlays.
  Evidence is under `local/logs/live-bloom-curve-20260901-014429/`.
- Passed all 13 renderer settings cases and all eight menu/display cases with
  the expanded gain curve, including bloom endpoints, logical 4K, and MSAA 8x.
  Evidence is under `local/logs/automated-20260901-014626/` and
  `local/logs/automated-20260901-014832/`.
- Rebuilt the offline installer with the expanded bloom curve; its SHA-256 is
  `D615FA53924E5296B08A87FCB4EB08CDF97EC772C8F66619FF9D96E87058D30F`.

### Added contrast and saturation to Video Preferences

- Added D3D12-only Contrast and Saturation sliders directly below Brightness,
  matching its width and track geometry. Both expose the renderer's existing
  byte settings, show the current value, disable on other renderers, and save
  to the active engine profile.
- Added `D3D12 CONTRAST` and `D3D12 SATURATION` commands for immediate active-
  renderer updates. Frozen NyLeve captures verified maximum contrast and the
  grayscale saturation midpoint in one clean process. Evidence is under
  `local/logs/live-color-controls-20260901-020421/`.
- Runtime layout testing exposed that the stock page finalizes Brightness's
  vertical position during paint. Anchoring the custom rows during
  `BeforePaint` corrected the initial overlap; the final page shows clean
  Brightness, Contrast, and Saturation ordering under
  `local/logs/video-color-layout-20260901-021135/`.
- Foreground UI interaction changed both numeric labels, invoked both live
  commands, and persisted `Contrast=129` and `Saturation=254` in an isolated
  temporary profile. Evidence is under
  `local/logs/video-color-interaction-20260901-021247/`.
- Added isolated contrast and saturation startup cases and passed all 15
  renderer settings cases plus all eight menu/display cases, including logical
  4K and MSAA 8x. Evidence is under
  `local/logs/automated-20260901-022250/` and
  `local/logs/automated-20260901-022809/`.
- Corrected ModernMenu deployment to seed `bShowFPS=False` when the class config
  section is absent, preventing later package rebuilds or temporary-profile UI
  tests from leaving menu automation without its required source setting.
- Preserved the exact selected Contrast percentage in ModernMenu when multiple
  1% positions map to the same legacy byte renderer value. The saved percentage
  is accepted only while it still maps to the current raw value, so 115% now
  survives Preferences Restart without masking independent renderer changes.
  Focused editor diagnostics reported no errors; runtime restart validation was
  not run.
- Rebuilt the offline installer with the color controls and deployment repair;
  its SHA-256 is
  `B0F595DBEFF60A91ACC01F1796B9AE8EA01EEFE83F392269E225953F524B4B36`.

### Added optional gameplay preview behind menus

- Replaced the stock HUD scrolling client with a compatible ModernMenu wrapper
  and added **Show Game Behind Menus** below HUD Scaling. The option defaults
  off, persists in the active profile, and is explicitly seeded by deployment.
- Initially limited world preview to active gameplay HUDs. Isolated NyLeve
  profiles proved that off retains branding and on reveals the paused world,
  with clean D3D12 bind/unbind cycles. Evidence is under
  `local/logs/menu-world-preview-20260901-024749/`.
- Corrected the initial wrapper after runtime captures proved the stock HUD
  scroll client overwrote `ClientClass` from `HUDConfigWindowType`. The final
  wrapper constructs `ModernHUDConfigCW` directly; its visible layout is under
  `local/logs/hud-preview-layout-20260901-025905/`.
- Foreground UI interaction checked the option, switched the still-open HUD
  Preferences window to the paused world immediately, and persisted
  `bShowGameBehindMenus=True` in an isolated profile. Evidence is under
  `local/logs/hud-preview-interaction-20260901-030138/`.
- Passed all 10 menu/display cases with explicit gameplay-preview enabled and
  disabled profiles, including logical 4K and MSAA 8x. Evidence is under
  `local/logs/automated-20260901-030338/`.
- Rebuilt the offline installer with the HUD preview option and seeded default;
  its SHA-256 is
  `A3F840AF3254EF1ADFF56ACB2EE36497AEC15208E4BBF34369AD14E6EDFEA83B`.
- Extended the local development behavior to editor viewports, where no
  gameplay HUD exists. ModernMenu deployment now configures the disposable
  `System64/Unreal.ini` root and options menu while preserving unrelated editor
  settings; bare `UnrealEd.exe` visibly opened its editor browser and four
  viewports without the branded full-screen background. Evidence is under
  `local/logs/unrealed-menu-background-20260901-031322/`.
- Passed all 10 menu/display cases after separating always-visible editor
  viewports from checkbox-controlled gameplay and the branded intro.
  Evidence is under `local/logs/automated-20260901-031355/`.
- Rebuilt the offline installer with the synchronized ModernMenu payload while
  retaining the UnrealEd exclusion policy; its SHA-256 is
  `A58959443028E87F5202EC77EC82687428EB515ACE31BBAF23C716892101D7EA`.
- Removed the intro exception after confirming that the normal game shortcut,
  not UnrealEd, was the requested target. With the saved option enabled, the
  actual `Unreal Revived.lnk` command displayed the live `Unreal.unr` scene
  beneath its Escape menu and completed a clean D3D12 cycle. Evidence is under
  `local/logs/normal-shortcut-world-preview-20260901-032207/`.
- Passed all 10 menu/display cases with the checkbox controlling both normal
  startup/menu and gameplay paths. Evidence is under
  `local/logs/automated-20260901-032241/`.
- Rebuilt the offline installer with the normal-game preview behavior; its
  SHA-256 is
  `90101F06AB18A489384B9512BE8FB0CB218C01FB0D8EF9C901DEA7A810D72455`.

### Polished HUD and Video preference controls

- Aligned **Show Game Behind Menus** with standard checkbox geometry and made
  it checked by default for fresh profiles while preserving explicit saved
  choices.
- Replaced the Crosshair Scale and HUD Scale text boxes with tenths-based
  sliders, added one-decimal values beside their and Brightness's labels, and
  widened HUD and Video slider handles from 4 to 8 pixels.
- Added skin-matched square reset buttons beside both scale sliders. Each
  restores the Unreal Revived profile default of `1.5` in the control, label,
  live HUD, and saved configuration.
- Fitted reset buttons within the sliders' original right edge by shortening
  their tracks, then extended the same control to all six visible Video sliders with
  setting-specific defaults and existing live/persistence handlers.
- Removed the inaccurate combo arrow glyph from reset buttons. Updated fresh
  installer and development
  profiles to Brightness 0.5, GUI override at 1.5x, 60 FPS target, unlimited
  shadow distance, high-detail sky fog, MSAA 4x, and Bloom Amount 128.
- Restored vertical handle centering and matched every reset button to the
  combo arrow's 2-pixel horizontal right inset. Added fitted resets for HUD
  Layout and Crosshair Style. Compiled
  and deployed 1,380 UnrealScript lines with zero warnings. Runtime tests were
  skipped for this final alignment update at the user's request.
- Removed Color Depth and GUI Mouse Speed from Video Preferences while
  retaining their underlying host settings for compatibility. Closed both
  25-pixel row gaps, removed the mouse reset control, and compiled/deployed
  1,412 UnrealScript lines with zero warnings. Runtime tests were skipped at
  the user's request.
- Filtered the Video Driver combo at population time to Direct3D 12, OpenGL,
  and XOpenGL while preserving the inherited unavailable marker for an active
  unsupported profile. Compiled and deployed 1,459 UnrealScript lines with zero
  warnings. Runtime tests were skipped at the user's request.
- Replaced the separate fullscreen and borderless checkboxes with a single
  **Display Mode** combo backed by the host's live `GetScreenMode` and
  `SetScreenMode` commands. Fullscreen, Borderless, and Windowed selection now
  follows Alt+Enter while the page is visible. Compiled and deployed 1,556
  UnrealScript lines with zero warnings. Runtime tests were skipped at the
  user's request.
- Corrected Borderless being omitted because the inherited menu probed the
  obsolete `UseDesktopFullScreen` key. ModernMenu now derives capability from
  a valid live `GetScreenMode` response and includes all three modes. Compiled
  and deployed 1,567 UnrealScript lines with zero warnings. Runtime tests were
  skipped at the user's request.
- Added a 227-only D3D12 viewport window-procedure adapter so Alt+Enter routes
  through WinDrv's supported `SetScreenMode` command and switches between
  Windowed and Borderless, or exits Fullscreen to Windowed. Explicit Fullscreen
  selection remains available in Video Preferences. The Release D3D12Drv
  target built successfully; runtime testing was skipped at the user's request.
- Widened D3D12 saturation storage beyond the legacy byte range and extended
  Video Preferences to 200% boosted color. The menu now displays saturation as
  0% grayscale, 100% normal, through 200% boosted while keeping existing value
  255 and the reset action at 100%. The renderer clamps stale and live values to
  the non-inverted 128 through 383 range. Brightness now presents its 0.5
  default as 100%, Contrast presents its effective 10% through 400% gain, and
  both Brightness and Contrast move in 1% increments while preserving their
  existing stored formats. Bloom Amount presents 0% through 100% directly
  below Saturation. The Release D3D12Drv target built successfully, and
  ModernMenu compiled and deployed 1,619 lines with zero warnings.
- Corrected a Brightness interaction crash whose captured stack entered
  `UD3D12RenderDevice::PrecacheTexture` for `Engine.Border`: the inherited
  Brightness handler flushed renderer resources while UWindow was drawing.
  D3D12 already reads viewport Brightness every frame, so ModernMenu now saves
  the value without `FLUSH` and retains live updates. Constrained the new 1%
  control to the host's historical `0.1` through `1.0` range, displayed as 20%
  through 200%. Rebuilt the previously locked package and passed all ten
  automated MenuDisplay runtime cases.
- Added reusable supported-renderer smoke automation with isolated profiles,
  expected-module bind/unbind verification, crash-signature rejection, and
  profile-integrity checks. D3D12, OpenGL, and XOpenGL each loaded and cleanly
  shut down on NyLeve, DmDeck16, Chizra, Vortex2, Dug, and Terraniux: all 18
  renderer/map cases passed. The complete 31-case D3D12 content, settings,
  menu, and display suite also passed, for 49 passing runtime cases total.
- Rebuilt `UnrealRevived-Setup-0.1.0.exe` after renderer validation. Inno Setup
  completed successfully; the installer is 87,650,764 bytes with SHA-256
  `A0F6C38E060652C5A01E5862CE6CA1BE883E5A21BB2E82A18F3691EEA3219FEB`,
  independently matched against its generated checksum sidecar.
- Enabled continuous mouse-drag notifications for every ModernMenu Video and
  HUD slider. Values and existing live handlers now update on each changed
  step instead of only when the handle is released; keyboard behavior remains
  unchanged. ModernMenu compiled and deployed 1,629 lines with zero warnings,
  and all ten automated MenuDisplay runtime cases passed.
- Clamped Contrast to 20% through 200% in 1% menu increments while preserving
  100% neutral. D3D12 now constrains live commands and stale stored values to
  the corresponding raw 26 through 170 range before present-color correction.
  All 18 automated Settings cases passed, including minimum, maximum, stale
  raw 0, and stale raw 255 Contrast profiles.
- Tightened both Brightness and Contrast to 50% through 200%, retaining 1%
  increments and 100% neutral/default behavior. Brightness now clamps loaded
  profiles to raw `0.25` through `1.0`; D3D12 clamps Contrast to raw 64 through
  170. All 22 automated Settings cases passed, including both endpoints and
  stale low/high startup profiles for each control.
- Added a root-level focus indicator that resolves nested combo focus to the
  outer dialog control and draws a two-pixel gold outline after all menu
  children. Keyboard-only captures verified coherent outlines around an
  inherited Player Setup checkbox and the Modern Video Bloom Amount slider;
  the latter retained label, handle, and reset-button clarity. ModernMenu
  compiled and deployed 1,704 lines with zero warnings, and all ten automated
  MenuDisplay runtime cases passed.
- Refined focus rendering to a one-pixel dashed frame around type-specific
  widget geometry, excluding labels, pulldown menus, and open combo lists. A
  captured open Options menu contained zero pixels of the exact focus color,
  validating dropdown exclusion. ModernMenu compiled and deployed 1,798 lines
  with zero warnings, and all ten automated MenuDisplay runtime cases passed.
- Fixed a menu-open crash in the refined focus indicator. UWindow can
  temporarily assign keyboard focus to the root itself, but its `GetParent`
  helper assumes a caller ancestry chain that reaches the root and dereferenced
  `None` in that state. Replaced those calls with null-safe ancestry traversal.
  ModernMenu compiled and deployed 1,794 lines with zero warnings; a focused
  normal launch remained responsive after opening the menu once, logged no
  critical/script failure signature, and closed normally.
- Restored the widget focus indicator to a solid two-pixel gold outline and
  relinked the Modern Video and HUD controls into visible top-to-bottom tab
  order. Mouse-only reset buttons are excluded from keyboard traversal. Direct
  runtime captures verified Bloom advances to Override GUI Scaling and the HUD
  sequence wraps through HUD Layout and Crosshair Style to Crosshair Scale.
  ModernMenu compiled and deployed 1,910 lines with zero warnings, and the
  validation run closed normally with no critical or script failure signature.
- Made Video Driver the initial Preferences focus, clipped focus geometry to
  every visible ancestor, and opened the existing **Save Settings and
  Restart...** confirmation immediately after the driver selection changes.
  Runtime captures verified the initial Video Driver ring, complete suppression
  after a focused Display Mode scrolled outside the page, and the confirmation
  after selecting XOpenGL without applying it. ModernMenu compiled and deployed
  1,990 lines with zero warnings; the validation log had no failure signature.
- Painted the 227 viewport client black at the beginning of D3D12 initialization
  and on renderer-owned background erase requests, preventing the unrendered
  startup client area from appearing white. The x64 renderer built and deployed
  successfully, and a focused launch initialized, rendered, and closed normally.

### Preserved installer profiles across Preferences Restart

- Replaced the development-only profile names hardcoded in ModernMenu's
  Restart action with config-backed engine and user profile names.
- Configured development deployment to retain `D3D12Test.ini` and
  `D3D12TestUser.ini`, while installer profiles formerly used
  `UnrealRevived.ini` and `UnrealRevivedUser.ini`.
- Validated a zero-warning ModernMenu compile and asserted both development and
  production restart-profile configuration values.

### Added canonical argument-free installed startup

- Changed the installed product to generate canonical `Unreal.ini` and
  `User.ini` profiles and embed `ModernMenu.ModernIntro` in `[URL] LocalMap`
  and 227's `AltLocalMap`, allowing `System64\Unreal.exe` and installed
  shortcuts to start without command-line arguments.
- Added a schema-tracked migration from the former dedicated profile names,
  preserving existing preferences and timestamped safety copies while keeping
  later repair passes idempotent.
- Excluded copied source profiles from the canonical path, aligned packaged
  defaults with profile regeneration, and extended uninstall backup coverage.
- Built the offline installer successfully and verified that its staged x64
  defaults contain both direct-start URL keys while canonical profiles remain
  excluded from copied content.
- Assembled a clean isolated installation and launched `System64\Unreal.exe`
  with no arguments. The runtime log loaded
  `Unreal.unr?...Game=ModernMenu.ModernIntro`, initialized D3D12 at 1920x1080
  with MSAA 4x, loaded XInput, and created `ModernMenu.ModernRootWindow`.
- Simulated a schema-1 upgrade with customized legacy profiles and a conflicting
  canonical decoy. Migration retained the active viewport and mouse settings,
  created timestamped backups, removed legacy names, recorded schema 2, and a
  second repair left both canonical profile hashes unchanged.

### Simplified unreleased profile handling and documented commands

- Removed legacy profile migration, schema metadata, and migration-backup code
  before the first public installer release. Fresh installs and repairs now use
  only canonical `Unreal.ini` and `User.ini` profiles.
- Added `docs/commands.md` with the common bootstrap, configure, compile,
  deploy, launch, recovery, test, audit, rebuild, branding, and installer
  commands, including important prerequisites and replacement behavior.
- Rebuilt the complete offline installer successfully after the cleanup;
  Inno Setup produced `UnrealRevived-Setup-0.1.0.exe` with SHA-256
  `874DA06574CF1640247545E96D542ACB059F1032A2201E795401AF9833427C04`.
- The repository safety check passed with 129 commit candidates, and workspace
  diagnostics plus `git diff --check` reported no errors.

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

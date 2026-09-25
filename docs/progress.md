# Engineering progress

This log records meaningful implementation milestones, why they were needed,
and how they were validated. Keep current behavior documented in the focused
technical guides; use this file for the chronological record.

Historical paths below record where evidence was produced. The owner requested
removal of obsolete experiments and archived logs on 25 September 2026; many
old paths no longer exist. Current validation evidence stays under `local/logs/`
and the disposable runtime; committed milestones preserve the history.

## 2026-09-25

- Owner accepted both world/HUD horizon lock and the revised VR vignette as
  perfect on CV1 at checkpoint `232f768`. Closed both visual-acceptance tasks and
  preserved heading-only world/panel recenter plus the shared 20-40-degree maximum
  fade as the accepted baseline. Other-headset coverage remains unverified. This
  acceptance is documentation-only: no rebuild, packaging, publication or push;
  the existing installer predates this follow-up. Music edits remain separate.

- Owner confirmed the world horizon fix but reported HUD tilt and a barely
  visible VR vignette. Explicit recenter now captures heading only for the HUD
  too, keeping the panel upright at eye height without changing size/distance,
  menu transitions or natural tracking. Increased only VR angular coverage:
  maximum fade now spans 20-40 degrees off head-forward (30-50 at half strength).
  Shared stereo rays, clear center, UI exclusion, zero default and desktop falloff
  remain. Canonical renderer build, nine native suites and desktop intro/NyLeve
  smoke checks passed; deployed to `local/game` for CV1 acceptance. Evidence:
  `local/logs/hud-vignette-20260925` and `local/logs/automated-20260925-105727`.
  The existing installer predates this follow-up; music edits remain separate.

- Packaged current source through `local/build` and passed the isolated validation
  installer lifecycle after migration removal: fresh install, production fixture
  exclusion, payload/host hashes, desktop/VR startup and restart, exact backups,
  save retention, reinstall with all four profiles matching their original fresh
  SHA-256 hashes, and final removal/cleanup. Oculus 1.207.0 detected CV1 and
  initialized the session in IDLE; this is not optical acceptance. Validation
  registration, shortcuts and uniquely identified test backups were removed.
  Package: `local/package/offline-installer/output/UnrealRevived-Setup-0.8.0.exe`,
  SHA-256 `A75BEE74EB4A1176D7DF717345A4D3682E623B7708E58C42A2DB785D4EC449D6`.
  Manifest: base `d2eda30`, `sourceDirty=true`, including reviewed uncommitted
  music navigation. No publication/push. Evidence: `local/logs/horizon-20260925`.
  Save/load/travel and the separate music fixture also passed
  (`VRTravel-20260925-103024.log`, `MusicReview-20260925.log`).
  Outside-sandbox live probes verified runtime-driven per-eye dimensions at all
  four presets (`VRQuality-20260925-104222-1..4.log`); no stereo frame was submitted
  while the session remained idle. All 35 protected profile/save hashes remained
  unchanged. Removed the generated native-test tree, duplicate validation installer
  and completed test runtime after retaining evidence; canonical build/current
  package remain. Repository safety, whitespace and local Markdown links passed.

- Audited horizon lock and found full-head world-reference capture could store
  pitch/roll on startup or recenter. World capture now uses heading only, retaining
  previous heading near vertical gaze. Natural tracking, yaw transfer, authored
  cameras and the independent full-gaze HUD anchor remain. Nine native suites,
  the canonical Release build, menu compilation, gameplay regression and desktop
  preferences passed. Evidence: `local/logs/horizon-20260925`,
  `VRMotionRegression-20260925-102650.log`, `VideoPreferences-20260925-102657.log`.
  OpenXR still reports runtime unavailable (-51) in `VRQuality-20260925-102704-2.log`;
  horizon-lock and vignette CV1 optical acceptance remain pending. See
  [the audit and hardware cases](vr-horizon-lock.md). Separately reviewed the
  existing music navigation changes/fixture/docs; they remain uncommitted.

- Implemented shared head-relative VR vignette rays using runtime asymmetric FOV
  and the eye-to-head quaternion, preserving accepted desktop falloff. One slider
  controls opacity and angular coverage; at 100% the clear/faded boundaries are
  35/55 degrees off forward. HUD/menu exclusions and zero default remain intact.
  Production shader tests verify matched attenuation across asymmetric eyes,
  horizontal/vertical cant, center visibility, strength, UI exclusion and desktop
  falloff. The production pose helper is tested under head yaw/pitch and eye cant.
  Canonical renderer and menu builds, all nine native tests and desktop preferences
  passed (`VideoPreferences-20260925-011916.log`). Live VR could not initialize the
  runtime (result -51, `VRQuality-20260925-011924-2.log`); owner CV1 optical acceptance
  remains pending. Deployed to local/game; retained current logs and removed the
  temporary generated native-test build after validation.


- Completed owner-requested workspace/source/docs cleanup. Removed 143 obsolete
  local targets (2.52 GiB): alternate build, generated test builds, duplicate
  launcher runtime, old installer experiment, archived experiments/logs, exported
  investigation classes, stale test INIs and staging helpers. Preserved nine
  preview saves and three profiles under `local/user-data/retired-preview`;
  verified 31 protected data files by SHA-256. Current package, canonical build,
  SDK/downloads, maintained test sources and unrelated music edits are retained.
  Inventory: `local/logs/cleanup-20260925.json`.
- Removed unreachable quality-zero sizing/test branches. Profile-reset regression
  now uses `local/tests` and cleans its own runtime. Full canonical native build,
  nine renderer tests, two input tests and profile reset passed. The renderer
  rebuilt successfully after deleting the experimental tree. Repository safety,
  whitespace and local Markdown-link checks passed. Updated current guides to
  remove stale scene-resolution, locomotion, collision and focus-loss claims;
  historical records explicitly identify removed evidence. `pending-tasks.md`
  is the current backlog, including unresolved VR vignette stereo alignment.


- Restored the documented `local/build` workflow after development had drifted
  to a temporary build tree. Configured the canonical directory, verified cached
  dependency archives against pinned SHA-256 values, built the Release renderer,
  and confirmed both offline packaging targets are generated. Corrected the VR
  guide command and reinforced the canonical path in developer instructions,
  command reference and current-state notes. No installer was built or published.
  Evidence: `local/logs/canonical-configure.log` and
  `local/logs/canonical-renderer-build.log`.

## 2026-09-24

- Owner rejected the narrowed vignette because of excessive VR coverage and
  visible per-eye overlap. Restored the gentler accepted 0.30/0.52 maximum
  radii, with added coverage only above 50%. Retained one slider and default off;
  removed the unvalidated VR comfort suggestion from its help text. Builds and
  production shader regression passed. Deployed for CV1 revalidation; this
  reduction does not claim a shared stereo mask or resolved binocular overlap.

- At the owner's request, coupled vignette opacity and coverage across the one
  existing slider. Increasing strength progressively narrows the clear center;
  100% provides opaque outer edges, while the default remains off. Updated help
  text and documented the static image mask. Renderer/menu builds and production
  shader WARP regression passed; deployed to local/game for visual comfort review.

- Updated Multiplayer > Download Latest Update to the project releases/latest
  URL. Increased vignette edge coverage above 50%, with stronger darkening at
  100%; off/default and the lower half retain their previous appearance.
  Renderer/menu builds, production shader WARP coverage and menu-back regression
  passed (`MenuBack-20260924-203645.log`). Deployed to the disposable runtime;
  final vignette strength remains a visual preference for owner review.

- Owner accepted the controller/menu checkpoint and authorized removing the temporary
  Current profile option. Balanced (100%) is now the renderer and menu default;
  four presets remain, with internal allocation recovery retained. No migrations
  were added. Renderer/menu builds, all nine native tests and in-game preferences
  passed (`VideoPreferences-20260924-202328.log`). Other-headset hardware validation
  remains separate from this CV1 acceptance.

- Expanded OpenXR controller suggestions to Index, Vive wands, Microsoft motion,
  simple controllers and advertised Cosmos/Focus 3/HP/Touch Pro/Touch Plus profiles.
  Retained all 17 original Touch bindings and the Xbox input path. Added runtime
  profile diagnostics, isolated profile rejection and tested wand button adapters.
  Canted-eye head orientation uses runtime VIEW space with a midpoint fallback;
  parallel-eye CV1 orientation, per-eye projection and current defaults remain intact.
  Fixed B navigation through dropdowns, modal dialogs, Preferences and root. Including
  the active GUI skin in Preferences prevents its close from resetting the entire UI.
  Focus-loss stutter is closed at the owner's direction, with no further work added.
  Renderer/menu builds, nine native renderer tests, two input tests, menu-back,
  video preferences and gameplay VR motion regressions passed. Evidence:
  `MenuBack-20260924-200222.log`, `VideoPreferences-20260924-195919.log`,
  `VRMotionRegression-20260924-195926.log`. Live OpenXR could not initialize in
  `VRQuality-20260924-200029-0.log`; CV1 Touch/Xbox manual acceptance of this build
  and other-headset hardware reports remain required. See `vr-controller-compatibility.md`.

- At the owner's request, removed optional HUD/Menu Sharpness and restored its
  original texture and menu layout. Removed the Epic migration and installer
  profile-preservation branches; fresh installs seed defaults and retain saves.
  Added shared production pose-math coverage for rotated/canted eyes, coordinate
  conversion and quaternion equivalence without changing projection policy.
  Renderer/menu builds, nine native tests and in-game preferences passed.
  Profile-reset regression passed against the real installer writer in a new
  disposable directory, verifying all four profiles and unchanged saved data.
  Evidence: `VideoPreferences-20260924-142014.log` and
  `local/profile-reset-test-9bb25248e9ac49908a93e71a86840a15`.
  Other-headset hardware validation and the separate focus-loss stutter issue
  remain open; no new packaged installer or full lifecycle run is claimed.

- Saved the owner-accepted VR implementation as rollback commit `df6921c`.
  Removed Epic (saved value migrates to Ultra), fixed familiar/custom aspect
  labels, and added live opt-in HUD/Menu Sharpness with the original default.
  Runtime limits and failed allocations preserve working resources and panel
  geometry. Expanded synthetic per-eye sizing and descriptor replacement checks.
  Renderer/menu builds, all eight native tests, desktop preferences and repository
  safety checks passed. Preferences evidence: `VideoPreferences-20260924-102055.log`.
  Live OpenXR testing could not initialize the runtime (`VRQuality-20260924-102113-0.log`);
  new HUD visual acceptance and other-headset hardware validation remain pending.
  Cleaned the quality guide and current-state/testing references to distinguish
  accepted CV1 behavior, automated coverage and remaining limitations.
- Owner accepted the current CV1 development build after testing immediate VR
  quality changes, compact context-sensitive F11 statistics, bloom clipping
  correction, gaze-directed swimming/flying, and input/pitch recovery. Latest
  confirmation: mouse pitch prevention and load/remount/recenter behavior were
  tested and reported perfect. Original default quality and VR logical layout
  remain preserved. Details and regression evidence: `vr-render-quality.md`.
- Development renderer, input driver and menu builds pass; native renderer and
  input tests, menu preferences and gameplay regressions passed as recorded in
  the session. This is CV1 acceptance, not validation of other headsets or a
  published release. The separately deferred focus-loss stutter issue has not
  been claimed fixed.

## 2026-09-21

- Published [Unreal Revived 0.8.0](https://github.com/kwstasg/Unreal-Revived/releases/tag/UnrealRevived-Setup-0.8.0)
  as GitHub's latest stable release after explicit owner approval. Committed
  release source/docs as `9b8ce3a` and atomically pushed main, annotated release
  tag `UnrealRevived-Setup-0.8.0`, and the existing accepted weapon-milestone tag.
  Uploaded the exact tested installer (89,756,358 bytes) and SHA-256 sidecar to a
  draft, verified both server-reported asset digests against local files, then
  published and confirmed `/releases/latest` resolves to 0.8.0. Installer SHA-256:
  `5A00521B1F84CA25A423DD3109153C21D3BF3218A3DB02BC659764933CAEBD58`.
  No rebuild or game/runtime edits occurred during publication. The embedded
  original build record remains intact. Repository and whitespace gates passed;
  focus-loss stutter stays documented as deferred.

- The owner explicitly authorized committing, pushing and publishing 0.8.0
  after accepting the installer. Verified the exact accepted installer hash
  `5A00521B1F84CA25A423DD3109153C21D3BF3218A3DB02BC659764933CAEBD58`
  and checksum sidecar. Prepared the release notes and source for tag
  `UnrealRevived-Setup-0.8.0`. Publication uses the existing tested binary,
  retaining its original embedded base revision/dirty build record. No rebuild
  or new runtime testing is needed for this publication-only step.

- The owner tested the corrected 0.8.0 installer and confirmed "everything is
  in order". Recorded acceptance of the current 89,756,358-byte candidate,
  SHA-256 `5A00521B1F84CA25A423DD3109153C21D3BF3218A3DB02BC659764933CAEBD58`.
  Updated release/current-state notes and changelog without rebuilding or
  changing the tested artifact. Focus-loss stutter remains deferred and existing
  hardware/multiplayer limits are unchanged. This is test acceptance, not an
  instruction to publish; no commit, push, release tag or upload was performed.

- Corrected the welcome layout after the owner showed a narrowed window and
  clipped text. `WizardSizePercent=100,130` had overridden the modern width,
  and increasing window height did not expand the static welcome label.
  Set supported sizing to `120,150` and extend `WelcomeLabel2.Height` to the
  available welcome-page height. An initial height of 160 was rejected by Inno;
  the corrected value compiled. Opened only the isolated validation welcome
  screen, inspected its 612x579 capture and confirmed the one-line heading,
  all six features and final paragraph are visible. No installation was run.
  Evidence: `local/logs/release-080-welcome-layout.png` and
  `local/logs/release-080-layout-build.log`. Closed the validation preview and
  rebuilt the normal installer: 89,756,358 bytes, SHA-256
  `5A00521B1F84CA25A423DD3109153C21D3BF3218A3DB02BC659764933CAEBD58`.
  Updated release identity and checksum; game payload/settings are unchanged.

- Replaced the previous welcome copy with the owner's approved feature overview:
  modern graphics/displays, seated VR with gaze or motion-controller aiming,
  adjustable VR comfort, flexible controls and both campaigns. Removed the
  controller brand and profile count from this screen. Initially set sizing to
  `100,130`, incorrectly assuming 100 retained the modern width. Inno compilation
  passed using the existing game payload; no game behavior or settings changed.
  Current candidate: 89,756,319 bytes, SHA-256
  `FC7E2ABF472BF39E0E5C40102E4C61695FF3BAF02BD22040437D647D4E6A9E57`.
  Evidence: `local/logs/release-080-approved-welcome-build.log`. Updated the
  checksum sidecar and release record; publication remains on hold for owner
  acceptance. No visual or full installer lifecycle check was repeated.

- Updated the 0.8.0 installer welcome screen to describe Touch/head-gaze aiming,
  14 calibrated weapon profiles, optional size/position tuning, existing input
  bindings and separate desktop/VR settings. Added the installed configuration
  path and clarified that Setup leaves the original game untouched. Kept the
  existing logo and layout. Inno compilation passed using the unchanged verified
  payload; no runtime or installer lifecycle test was repeated for this copy edit.
  Rebuilt candidate: 89,756,201 bytes, SHA-256
  `B0C25769B4761B6DBADECAF3ECE22B42D2DA08F760554218AB056537FACC27B8`.
  Build evidence: `local/logs/release-080-welcome-build.log`. Updated the checksum
  sidecar and candidate identity in the release notes. Nothing was published.

- Prepared the private 0.8.0 test installer after resolving the owner's mixed
  0.8.0/0.9.0 request explicitly in favor of 0.8.0. Updated both launcher
  resources, Inno version fields, rebuild artifact checks and current build
  examples. Compared against `UnrealRevived-Setup-0.7.0`, restored its historical
  release notes, and wrote a player-facing 0.8.0 changelog covering Touch aiming,
  calibrated weapons, optional tuning, bindings, brightness and cleanup.
  Updated only comments in the shipped weapon seed; all 14 accepted profiles
  remain identical. Documented seed-only installation and the distinction from
  uninstall backups, which are not automatically restored.
  Built `local/package/offline-installer/output/UnrealRevived-Setup-0.8.0.exe`
  (89,756,267 bytes), SHA-256
  `70836D74B50DC1D84BCE9680A9D1E36EAC0A85D09F6D844C9F1B8A4A67D7F2FA`.
  Verified installer product version 0.8.0/file version 0.8.0.0, both launchers,
  every manifest payload hash, packaged calibration and fixture exclusion.
  All 30 runtime profile/save hashes stayed unchanged. Build evidence:
  `local/logs/release-080-launch-build.log` and
  `local/logs/release-080-package-build.log`. No new full installer lifecycle or
  headset test was run for this version/comment-only rebuild; owner acceptance
  remains required. GitHub main was queried at `aa5d9b2`, two commits behind local
  HEAD `988eb80`, with release changes uncommitted. Nothing was pushed, tagged,
  uploaded or published. Await the owner's explicit release approval.

- Completed the four agreed release-cleanup tasks, with focus-loss stutter
  explicitly deferred. Built the fixture-free 0.7.0 installer at
  `local/package/offline-installer/output/UnrealRevived-Setup-0.7.0.exe`
  (89,758,998 bytes), SHA-256
  `617AC96AC32EE8F4CC0640A268CEA37D57D41F4449C7D2960350E2D754A51209`.
  The same staged payload compiled with the isolated validation AppId passed
  fresh installation, component/host hashes, fixture exclusion, calibrated seed,
  desktop and VR startup, argument isolation, both Preferences restart paths,
  Old Weapons activation, edited profile/calibration preservation, uninstall
  backup integrity, save retention, reinstall and final cleanup. CV1 detection
  and OpenXR initialization passed, without claiming new visual validation.
  Evidence: `local/logs/release-package-build.log`,
  `local/logs/release-installer-lifecycle.log`, and the isolated installation
  logs under `local/tests/release-070-clean-20260921/`.
  All 30 development profile/save SHA-256 values remained unchanged; deployed
  renderer, input, loader, ModernMenu and OldWeapons match the payload. Validation
  registration, shortcuts and synthetic test backups were removed by the harness.
  Updated release/current-state documentation and removed stale acceptance TODOs.
  The production installation was not targeted, no personal backup was made,
  and nothing was committed or published. The payload records the base revision
  and `sourceDirty=true`; older same-version artifacts are not this candidate.

- Release cleanup: made console-created aim/motion hooks explicitly transient
  with `new(None)` and routed the lifecycle fixture through the production
  constructor. The earlier fixture created hooks on a different outer and did
  not exercise console ownership. Expanded it to save/load into an isolated
  temporary save directory. Repeated travel, save/load, rebinding and shutdown
  passed without script warnings or invalid owners at
  `local/game/System64/VRTravel-20260921-163258.log`; accepted firing regression
  passed at `local/game/System64/VRMotionRegression-20260921-163309.log`.
  Added a production menu build excluding all 13 test fixture sources and
  checking their names are absent from the compiled package; compilation passed
  with zero warnings. Installer staging requires this production rebuild while
  normal development builds retain regression fixtures. Reconciled stale
  renderer/weapon acceptance descriptions and documented the build split.
  Focus-loss stutter remains explicitly deferred; no firing/calibration changes.

- Audited remaining production VR logging and test reachability after removing
  the failed focus experiment. Active VR script classes have no direct `Log`
  calls; production script references to the named VR/bindings/video test
  classes were not found. The menu build nevertheless copies and compiles all
  classes, including fixtures, into its shared package. No packaging split or
  gameplay cleanup was performed during this read-only code audit. Renderer
  logging includes startup/state/error reporting and an environment-enabled
  performance sampler; retained error logging can repeat under persistent
  failures. No zero-overhead or full performance certification is claimed.
  Updated current-state and release notes with unresolved focus stutter, recorded
  saved-game hook invalid-outer warnings and the missing new installer validation.
  Automatic/runtime testing was not repeated for this documentation-only audit.

- Closed the unsuccessful focus-recovery experiment without claiming a fix.
  The owner reproduced stutter after desktop focus loss/return without F8 or
  headset removal, and confirmed the deferred-paint attempt did not help.
  Captures showed Windows `Ghost` windows coinciding with 66-78 ms draw stalls;
  that correlation did not prove the proposed paint-handling cause. Evidence
  remains in ignored `local/logs/vr-focus-reproduction-20260921/`.
  Removed the paint override, timing/process probes, diagnostic commands and
  temporary harness extension. Renderer source and runtime harness now exactly
  match `vr-weapons-validated-2026-09-21`; the renderer rebuilt and deployed
  successfully, with the deployed DLL matching the build. All 30 runtime profile
  and save-file hashes were unchanged. Removed obsolete diagnostic instructions
  and marked focus-loss stutter unresolved. No further owner captures requested,
  no unrelated code/assets deleted, and no installer built or published.

### Accepted milestone: VR weapon baseline

The owner confirmed "Everything seems perfect now" after the final Eightball
correction and requested a preserved working milestone. This establishes headset
acceptance for weapon sizing, gaze handed placement, tracked placement,
projectile/aim alignment, RazorJack alternate rotation and weapon/HUD composition.
It supersedes earlier pending visual checks for that scope; it does not close
remote-client multiplayer limitations or the recurring-stutter investigation.

Promoted the owner's latest 14 runtime profiles to the shipped seed template,
including Eightball gaze Y=20. Exact profile parity passed; existing runtime
calibration remains untouched and build/install remain seed-only. Preserved the
working source under the annotated milestone `vr-weapons-validated-2026-09-21`,
with recovery details in [the weapon guide](vr-weapon-tuning.md#accepted-milestone).
The source snapshot also retains existing controller, bindings and video work;
the milestone does not expand its visual acceptance claim to untested behavior.
The preceding zero-warning ModernMenu build and firing regression passed at
`local/game/System64/VRMotionRegression-20260921-145525.log`.
The final accepted calibration also passed at
`local/game/System64/VRMotionRegression-20260921-152645.log`. A private runtime
snapshot was initially verified across 3,819 files with SHA-256; its renderer
and input DLLs matched the existing Release build outputs. The owner subsequently
requested repository-only preservation, so that additional backup and source
bundle were removed. The milestone commit/tag and active runtime are retained;
the tag's original backup reference is historical. Future recovery uses the
tagged source and normal runtime provisioning/build steps.
Repository safety and source whitespace checks passed. No installer was built
and nothing was published as part of this local milestone.

- Extended the stock-mesh gaze handed-barrel correction to Eightball after the
  owner reported a smaller version of RocketLauncher's left/center offset.
  Right-hand calibration, motion placement and runtime INI values are unchanged.
  Reused the launcher symmetry checks for both weapons, each at its configured
  scale and a larger scale. ModernMenu rebuilt/deployed with zero warnings;
  handedness and existing firing regressions passed at
  `local/game/System64/VRMotionRegression-20260921-145525.log`. Eightball visual
  acceptance remains pending.
- Corrected stock UPak RocketLauncher gaze left/center placement for its authored
  off-center barrel while preserving right-hand calibration and motion placement.
  RazorJack now samples its live alternate-animation muzzle in both aiming modes,
  retaining the idle cache, model scale and intentional alternate-projectile roll.
  No runtime INI values changed. ModernMenu rebuilt/deployed with zero warnings.
  Launcher handed symmetry at two scales, independent RazorJack animated vertex
  measurements, actor-state restoration and existing firing checks passed at
  `local/game/System64/VRMotionRegression-20260921-144434.log`. The initial launcher
  fixture needed explicit geometry initialization before its right-hand baseline.
  The owner accepted other weapons' handed placement; these two changes still
  require headset visual confirmation.
- Made only the gaze calibration's Y component follow handedness: right uses the
  saved value, left negates it, and center adds zero Y. The shared drawing/muzzle
  helper applies the adjustment; stock center placement/roll, gaze X/Z, scale and
  motion-controller behavior remain unchanged. Preserved all runtime profile
  values and updated only the INI comments. ModernMenu rebuilt/deployed with zero
  warnings. Right/left/center offset assertions, unchanged motion calibration and
  existing firing regressions passed at
  `local/game/System64/VRMotionRegression-20260921-143605.log`. Center is a
  conservative placement trial, not forced mesh centering; headset acceptance
  remains pending. The owner reported excellent projectile/aiming alignment,
  especially in motion mode, before this gaze-only adjustment.
- Audited the expanded firing paths and removed repeated native state-function
  resolution from steady-state firing with a map-scoped class/state/function
  cache, including negative results. Added an authority guard without modifying
  RPCs, replicated fields or stock server firing. Added explicit AutoMag/Minigun
  alternate-state, QuadShot four-pattern and gaze/motion blocked zoom/reload checks,
  plus a loopback listen-host variant of the existing regression. ModernMenu built
  and deployed with zero warnings (15520 lines, 1659 statements). Standalone
  coverage passed at `VRMotionRegression-20260921-141623.log`; listen-host coverage
  passed at `VRMotionRegression-20260921-141809.log`, under `local/game/System64/`.
  The latter measured 10,000 function lookups at 15.625 ms cached versus 35.156 ms
  native; this is a microbenchmark, not an FPS claim. Map travel/shutdown passed at
  `local/game/System64/VRTravel-20260921-141929.log`.
  Remote clients remain an explicit limitation: stock movement packets contain no
  tracked/calibrated muzzle position, so equivalent remote VR firing cannot be
  claimed under the unchanged-network constraint.
- Corrected a weapon/HUD mask bug relevant to the reported UPak skin holes:
  opaque color ignores texture alpha but the previous coverage mask used it.
  Added an opaque-weapon coverage flag so surviving opaque/masked pixels fully
  occlude HUD without changing genuine blended effects, invisible polygons or
  texture assets. Renderer built/deployed; the production-shader WARP pixel test
  passed opaque-zero-alpha, masked discard/survival, blended-effect and unchanged
  UI-alpha checks. VRFoundation startup passed under
  `local/logs/automated-20260921-141833/`; the headset session stayed IDLE, so actual
  UPak visual confirmation remains pending. The owner's calibration INI was not
  modified during this audit.
- Extended gaze shot routing and guarded resting-mesh muzzle references to all
  14 stock/UPak profile families, preserving the owner's newly calibrated scales
  and offsets. Added exact stock spawn adapters for Eightball volleys, both UPak
  GrenadeLauncher states, RazorJack primary and UPak RocketLauncher; standard
  hitscan/projectile paths keep their original code. Active VR shots follow the
  computed aim ray instead of legacy auto-aim deflection. Reload, zoom and existing
  remote-grenade detonation bypass muzzle blocking. Multi-barrel weapons use a
  shared muzzle reference; Eightball retains angular spread/counts but no longer
  uses its body-relative randomized spawn ring. Stock replacement-mesh fallback,
  physical sizing and AutoMag grip placement remain intact. QuadShot handed meshes
  required front-face measurement because their vertex ordering differs.
  ModernMenu rebuilt/deployed with zero warnings (15394 lines, 1653 statements).
  Full focused regression, including actual saved gaze tuning, mirrored meshes,
  shot origins/directions, charged/alternate shots, volleys and hitscan traces,
  passed at `local/game/System64/VRMotionRegression-20260921-140546.log`.
  Reload/removal passed at `local/game/System64/VRReload-20260921-140619.log`;
  map travel/shutdown passed at `local/game/System64/VRTravel-20260921-140630.log`.
  No headset visual acceptance, animated sockets, complete campaign or multiplayer
  validation is claimed. Only the runtime INI's outdated coverage comment changed.
- Replaced profile `GazeScale`/`MotionScale` with one per-weapon `Scale` at the
  owner's request. Both modes read the same multiplier; offsets remain separate.
  Converted all 14 source/default and current disposable runtime profiles,
  preserving the owner's sizes (1.0, 1.1, 1.25, 0.85 for the first four) and every
  offset. Older external profiles need explicit field conversion; no legacy
  scale aliases or automatic averaging remain. Updated fixture profiles and
  assertions for shared sizes with independent offsets. ModernMenu compiled and
  deployed with zero warnings. Weapon regression passed at
  `local/game/System64/VRMotionRegression-20260921-103659.log`; live shared-scale
  reload/profile removal passed at `local/game/System64/VRReload-20260921-103714.log`.
- Performed a behavior-preserving cleanup of the recent VR weapon work: renamed
  the stock barrel regression helper to describe its assertions, corrected the
  shared-sizing module comment, removed stale personal tuning values from the
  current guide and tidied documentation wrapping. No gameplay statements,
  calibration constants, profiles or compatibility paths changed. ModernMenu
  compiled/deployed with zero warnings (14607 lines, 1603 statements, unchanged
  counts). No runtime tests were run for this naming/documentation-only cleanup.
- Addressed the reported low DispersionPistol projectile origin with measured
  stock barrel landmarks in both VR modes. Sampled all five idle forms: the
  first two use front-opening vertices 2/13/10/11 and later forms use the extended
  barrel pair 29/156, guarded by mesh identity and the 195-vertex layout. Power
  upgrades refresh only the cached muzzle, preserving existing size and offsets;
  sampling restores live mesh, rotation and animation. User INI values were not
  changed. ModernMenu compiled/deployed with zero warnings. Runtime regression
  passed at `local/game/System64/VRMotionRegression-20260921-021026.log`, covering
  all power-level landmarks, cache updates and state restoration, plus existing
  primary/charged origins in forced motion and synthetic gaze (errors under
  0.001 game units). Headset barrel alignment still requires user confirmation.
- Corrected the reported low Stinger shots and ASMD beam/ball misalignment in
  both aiming modes. Stock Stinger/ASMD muzzle geometry now uses measured barrel
  landmarks from the pinned resting meshes instead of whole-mesh centre/bounds;
  identity and vertex-count checks preserve fallback behavior for custom meshes.
  The original size, grip and user offsets are untouched, and animation state is
  restored after measuring. Extended the gaze firing scope to ASMD and compensated
  its stock ProcessTraceHit visual offset multipliers (Y 3.3, Z 3) only inside VR
  firing, forwarding to original hit/effect code with an explicit re-entry guard.
  ModernMenu built/deployed with zero warnings. Final runtime regression passed
  at `local/game/System64/VRMotionRegression-20260921-020150.log`: ASMD ball/beam
  origins within 0.001 game units of the calculated muzzle in forced motion and
  synthetic gaze, unchanged desktop beam offsets, stock landmark calibration,
  animation restoration and existing weapon regressions. Signature commandlet
  passed at `local/game/System64/VRMotionSignatures.log`. Preserved the owner's
  latest INI scales/offsets (including Stinger 1.25 and ASMD 0.7). Visual barrel
  alignment in the headset remains to be confirmed; no live headset session or
  complete damage/combo gameplay acceptance was performed.
- Fixed the underlying gaze/motion size inconsistency: both paths now use the
  existing weapon-family physical geometry baseline. Equal profile multipliers
  produce equal model scales without a matching option. Preserved motion sizes
  and offsets; converted the disposable runtime's first three gaze multipliers to
  1.20, 1.00 and 1.26, matching their motion entries. Their previous rounded gaze
  sizes change by less than 0.31%; other neutral gaze weapons now use the same
  physical baseline as motion. No installed profiles were migrated automatically.
  Expanded the regression to all 14 stock/UPak profile classes, two Old Weapons
  subclasses, and a custom weapon with changed mesh/view scale. ModernMenu
  compiled/deployed with zero warnings; the regression passed at
  `local/game/System64/VRMotionRegression-20260921-012101.log`, including existing
  projectile/refire checks. This proves the shared sizing calculations, not full
  mutator/Return to Na Pali gameplay or visual barrel alignment. Documented those
  boundaries and the migration requirement for older gaze multipliers.
- Removed the temporary automatic matching option completely at the owner's
  request: config property, reload handling, averaging, override argument, and
  source/runtime INI entries. Gaze now directly applies its own multiplier without
  looking up motion geometry; motion applies only its own multiplier. Retained
  the rounded direct calibration and all offsets. Replaced the midpoint regression
  with checks of independent scale application through production helpers.
  ModernMenu compiled/deployed with zero warnings; the focused weapon regression
  passed at `local/game/System64/VRMotionRegression-20260921-011528.log`.
- At the owner's request, disabled automatic gaze/motion size matching in the
  disposable runtime and set direct two-decimal scales: DispersionPistol
  3.33/1.20, AutoMag 3.69/1.00, Stinger 2.25/1.26 (gaze/motion). Preserved all
  offsets and other profiles. Arithmetic against the measured baselines gives
  mode-size differences of 0.192%, 0.194% and 0.306%; no game launch or rebuild
  was needed. Updated tuning guidance to reflect the direct-value approach.
- Follow-up to recurring F8 stutter and removing/replacing the HMD: moved session
  transition polling out of per-eye Unlock to the existing viewport frame
  boundary. This prevents STOPPING from ending a session before its pending
  stereo frame finishes. The prior game log showed STOPPING/IDLE followed by
  `xrEndFrame` result -16, but recurring-stutter causality remains unproven.
- Added optional `bMatchGazeAndMotionSize`: arithmetic midpoint of the two actual
  model draw scales, used in both modes without rewriting profile values or
  offsets. Enabled only in the owner's tuned disposable runtime; template default
  remains False. Measured DispersionPistol 4.485000/3.185136 -> 3.835068, AutoMag
  4.255000/4.235294 -> 4.245147, Stinger 4.887500/3.898073 -> 4.392787.
- Corrected projectile origins through a temporary FireOffset/view scope around
  stock firing functions; the previous final CalcDrawOffset hook was not entered
  by actual stock projectile calls. Gaze DispersionPistol/Stinger now share their
  rendered placement calculation, with head-center translation available between
  eye draws. Aim hooks avoid applying tracked rotation twice within that scope.
  Pinned script state-function lookup returned incorrect objects, so a narrow
  native SDK field resolver supplies exact state targets. Charged DispersionPistol
  and Stinger's five-shot alternate burst retain original stock implementations.
- Release renderer and ModernMenu built/deployed. Final motion regression passed
  at `local/game/System64/VRMotionRegression-20260921-010657.log`, covering actual
  primary/charged/burst origins, stock spread, exact state binding, restored
  offsets/view, shared sizes and existing refire/geometry checks. Primary origin
  errors were below 0.001 game units. Signature commandlet passed at
  `local/game/System64/VRMotionSignatures.log`; reload and map travel passed at
  `VRReload-20260921-010710.log` and `VRTravel-20260921-010724.log` in the same
  directory. All three renderer CTests passed. VRFoundation passed at
  `local/logs/automated-20260921-010740/`; Oculus remained IDLE. Exact barrel
  alignment (bounds-derived muzzle), headset on/off recovery, perceived matched
  sizes and recurring stutter still require live headset confirmation. Repository
  safety check passed with 304 commit candidates.

- Investigated intermittent stuttering reported after F8 `ReloadVRWeapons`.
  Reload has no recurring timer or file polling. Reuse the live tuning object
  instead of allocating a replacement on every successful reload, and invalidate
  resolved class matches even when the profile count is unchanged. The existing
  live edit/removal regression now checks object identity and passed at
  `local/game/System64/VRReload-20260921-002041.log`. This removes allocation
  churn; it does not establish the cause or resolution of the periodic stalls.
  The prior session log also contained configuration-triggered WinMM messages
  and headset stop/restart events, without timing evidence linking them to stalls.
- Implemented weapon-over-HUD composition for gaze and motion aiming. Weapon
  coverage occupies the second channel of the existing composition mask.
  Eye-specific slices of one UI swapchain preserve the shared panel's pose,
  dimensions, canvas and input coordinates, while hiding covered UI pixels.
  Invisible polygons do not occlude; collision fade keeps the recovery UI visible.
  Explicit shader resource registers prevent the UI-only compiler variant from
  shifting the mask binding after removing unused world textures.
- Renderer Release build/deploy and ModernMenu compilation passed. All three
  renderer CTests passed, including the new production-shader WARP pixel test
  for occlusion, asymmetric-eye mapping, out-of-view rejection and premultiplied
  alpha. Final VR startup/config/desktop-override checks passed at
  `local/logs/automated-20260921-002843/`. Corrected the harness's obsolete
  requirement for a desktop-fallback message after successful VR initialization.
  Oculus remained IDLE during automation: headset overlap, recenter, menus,
  collision recovery and sustained stutter reproduction remain manual checks.
  Deployed only to the disposable runtime; preserved the tuned weapon INI.

## 2026-09-16

- Renamed the unpublished 0.6.2 candidate to 0.7.0 at the owner's request.
  Updated launcher/installer versions, build artifact references and release
  links. Retained the earlier tag and validation record as historical evidence.
- Rewrote the changelog and release notes for players: explain seated height,
  world-size direction and examples, collision-fade recovery, classic weapon
  sounds and the purpose of the pawn-shadow change. Keep internal build and
  regression details in engineering records.

## 2026-09-15

- The owner validated VR head-collision fade: leaning into walls, corners and
  low ceilings fades normally to black and retreat restores the view. A door,
  world-size adjustments, swimming in water and an elevator also behaved
  normally. Record acceptance for these scenarios; this does not establish
  exhaustive custom-map/trigger coverage or complete swimming-control support.
- The owner accepted the signed height-slider fix after the installed UWindow
  rounding implementation trapped analog-stick adjustments at the minimum.
  The regression commandlet passed traversal in both directions across the
  full range, clamping, negative rounding and reset to zero.

## 2026-09-12

- After confirming the replacement release works, the owner explicitly rejected
  retaining rollback copies. Removed all project backup snapshots, obsolete
  installer archives and the temporary local rollback Git reference. Preserved
  the current published installer, active runtimes and normal Git history;
  updated `AGENTS.md` so future cleanup follows this retention policy.

- The owner installed the branded-executable candidate and confirmed desktop
  and VR work as expected. Preserved that exact installer and payload under
  `local/backups/release-0.6.0-user-tested-20260912/` for rollback.
- Reviewed the native hosts, separate profiles, installer copy recovery and
  unchanged maintenance flow for release. Release preparation captures these
  changes in Git, rebuilds from committed source, and records artifact identity
  and validation in the canonical installer output directory. Publishing is
  a separate action; clean-PC coverage remains outside the local evidence.

## 2026-09-11

### Freeze the accepted 0.6.0 feature set for release

- User accepted all current behavior, including recenter bindings and the final
  proportionally drawn logo, and requested release preparation with new features
  deferred. This supersedes pending user checks in earlier entries.
- Reviewed implementation and provisioning changes without altering accepted
  runtime behavior. Retained useful diagnostics and historical investigation
  notes; corrected stale current-state and contributor instructions.
- Promoted seated OpenXR VR in the end-user README and prepared release notes
  describing the validated Rift CV1 scope and remaining compatibility work.
- Native Release build, both focused VR CTest suites and all 50 runtime regression
  cases passed (`local/logs/automated-20260911-123854/`). Source checks and changed
  PowerShell syntax checks passed. Fresh offline installer packaging follows
  this frozen source commit; publication remains a manual action by the owner.

### Quick recenter bindings and flyby branding

- Follow-up: user found the logo squeezed. The intro now uses
  `branding/UnrealRevivedLogo.png` directly as its build source, packed into an
  import-compatible texture. Drawing restores the original 2168:725 aspect at
  256 canvas units wide, bottom-centered and fully within the canvas. This
  supersedes the original 256x64 replacement rectangle described below.
- Preserved the headset-accepted baseline in commit `791d54f` before this work.
- Added `RecenterVR`, calling the same renderer command as Preferences. Defaults
  are right-stick click (Joy10) and F10; Preferences > Bindings has a VR group
  for changing them. Menu input handles binding capture before recenter, so
  assigning a key does not recenter. Outside VR the action has no view effect.
- New runtime/installer defaults and Restore Defaults include both keys. Local
  profiles were updated; ordinary menu rebuilds do not reapply these bindings.
- Replaced the flyby flame layer and old logo with the existing transparent
  Unreal Revived campaign artwork in the old 256x64 rectangle at
  `(ClipX/2-128, ClipY-52)`, shared by desktop and VR.
- ModernMenu compiled with zero warnings. Desktop flyby/gameplay smoke passed
  in `local/logs/automated-20260911-120942/`; changed provisioning scripts parse.
  Screenshot capture could not obtain window bounds. Visual logo acceptance,
  headset/button and rebinding checks remain manual. The earlier local installer
  does not include these additions.

### Recenter pitch/roll and UI output encoding correction

- User subsequently headset-validated both corrections: perfect and exactly as
  requested. This supersedes the pending headset check below and establishes
  the accepted baseline before recenter bindings and intro logo replacement.
- User accepted yaw recenter but reported opposite apparent pitch/roll. The
  panel was intentionally room-upright, so head tilt remained visible relative
  to it. Explicit view recenter now captures full head orientation once. Initial
  placement stays upright, and menu transitions still do not move the panel.
- Found the sRGB output conversion nested inside the world-only shader branch.
  Moved it outside that branch so VR UI receives the same conversion before
  writing to an sRGB target. No alpha, opacity or color tuning was introduced.
- Renderer build and four present-shader variants compiled; desktop flyby and
  gameplay smoke passed in `local/logs/automated-20260911-115013/`. Previous
  runtime renderer backed up in `local/vr-recenter-color-20260911-115013/`.
  Headset confirmation of orientation and colors remains pending.
- No resolution override was added. A VR-only logical canvas would require
  coordinated layout, clipping and input work; retain the validated 1280x1024
  setting meanwhile. The earlier installer predates these two renderer fixes.

### Accepted locomotion and VR polish follow-up

- User accepted forward/back/strafe while looking 90 degrees left/right and
  right-stick turning while walking. The movement implementation is preserved.
- Removed the startup checkbox at user request; Preferences Restart preserves
  the requested shortcut mode. Recenter now also levels software pitch/roll and
  refreshes the tracking reference while preserving current horizontal gaze.
- VR-only UI textures now allocate only when OpenXR rendering is ready. Shared
  panel sizing remains unchanged; geometry tests verify upright orientation and
  source aspect preservation.
- Renderer/menu builds, panel unit tests, desktop flyby/gameplay smoke and VR
  startup/fallback smoke passed. Active headset recenter/allocation, interactive
  restart and installed shortcut checks remain pending.
- README and setup welcome advertise current VR support. Fresh local installer:
  `local/package/vr-preview-20260911/output/UnrealRevived-Setup-0.6.0.exe`.
  Both desktop icons have independent checkboxes. No release was published.

### VR audit, first gamepad locomotion step, and explicit mode shortcuts

- Added headset-yaw left-stick movement after input shaping, preserving magnitude
  and axis speeds. Kept raw menu axes and desktop input unchanged. Right-stick
  pitch is suppressed for the first-person VR walking/falling path; yaw remains
  smooth body turning. Swimming/flying and custom aliases remain native.
- Found and removed a missed script-side recenter in `LaunchUWindow`. The existing
  shared-panel renderer and layout are unchanged.
- Added normal/VR installer shortcuts with independent desktop checkboxes and
  explicit `-novr`/`-vr`; updated development shortcuts and startup checkbox help.
- Corrected plan/configuration/roadmap contradictions. Recorded the remaining
  non-VR texture-allocation overhead, restart-mode behavior, and incomplete
  comfort/movement/runtime coverage in [the audit](vr-audit-2026-09-11.md).
- Release input/menu builds and portable direction/magnitude tests passed.
  Input smoke evidence: `local/logs/automated-20260911-021246/`; desktop flyby/
  gameplay: `local/logs/automated-20260911-021251/`. Installer source compiled
  with Inno Setup using the existing staged payload into ignored validation
  output; no installer was installed or published. Actual checkbox interaction
  and headset/gamepad acceptance remain pending.

## 2026-09-10

### Accepted milestone: consistent VR HUD, menus and UI

The user accepted the final shared-panel implementation and requested it be kept,
cleaned, documented and committed without publishing a release. This acceptance
supersedes the pending-headset notes in the chronological entries below.

- Complete existing desktop-like UI now fits the VR source canvas. Symmetric
  canvas projection fixes the original pre-composition shift/clipping; OpenXR
  alone supplies asymmetric eye projection for the completed panel.
- HUD/menu/intro share an upright eye-level anchor and identical dimensions.
  Menu transitions do not recenter or resize. Distance and scale are independent;
  slider updates retain the anchor and Recenter is explicit.
- Removed experimental root scaling/input remapping, HUD/intro offsets,
  per-layout geometry/state and redundant script mode dispatch. Kept working
  composition, game/UI boundaries, preferences, localization and desktop behavior.
- Consolidated [best practices](vr-ui-recovery-design.md), archived failed
  approaches, and corrected obsolete spatial UI/recenter claims in focused docs.
- Preserved pre-cleanup accepted files/binaries in ignored
  `local/backups/vr-ui-accepted-milestone-20260910-212645/`. No release, tag, installer or
  distribution artifact is part of this milestone commit.
- Final cleanup validation: ModernMenu rebuilt/deployed with zero warnings;
  desktop flyby/gameplay smoke tests passed in
  `local/logs/automated-20260910-213012/`. User profiles preserved; repository
  safety and whitespace checks passed. Final cleanup removes equivalent mode
  dispatch only, without changing the headset-accepted geometry or projection.

### Shared VR panel geometry and explicit recenter

- User accepted the desktop-like VR layout. Preserved that renderer/menu in
  `local/backups/vr-ui-before-shared-panel-20260910-211221/` before the follow-up.
- HUD/menu/intro now use identical dimensions and placement, with no automatic
  recenter on menu transitions. Removed HUD-specific vertical offset and width.
- Anchor is upright at eye level, using horizontal heading only. Initial session
  setup and explicit Recenter establish it; sliders retain it.
- Decoupled physical size from distance. The default menu size is preserved at
  1.75m/100%; moving to 3m reduces apparent width from 64 to approximately 40
  degrees instead of enlarging the panel to compensate.
- Release build/deployment and flyby/gameplay smoke checks passed
  (`local/logs/automated-20260910-211332/`). Headset comfort and transition checks
  remain pending. No changes to the accepted canvas projection or logical layout.

### Match VR source layout to the supplied desktop reference

- Removed the root menu's 70% shrink and partial inverse pointer mapping, intro
  shrink/offset, and gameplay HUD inset/downward shift/scale override. Existing
  GUI/HUD layout now spans the full source canvas in VR as on desktop.
- Kept console messages/statistics inside the matching VR canvas pass and
  restored desktop HUD scaling for translator/MOTD. Preserved renderer projection,
  stable anchor controls, physical panel geometry, and eye-space weapon/crosshair.
- Backed up scripts, menu package, and settings in
  `local/backups/vr-ui-before-layout-20260910-210020/`. Built/deployed ModernMenu with zero
  warnings; flyby/gameplay smoke tests passed in
  `local/logs/automated-20260910-210145/`. User settings retained.
- Headset comparison and mouse/controller alignment still require visual testing.

### Full menu visibility confirmed; stabilize VR preference sliders

- User confirmed the complete menu is now visible in the headset after the
  canvas projection correction. Preserved this source and runtime binaries in
  `local/backups/vr-ui-visible-20260910-205225/` before further changes.
- Removed implicit recenter from distance/scale commands. Panel position is
  derived from a saved head reference and current distance; scale changes size
  around the panel center. Explicit recenter and layout transitions still work.
- Release build and local deployment passed. Headset slider validation remains
  pending; retained projection, root scaling, HUD margins, and opacity unchanged.
- Supplied captures show the remaining 70%-width, left-aligned menu region.
  Recorded it for the next logical-layout correction, separate from anchor work.

### VR UI source audit and isolated projection correction

- Preserved the existing dirty files and runtime binaries under ignored
  `local/backups/vr-ui-recovery-20260910-204146/`; no blanket rollback or commit.
- Found that the working renderer differed from `f767139c`: slider commands
  invalidated the anchor again and menu width was changed to 64 degrees.
- Found a separate source-space defect: Canvas vertices derived from symmetric
  game FOV were projected through asymmetric headset FOV inside the VR UI pass.
  Selected matching Canvas projection during that pass, with batch flushing
  and eye projection restoration on exit. All other layout boundaries stay fixed.
- Release renderer build/deployment and desktop flyby/gameplay smoke checks
  passed. VR launch checks fell back with OpenXR result -51; actual headset
  placement is unverified. No claim of full UI recovery or desktop visual acceptance.
- Recorded retained features, outstanding regressions, coordinate ownership,
  and ordered acceptance gates in [the recovery design](vr-ui-recovery-design.md).

### Corrected the VR UI recovery baseline

- Testing showed that bare commit `9dc4802` did not reproduce the previously
  visible menu. The earlier claim that it was the visual baseline was wrong.
- Recovered the exact uncommitted 11:44 implementation from Git tree
  `f767139c`. This is the user-validated state where the menu was visible but
  stretched/clipped, slider changes no longer moved the anchor, distance was
  weak, and logos were absent.
- Restored only that snapshot's implementation files while retaining the VR UI
  failure record. Later raw-mirror, per-eye, depth, tile-count, alpha, dynamic
  swapchain, and combined layout experiments remain excluded.

### Restored the last visible VR menu baseline

- Reverted the unsuccessful VR menu, panel, logo, and preferences experiments
  to commit `9dc4802`, the last state where useful menu content was visible in
  the headset, although still too small and partially clipped.
- Removed the two experimental VR preferences classes, rebuilt and deployed the
  Release D3D12 renderer and `ModernMenu`, and compiled UnrealScript with zero
  warnings.
- Recorded confirmed headset observations, failed and inconclusive experiments,
  invalid mirror-based diagnostics, and strict isolation rules in
  [vr-ui-investigation.md](vr-ui-investigation.md).
- No further headset experiment was performed after restoring the baseline.

## 2026-09-09

### Added stable render-only VR weapon following

- Composed the relative headset rotation into `ViewRotation` only while the
  existing first-person weapon overlay renders, then restored gameplay state.
  Scripted cameras, player aim, locomotion, and right-stick behavior therefore
  remain authoritative and unchanged.
- Exposed the tracked head-center translation separately from the per-eye
  offset and applied it to the temporary weapon view offset. The weapon follows
  forward/backward and left/right leaning without inheriting IPD twice.
- Added a conservative VR-only placement adjustment that moves each weapon
  farther forward, lower, and toward the configured hand while preserving its
  authored per-weapon offset.
- Live headset validation confirmed stable weapon placement through all head
  movements, correct left/right lean following, believable stereo depth,
  preserved scripted flybys and controls, and unchanged stereo fusion and
  distortion-free tracking.
- Fine weapon distance, scale, and lower-right placement tuning is deferred.
  Crosshair gaze alignment and actual firing direction remain separate future
  stages and are not implemented by this render-only milestone.
- `ModernMenu` compiled with zero warnings. The flat-screen Content and Input
  suites passed under `local/logs/automated-20260909-180738/`,
  `local/logs/automated-20260909-180839/`,
  `local/logs/automated-20260909-182044/`, and
  `local/logs/automated-20260909-182142/` across the head-follow and final
  placement revisions.

### Reached stable distortion-free OpenXR stereo rendering

- Replaced the shared monoscopic headset image with two independently culled
  UE1 camera passes using the runtime's eye poses, IPD, asymmetric FOV, frame
  timing, and 1344x1600 Oculus Rift CV1 swapchains.
- Extended the authoritative `PlayerCalcView` bridge with per-eye position and
  seated head translation while preserving the original scripted camera as the
  gameplay base. Live validation confirmed correct initial direction and
  natural yaw, pitch, and roll without the previous black visibility gaps.
- Diagnosed an asymmetric vertical-projection error hidden by ordinary
  symmetric flat-screen projection. UE1 camera-space Y is positive down and
  the D3D12 final presentation pass flips vertically, so OpenXR's positive-up
  upper/lower FOV bounds must be exchanged and negated for scene projection.
- Live Oculus Rift CV1 validation confirmed that both eyes fuse with correct
  depth, rotational stretching/swimming is completely gone in up/down and
  left/right motion, and existing gamepad controls remain unchanged.
- A focused timing capture measured 2.640 ms for the left eye, 2.505 ms for the
  right eye, and 5.190 ms through submission against the runtime's 11.111 ms
  display period, ruling out missed frame timing as the distortion source. The
  temporary timing instrumentation was removed afterward.
- The Release renderer built and deployed successfully. The six-map flat-screen
  Content suite passed after the final projection correction under
  `local/logs/automated-20260909-170147/`.
- This is a local rendering milestone, not completion of the seated VR plan.
  Head-gaze aiming, locomotion semantics, recentering, spatial UI, collision
  fade, mirror options, and broader runtime/gameplay validation remain.
- No GitHub push or release was created.

### Restored headset orientation through the authoritative camera hook

- Added a narrow renderer command that exposes the latest valid OpenXR
  orientation relative to a per-session neutral baseline.
- Added a highest-priority 227 `PlayerInteraction` that first obtains the
  player's fully calculated camera, including scripted flybys and view targets,
  then composes yaw, pitch, and roll onto that camera before scene culling.
  Pawn rotation, gameplay aim, and the underlying scripted camera remain
  unchanged.
- Live Oculus Rift CV1 validation confirmed that the intro begins in the same
  correct direction as the flat view and that all head rotations feel correct.
  The earlier severe direction error and black culling wedges were absent.
  Fine visual-comfort assessment remains limited until true per-eye stereo is
  implemented.
- The Release renderer and `ModernMenu` package built and deployed successfully.
  The three-case VR foundation suite passed under
  `local/logs/automated-20260909-140641/`, and the six-map flat-screen Content
  suite passed under `local/logs/automated-20260909-140731/`.
- Both eyes still intentionally receive the same image. Positional tracking,
  independent eye cameras, runtime FOV projection, and VR input remain future
  work.
- No GitHub push or release was created.

### Removed the invalid pawn-view VR camera experiment

- Flat and VR desktop-mirror captures of the flyby showed materially different
  scripted camera pitch and roll: the normal view looked toward the castle,
  while the VR override looked sharply down at the floor.
- Removed the `PlayerPawn.ViewRotation` override and all follow-on experimental
  stereo camera/projection work. The deployed renderer again submits UE1's
  untouched completed image to both eyes.
- Corrected the implementation boundary: future head tracking and stereo must
  transform UE1's authoritative calculated scene camera, including flybys and
  view targets, rather than treating pawn view state as the rendered camera.
- The rollback built and deployed successfully. The three-case VR foundation
  suite passed under `local/logs/automated-20260909-134039/`, and the six-map
  flat-screen Content suite passed under
  `local/logs/automated-20260909-134106/`.
- No GitHub push or release was created.

### Tested render-only headset orientation (later removed)

- Fed the latest valid OpenXR headset orientation into the next UE1 scene draw
  relative to a per-session neutral baseline, including yaw, pitch, and roll.
- Applied the pose only around the viewport draw and restored the player's view
  rotation immediately afterward, preserving pawn rotation, aiming,
  replication, and saved gameplay state.
- Reset pose validity and the neutral baseline across session stop, exit, loss,
  restart, and renderer shutdown paths.
- An initial Oculus Rift CV1 movement check appeared to confirm yaw, pitch, and
  roll, but later matched flat/VR flyby captures disproved that result by showing
  the scripted camera was not preserved. The experiment was subsequently
  removed as recorded above.
- The Release renderer built and deployed successfully. The three-case
  `VRFoundation` suite passed under `local/logs/automated-20260909-122944/`, and
  the six-map flat-screen Content suite passed under
  `local/logs/automated-20260909-110843/` with the loader remaining isolated.
- No GitHub push or release was created.

### Presented the UE1 game image in the headset

- Replaced the solid-color eye clear with the existing completed UE1 frame,
  rendered through a swapchain-format-compatible D3D12 presentation pipeline
  into both OpenXR eye images.
- Preserved the source aspect ratio with centered dark borders and added the
  correct display-to-linear conversion before writing through an sRGB OpenXR
  render-target view, avoiding an extra transfer-function application.
- Live Quest Link validation displayed the expected OldUnreal image in the
  headset and logged `first monoscopic game frame submitted to both eyes`, with
  the Oculus session returning cleanly through stopping to idle.
- Both eyes intentionally use the same camera image. Independent eye cameras,
  runtime FOV projection, and head tracking remain the next renderer bridge.
- All 50 D3D12 cases passed under
  `local/logs/automated-20260909-104934/`; all 18 D3D12, OpenGL, and XOpenGL
  renderer cases passed under
  `local/logs/supported-renderers-20260909-105306/`. Normal launches kept the
  OpenXR loader unloaded.
- No GitHub push or release was created.

### Submitted the first OpenXR stereo test image

- Added a seated `LOCAL` reference space, primary-stereo view configuration,
  runtime-selected sRGB color format, and separate runtime-recommended
  swapchains for the left and right eyes.
- Added session begin/end handling and the required wait/begin/locate,
  acquire/wait, D3D12 submission, release, and end-frame sequence. The current
  eye images are cleared to a stable dark-blue validation field; UE1 scene
  rendering is deliberately not connected yet.
- Live Quest Link validation created two 1344x1600 eye swapchains through the
  Oculus 1.207.0 runtime, reached the focused state, submitted the first stereo
  test frame, displayed the blue field in the headset, and shut down cleanly.
- Strengthened the runtime harness to require two ready eye swapchains and a
  submitted frame whenever a live session begins.
- All 50 D3D12 cases passed under
  `local/logs/automated-20260909-033510/`; all 18 D3D12, OpenGL, and XOpenGL
  renderer cases passed under
  `local/logs/supported-renderers-20260909-033845/`. Normal launches kept the
  OpenXR loader unloaded.
- No GitHub push or release was created.

### Added the guarded OpenXR D3D12 session handshake

- Enabled `XR_KHR_D3D12_enable` only for explicit VR launches, queried the
  runtime's graphics requirements, and reject adapter-LUID or feature-level
  mismatches without affecting the monitor renderer.
- Added D3D12 device/direct-queue session creation, lifecycle-event polling,
  and session-before-instance teardown. The session deliberately remains
  unbegun until frame timing and stereo swapchains are implemented.
- A user-driven Quest Link launch reached the Oculus 1.207.0 runtime and
  detected the HMD as `Oculus Rift CV1`, with orientation and position tracking
  available. After the session foundation was deployed, a second live launch
  created the D3D12 session and reached `XR_SESSION_STATE_READY`, then shut down
  cleanly. All 50 D3D12 cases passed under
  `local/logs/automated-20260909-031221/`, including runtime-unavailable
  fallback and strict `-novr` isolation. All 18 supported-renderer cases passed
  under `local/logs/supported-renderers-20260909-031551/`.
- No GitHub push or release was created.

### Prepared 0.6.0 locally with OpenXR runtime and HMD detection

- Increased local installer and rebuild artifact metadata to 0.6.0. The
  release-candidate tag is local only; no push or GitHub release was created.
- Added strict D3D12 OpenXR selection: flat-screen is the default, `-vr` or
  stored `EnableVR=True` requests detection, and `-novr` takes precedence.
- Pinned the official Khronos OpenXR SDK 1.1.61 source archive by SHA-256,
  builds its unmodified dynamic loader, and retains upstream provenance and
  license terms in installed packages. The loader is not an import dependency.
- Requested launches create a diagnostics-only OpenXR 1.0 instance, report the
  runtime and HMD system properties when available, and destroy the instance
  during renderer shutdown. Missing or unavailable runtimes and HMDs fall back
  safely. No session, stereo rendering, or VR support is claimed.
- The current host's registered Oculus/Meta runtime was reached through the
  loader but returned `XR_ERROR_RUNTIME_UNAVAILABLE`; no HMD was detected in
  that state. The diagnostic directs the player to start the headset software
  and connect or wake the device.
- The focused detection cases passed under
  `local/logs/automated-20260909-024421/`. All 50 D3D12 cases then passed under
  `local/logs/automated-20260909-024642/`, and all 18 supported-renderer cases
  passed under `local/logs/supported-renderers-20260909-025011/`. Every normal
  D3D12 launch kept `openxr_loader.dll` unloaded.
- Built the 88,893,707-byte local 0.6.0 offline installer with SHA-256
  `2402D38CC770090394873810216865F75E4EA8972EA6DB303FBC6F3926317C59`.
  It includes the 652,800-byte loader and its upstream copying notice, reports
  file version 0.6.0.0, and keeps `EnableVR=False` in staged defaults.

### Restored automated startup, shutdown, and release validation

- Added the missing `IDDIALOG_WizardDialog.IDC_WizardDialog` caption to every
  retained `Startup.*` localization during disposable-runtime provisioning and
  offline-installer staging. OldUnreal 227k_15 constructs the base wizard on
  every client startup, so the missing caption had aborted launches even with
  `FirstRun=227`.
- Made both runtime harnesses remove stale recovery markers and request clean
  engine shutdown through `WM_QUIT` on the process message queues. Closing only
  the viewport could leave the game running headless and prevented reliable
  unbind evidence.
- Added `/OriginalGameRoot=` for deterministic unattended installer runs while
  retaining the normal interactive source-detection page and validation.
- Built the Release D3D12 and SDL3 XInput drivers, deployed both, and compiled
  ModernMenu with zero warnings. All 47 D3D12 content, settings, menu/display,
  and input cases passed under
  `local/logs/automated-20260909-013107/`; all 18 D3D12, OpenGL, and XOpenGL
  map combinations passed under
  `local/logs/supported-renderers-20260909-013419/`.
- Rebuilt the 88,677,061-byte offline 0.5.0 installer with SHA-256
  `00C62C06773A5F28F39DFA63840017AB8FEA05713986E51DD20F0AB749F52BC2`.
  Its staged localization contains the required caption in all 10 languages.
  The existing-install uninstall path retained `Save` and created the expected
  Documents backup; a silent reinstall from explicit `C:\Unreal` succeeded,
  preserved the retained save directory, and an argument-free installed launch
  completed clean D3D12 and XInput bind/unbind cycles without the localization
  failure.

## 2026-09-08

### Refined project branding and installer interaction

- Replaced the previous logo source with the current transparent and
  dark-backed Unreal Revived artwork and derived dedicated campaign, About,
  Setup, and uninstall assets.
- Added unified campaign-preview branding and expanded the preserved About
  credits with the Unreal Revived project identity and link.
- Changed current-source existing-install handling to open one branded
  uninstall options dialog before standard progress, with save retention
  enabled by default. Direct uninstaller launches suppress Inno's redundant
  native confirmation.
- Added an optional desktop-shortcut task, a post-install launch option, and
  current feature text to the Setup welcome page.
- These changes are newer than the attached 0.5.0 release at `b1979f8` and
  require a new installer build and release before users receive them through
  the Releases page.

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

## 2026-09-15

### 0.6.2 installer production and lifecycle validation

- Built the 0.6.2 installer and branded launchers, bundled Old Weapons, and
  serialized the two UCC package builds that share a runtime directory.
- Removed the Realtime Ultra pawn-shadow option; the user verified its absence.
  The experimental mip workaround was fully reverted after display comparison
  isolated the motion artifact to the Dell monitor.
- Validated fresh install, payload/host hashes, both campaigns' startup,
  Old Weapons activation, desktop/VR launch and restart, profile migration,
  save retention, profile backups, reinstall, and final cleanup using an
  isolated validation installer identity. Evidence: `local/validation-062-20260915/`.
- Preserved development INIs byte-for-byte and retained the prior 0.6.1
  installer under `local/logs/release-062-20260915-151128/previous-installer/`.
- Production artifact, checksum, and limits are recorded in `release-0.6.2.md`.
  Source changes remain uncommitted; no GitHub publication was performed.

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

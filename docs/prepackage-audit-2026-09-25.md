# Pre-package maintenance audit — 25 September 2026

Scope: project-owned renderer/UI/input helpers, VR script lifecycle and hot paths,
test/build/packaging scripts, current documentation, tracked-file inventory and
local experiment outputs. This is a focused code review and regression pass, not
a proof that every code path is defect-free. No installer rebuild or publication.

## Corrections

- Removed unused `VRPanelGeometry::Upright` and its private quaternion type.
  Production now uses `OpenXRWorldHeading`; testing the old helper no longer
  protected the running renderer. Removed those obsolete assertions while
  retaining dimensions/aspect tests and the production OpenXR pose tests.
- Skip exponential easing calculation when neither position nor yaw is following.
  Follow timers and movement gates still update normally; thresholds, speeds,
  menu behavior, panel geometry and visual output are unchanged.
- Read each pressed key's binding once in `HandleVRRecenterKey`, instead of issuing
  a second identical console query for most keys. No cross-event cache is added,
  so binding changes remain immediately visible.
- D3D12 and supported-renderer smoke scripts now use disposable user-profile
  copies per case and clean them in `finally`. Previously they passed the owner's
  development user profile directly and only detected changes afterward by hash.
  Existing post-run source-profile hash checks remain.
- Reconciled the older seated VR plan and roadmap with accepted upright recenter,
  retained vertical tracking reference, automatic HUD recovery, snap turning,
  gaze swimming/flying and vignette acceptance. Historical progress/release
  records remain historical. Updated current-state wording for the weapon retest.

## Review observations and limits

- No byte-identical tracked source/script duplicates or missing local Markdown
  link targets were found by the scans. All PowerShell scripts/modules parse.
  These checks do not prove semantic dead-code absence: UnrealScript callbacks,
  reflected names, configuration properties and native hooks can have indirect
  callers. No reflection-visible fields were removed based on name counts.
- The internal localized name `AnimatedSnapText` is still used by the menu and
  displays Smooth Snap. It is not dead code; renaming a working localization
  property offers no runtime benefit.
- VR pose console queries, per-eye weapon rendering, and cached geometry/profile
  lookups were reviewed. More aggressive changes need representative profiling;
  this pass makes no measured FPS improvement claim. Do not cache per-eye poses
  across eyes/frames or remove required flushes merely to reduce call counts.
- The motion-save/restart/load/gaze report is currently not reproducing in the
  owner's retest. The rejected geometry change stays reverted; the specific
  restart-order regression coverage gap remains in the linked
  [weapon audit](vr-weapon-mode-load-audit.md). It is not closed by this pass.
- Maintained test sources and historical evidence are intentional. Existing
  extensionless files `System64/D3D12Test` and `System64/VRMotionTestUser` contain
  profile data and are preserved. SDK/reference trees, downloads, user-data,
  saves/profiles and the current installer are preserved.

## Validation

- Canonical Release build and renderer/menu deployment passed; menu builds have
  zero warnings.
- All 11 native renderer suites, both input suites and launcher-argument tests
  passed (14 total).
- Preferences, menu-back, weapon-motion and save/load/map-travel regressions passed.
- Desktop smoke and all 18 D3D12/OpenGL/XOpenGL map-startup checks passed. Smoke
  scripts verified source engine/user profile hashes remained unchanged.
- Production ModernMenu fixture-exclusion check passed; development fixtures were
  restored afterward for future testing. The installer itself was not rebuilt.
- Repository safety, whitespace, PowerShell syntax and local documentation-link
  checks passed. Evidence: `local/logs/prepackage-audit-20260925/`, with supported
  renderer details in `local/logs/supported-renderers-20260925-141528/`.

Generated native test build directories are removed after retaining logs. The
failed two-map-as-one-name smoke output and duplicate diagnostic log in System64
are obsolete and removed; the diagnostic evidence copy remains under local/logs.
No new headset visual acceptance or universal compatibility claim is made.

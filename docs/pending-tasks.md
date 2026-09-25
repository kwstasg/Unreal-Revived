# Pending tasks

Reviewed 25 September 2026. This is the current task list; dated audits and
release notes are historical evidence, not a second backlog.

## Current issues and acceptance

- **HUD horizon-lock acceptance:** owner confirmed the world fix but reported
  remaining HUD tilt. Explicit panel recenter now captures heading only too.
  Test looking up/down and tilting sideways, then straighten: panel stays upright
  at eye height while natural head motion remains tracked. Preserve yaw, authored
  cameras and panel size/distance. See [audit and CV1 cases](vr-horizon-lock.md).
- **VR vignette acceptance:** shared head-relative angular masking is implemented
  and passes production shader tests for asymmetric/canted eyes. Desktop falloff
  is preserved. Owner reported the 35-55-degree maximum barely visible; maximum
  coverage now fades over 20-40 degrees. Check 0/50/100% in CV1 for visibility and a single aligned fade,
  including head rotation, menus and quality changes. Hardware comfort/appearance
  is not established by the automated tests.
- **Other headsets/controllers:** obtain hardware reports for the profiles and
  headsets in [the compatibility guide](vr-controller-compatibility.md), including
  canted/wide-FOV optics, per-eye resolution, bindings and disconnect behavior.
  CV1 Touch and Xbox remain the owner's accepted baseline.
- **Uncommitted music work:** existing menu navigation changes, its regression
  fixture and documentation remain intact and outside the VR/installer commits.
  Reviewed and regression-tested again on September 25; still uncommitted.

## Broader coverage and future work

- Remote-client multiplayer VR firing and custom weapon adapters are unsupported.
- Complete Advanced/Mutator controller workflows and broader controller lifecycle
  coverage (including DS4 reconnect) need hardware/manual validation.
- Selectable desktop VR mirror and more detailed runtime status remain planned.
- Stereo comfort options, tracked hands, snap turning and room-scale
  design are not established by the current seated controller support.
- Physical 4K output, other runtimes and a clean-machine installer test need
  external hardware/environment coverage.
- RTX and a Vulkan renderer remain future projects; see [roadmap](roadmap.md).

## Closed or removed

- Current-source installer lifecycle: passed September 25 after settings-migration
  removal, including four fresh-profile hash comparisons, retained saves, exact
  backups, fixture exclusion and desktop/VR startup/restart. Oculus/CV1 initialized
  in IDLE; this does not establish headset visual acceptance. No publication/push.
- Focus-loss stutter: closed at the owner's direction; do not reopen as pending.
- Live VR quality, Balanced default, FPS/resolution feedback, bloom, gaze swimming/
  flying, pitch recovery and B/back behavior: owner accepted on CV1.
- Epic quality, Current profile selection and HUD/menu sharpness controls: removed.
- Settings migration: deliberately removed; installs seed defaults and retain saves.
- Canonical build path: restored to `local/build`. Active automated test sources
  remain maintained; their generated build directories can be regenerated.

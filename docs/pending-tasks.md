# Pending tasks

Reviewed 25 September 2026. This is the current task list; dated audits and
release notes are historical evidence, not a second backlog.

## Current issues and acceptance

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

- World/HUD horizon lock and revised VR vignette: owner accepted both as perfect
  on CV1 on September 25, at checkpoint `232f768`. Preserve heading-only world/
  panel capture and the shared 20-40-degree maximum fade. Other hardware remains
  unverified; the existing installer predates this accepted follow-up.
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

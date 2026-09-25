# Pending tasks

Reviewed 25 September 2026. This is the current task list; dated audits and
release notes are historical evidence, not a second backlog.

## Current issues and acceptance

- **Automatic HUD and recenter height:** implemented without a new setting;
  small seated motion stays stable, sustained displacement/turning brings the
  upright panel along, and open menus stay stationary. Recenter now preserves
  the running session's vertical reference instead of erasing standing height.
  Eleven native suites and runtime regressions pass; CV1 seated/standing,
  menu-interaction and repeated recenter acceptance remains pending. Full
  room-scale gameplay is separate. See [design and scope](vr-standing-and-turning.md).
- **Other headsets/controllers:** obtain hardware reports for the profiles and
  headsets in [the compatibility guide](vr-controller-compatibility.md), including
  canted/wide-FOV optics, per-eye resolution, bindings and disconnect behavior.
  CV1 Touch and Xbox remain the owner's accepted baseline.

## Broader coverage and future work

- Remote-client multiplayer VR firing and custom weapon adapters are unsupported.
- Complete Advanced/Mutator controller workflows and broader controller lifecycle
  coverage (including DS4 reconnect) need hardware/manual validation.
- Selectable desktop VR mirror and more detailed runtime status remain planned.
- Stereo comfort options, tracked hands and full room-scale
  design are not established by the current seated controller support.
- Physical 4K output, other runtimes and a clean-machine installer test need
  external hardware/environment coverage.
- RTX and a Vulkan renderer remain future projects; see [roadmap](roadmap.md).

## Closed or removed

- Turning modes: owner accepted behavior as perfect at `f995a53`; display names
  are Instant Snap and Smooth Snap. Smooth remains default; snap angle defaults
  to 30 degrees. Retain [the regression checklist](vr-standing-and-turning.md).
- Music menu navigation: reviewed and committed separately with its regression
  fixture and documentation. September 25 regression passed for focus navigation,
  playlist playback and empty-list handling; production fixture exclusion passed.
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

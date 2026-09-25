# Pending tasks

Reviewed 25 September 2026. This is the current task list; dated audits and
release notes are historical evidence, not a second backlog.

## Current issues and acceptance

- **Motion-to-gaze weapon offsets after save load:** unresolved owner report,
  clarified as motion gameplay/save, process restart, load in motion, then gaze.
  Currently not reproducing after rollback; [code audit](vr-weapon-mode-load-audit.md)
  records the remaining hypotheses and why earlier tests missed this sequence.
  especially UPak.RocketLauncher. The fixed-reference geometry attempt `d267b77`
  worsened more weapons and was reverted by `129c000`. Do not retune the accepted
  physical sizes or calibration based only on pose-cache tests. Reproduce the
  actual equipped/rendered offset and distinguish position from size before a
  replacement fix. A disposable copy of the owner's Save12 was inspected;
  unequipped weapons can have uninitialized hand offsets, which alone does not
  establish a defect because normal weapon selection calls SetHand.
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

- Automatic HUD recovery and recenter-height fix: owner accepted the result on
  CV1 at `b69ae2c`. No seated/standing option is needed. Retain the focused
  [regression checklist](vr-standing-and-turning.md); acceptance does not certify
  every listed scenario or full room-scale gameplay.
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

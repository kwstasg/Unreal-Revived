# Pending tasks

Reviewed 25 September 2026. This is the current task list; dated audits and
release notes are historical evidence, not a second backlog.

## Current issues and acceptance

- **VR vignette acceptance:** shared head-relative angular masking is implemented
  and passes production shader tests for asymmetric/canted eyes. Desktop falloff
  is preserved. Check 0/50/100% in CV1 for visibility and a single aligned fade,
  including head rotation, menus and quality changes. Hardware comfort/appearance
  is not established by the automated tests.
- **Other headsets/controllers:** obtain hardware reports for the profiles and
  headsets in [the compatibility guide](vr-controller-compatibility.md), including
  canted/wide-FOV optics, per-eye resolution, bindings and disconnect behavior.
  CV1 Touch and Xbox remain the owner's accepted baseline.
- **Installer acceptance:** after packaging the current source, repeat the full
  isolated lifecycle, including fresh settings and retained saves. The September
  21 lifecycle predates the removal of installer settings migration. Packaging
  and publication have not been performed as part of this cleanup.
- **Uncommitted music work:** existing menu navigation changes, its regression
  fixture and documentation remain intact and outside the cleanup commit.

## Broader coverage and future work

- Remote-client multiplayer VR firing and custom weapon adapters are unsupported.
- Complete Advanced/Mutator controller workflows and broader controller lifecycle
  coverage (including DS4 reconnect) need hardware/manual validation.
- Selectable desktop VR mirror and more detailed runtime status remain planned.
- Stereo comfort options, tracked hands, teleportation, snap turning and room-scale
  design are not established by the current seated controller support.
- Physical 4K output, other runtimes and a clean-machine installer test need
  external hardware/environment coverage.
- RTX and a Vulkan renderer remain future projects; see [roadmap](roadmap.md).

## Closed or removed

- Focus-loss stutter: closed at the owner's direction; do not reopen as pending.
- Live VR quality, Balanced default, FPS/resolution feedback, bloom, gaze swimming/
  flying, pitch recovery and B/back behavior: owner accepted on CV1.
- Epic quality, Current profile selection and HUD/menu sharpness controls: removed.
- Settings migration: deliberately removed; installs seed defaults and retain saves.
- Canonical build path: restored to `local/build`. Active automated test sources
  remain maintained; their generated build directories can be regenerated.

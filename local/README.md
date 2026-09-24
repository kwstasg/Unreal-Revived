# Local resources

Everything here except this file is ignored by Git.

| Directory | Purpose |
| --- | --- |
| `build/` | Canonical development and packaging build tree |
| `build-vr-tests/`, `build-input-tests/` | Regenerable builds of maintained native tests |
| `game/` | Marked disposable development runtime, profiles and saves |
| `sdk/227k_15/` | Pinned host SDK |
| `downloads/` | Verified dependency/host archives |
| `package/offline-installer/` | Current installer staging and output |
| `package/developer-bundle/` | Current generated developer bundle |
| `reference/` | Reference source and research, not build output |
| `logs/` | Current validation evidence and cleanup inventory |
| `tests/<task>/` | Temporary isolated runs; remove when the task is complete |
| `user-data/retired-preview/` | Saves/profiles preserved from the deleted launcher preview |

Use `cmake -S . -B local/build -A x64` before the documented build commands.
Do not create alternate development build trees or rename CMake caches. Separate
native test builds are legitimate; their sources and commands stay maintained.
Never modify the original game installation. Bootstrap details are in
[building](../docs/building.md); active work is in [pending tasks](../docs/pending-tasks.md).

Use Git commits for code rollback. Do not create project backup directories or
retain obsolete installer copies, experiment runtimes, staging helpers or logs.
On task completion remove disposable artifacts; retain current evidence, pinned
inputs, user data and the current package. Historical paths in progress/release
records do not imply that old binary artifacts are retained.

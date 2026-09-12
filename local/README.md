# Local resources

Everything in this directory except this file is ignored by Git.

```text
local/
  game/             Marked disposable Unreal Revived development runtime
  sdk/227k_15/      Extracted OldUnreal 227k_15 Windows SDK
  downloads/        Verified patch and SDK archives
  package/offline-installer/output/  Current validated installer and SHA-256
  package/developer-bundle/          Generated developer bundle
  reference/        Reference repository clones and research material
  backups/          Local configuration and save backups
  logs/             Collected runtime and diagnostic logs
  build/            Local build and staging output
  build-*/          Standalone native test/launcher build trees
  tests/            New disposable test runs, grouped by task
  archive/          Historical experiments and older installer outputs
  branded-launch-preview/  Accepted working preview (stable launch path)
```

The selected original Unreal Gold installation is the recovery source and must
remain unmodified, whether it came from OldUnreal or another valid source.
Create or refresh the complete local environment with:

```powershell
powershell -NoProfile -File scripts/bootstrap-dev-environment.ps1
```

Bootstrap physically copies the original game into `local/game/`, overlays the
verified host, installs the SDK, and writes the required development marker.
It reuses verified archives in `local/downloads/` or fetches them from the
original OldUnreal release. Previously downloaded archives can also be placed
in this directory for verified offline use.

Recommended environment variables:

```text
UE1_GAME_ROOT=<repository>\local\game
UE1_227K_SDK_ROOT=<repository>\local\sdk\227k_15
```

Never force-add files from this directory. Run
`scripts/check-repository.ps1` before commits and release packaging.

Keep new test runtimes and one-off helpers under `tests/<task>/`, rather than
creating more folders directly here. Store diagnostic logs under `logs/` and
recovery snapshots under `backups/`. Do not move existing build trees casually:
CMake caches contain absolute paths. The working preview also has launchers
pointing to its current location.

The September 12 cleanup preserved historical snapshots and old installer
outputs, removed redundant generated patch/payload staging, and restored the
current installer to the standard `package/offline-installer/output/` path.
The complete relocation record is `archive/2026-09-12/cleanup-manifest.json`.

Historical test runtimes and older test-log directories are compacted into
`archive/2026-09-12/experiments.zip` and `historical-test-logs.zip`.
`compact-verified.json` records their source locations, counts, sizes and
archive hashes; every file was compared byte-for-byte by SHA-256 before its
expanded copy was removed. Extract an archive when inspecting older evidence.
The current release validation logs remain directly available under `logs/`.

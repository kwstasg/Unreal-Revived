# Local resources

Everything in this directory except this file is ignored by Git.

```text
local/
  game/             Marked disposable Unreal Revived development runtime
  sdk/227k_15/      Extracted OldUnreal 227k_15 Windows SDK
  downloads/        Verified patch and SDK archives
  package/          Generated installer and developer-bundle output
  references/       Reference repository clones and research material
  backups/          Local configuration and save backups
  logs/             Collected runtime and diagnostic logs
  build/            Local build and staging output
```

The original Steam installation is the recovery source and must remain
unmodified. Create or refresh the complete local environment with:

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
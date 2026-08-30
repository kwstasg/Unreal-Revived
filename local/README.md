# Local resources

Everything in this directory except this file is ignored by Git.

```text
local/
  game/             Disposable Unreal Gold 227k_15 test installation
  sdk/227k_15/      Extracted OldUnreal 227k_15 Windows SDK
  downloads/        Verified patch and SDK archives
  references/       Reference repository clones and research material
  backups/          Local configuration and save backups
  logs/             Collected runtime and diagnostic logs
  build/            Local build and staging output
```

The original Steam installation is the recovery source and must remain
unmodified. Copy it into `local/game/`, then apply 227k_15 only to that copy.

Recommended environment variables:

```text
UE1_GAME_ROOT=<repository>\local\game
UE1_227K_SDK_ROOT=<repository>\local\sdk\227k_15
```

Never force-add files from this directory. Run
`scripts/check-repository.ps1` before commits and release packaging.
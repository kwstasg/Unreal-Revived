# Project instructions

## Required source attribution

Every project-owned source code file must start with this header:

```cpp
// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived
```

Use the language's valid comment prefix while retaining the exact three text
lines: `//` for C/C++, HLSL, UnrealScript and resource scripts; `#` for PowerShell,
Python and CMake; `;` for Inno Setup. Include tests, build scripts and source
templates. Generated project source must also include this header.

Add or correct the header whenever creating or modifying a project-owned source
file. Preserve existing upstream copyright/license notices. Do not relabel
unmodified third-party, vendored or SDK source as project-authored code.

## Generated files and cleanup

Use `local/package/offline-installer/output/` for the current installer. Keep
temporary validation installers under `local/tests/`, with a separate AppId.
Use `local/tests/<task>/` for disposable experiments and `local/logs/` for logs.
Do not scatter dated test folders or one-off scripts directly under `local/`
or the repository root.

Keep reusable tests in the existing test scripts/directories. Preserve the
current release, active working runtimes, build inputs and normal Git history.
The owner explicitly does not want project rollback snapshots retained: remove
all snapshots under `local/backups/`, including accepted-baseline and user-tested
installer backups, and obsolete installer copies under
`local/archive/2026-09-12/packages/`. Do not recreate these backups automatically;
use committed Git history for source history. Historical test evidence may stay
under `local/archive/`, but do not retain old runtime/installer copies for rollback.
This policy concerns project backups, not players' saves or the installer's
user-data backup feature. Update documentation when deleting or moving paths.
Installer maintenance/uninstall behavior is intentional; cleanup must not
change that behavior.

Before handing off source changes, check new and modified project-owned files
for this header. Do not change executable behavior just to add attribution.

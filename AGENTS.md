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
Use `local/tests/<task>/` for disposable experiments, `local/logs/` for logs,
and `local/backups/` for named recovery snapshots. Do not scatter dated test
folders or one-off scripts directly under `local/` or the repository root.

Keep reusable tests in the existing test scripts/directories. Preserve working
previews and accepted baselines during cleanup. Keep older results under
`local/archive/`; remove redundant generated staging only after preserving the
installer, its hash and manifests. Update documentation when moving paths.
Installer maintenance/uninstall behavior is intentional; cleanup must not
change that behavior.

Before handing off source changes, check new and modified project-owned files
for this header. Do not change executable behavior just to add attribution.

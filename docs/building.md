# Building

## Supported target

The current target is OldUnreal 227k_15 on Windows x64. CMake is the canonical
build system. The checked-in Visual Studio project is inherited reference
material and is not the supported build entry point.

## Prerequisites

- Windows x64
- Visual Studio 2022 with the Desktop development with C++ workload
- CMake 3.24 or newer
- An OldUnreal 227k_15 Windows SDK
- A disposable Unreal Gold installation patched with OldUnreal 227k_15

Game data and SDK files are not distributed by this repository. Keep them under
`local/` as described in [`../local/README.md`](../local/README.md), or provide
external paths through environment variables.

The SDK root must contain these files:

```text
Core/Inc/Core.h
Engine/Inc/Engine.h
Render/Inc/Render.h
Core/Lib/x64/Core.lib
Engine/Lib/x64/Engine.lib
Render/Lib/x64/Render.lib
```

## Path configuration

CMake resolves each path from an environment variable first, then falls back to
the ignored local directory:

| Variable | Default |
| --- | --- |
| `UE1_227K_SDK_ROOT` | `local/sdk/227k_15` |
| `UE1_GAME_ROOT` | `local/game` |

Example for the current PowerShell session:

```powershell
$env:UE1_227K_SDK_ROOT = 'D:\SDKs\OldUnreal-227k_15'
$env:UE1_GAME_ROOT = 'D:\Games\UnrealGold-227k_15-test'
```

## Configure and build

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
```

The renderer is built as `D3D12Drv.dll` with C++17 and links against the 227
Core, Engine, and Render import libraries plus the Windows Direct3D 12, DXGI,
and shader compiler libraries.

## Deploy

When `<game-root>/System64/Unreal.exe` exists, CMake exposes the deployment
target:

```powershell
cmake --build local/build --target deploy-d3d12drv --config Release
```

The target performs these operations in the disposable game installation:

1. Copies `D3D12Drv.dll` and `D3D12Drv.int` to `System64/`.
2. Copies the localized `UnrealShare.int` and `UPak.int` files from
   `SystemLocalized/int/` to `System/`.

The second operation is required because 227's `IntDescIterator` discovers the
single-player campaign registrations beside the game packages in `System/`.
Without it, the New Game campaign combo is empty even though localization paths
include `SystemLocalized/`.

Never deploy into the original Steam installation. Preserve it as the recovery
source and test only against the disposable copy.

## Repository safety

Run the repository guard before committing:

```powershell
powershell -NoProfile -File scripts/check-repository.ps1
```

The check rejects tracked or unignored game assets, SDK files, binaries, logs,
saves, and build output.

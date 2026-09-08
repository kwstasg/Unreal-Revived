# Project layout

## Implemented

```text
D3D12Drv/                    OldUnreal 227k adapter and native package project
XInputWinDrv/                Generated-source Windows viewport package project
cmake/                       Deployment and packaging target declarations
manifests/developer/         Optional developer-bundle artifact identity
manifests/hosts/             Supported host fingerprints
packaging/                   Offline installer definition
PERMISSIONS.md               Pinned payload authorization and packaging scope
local/                       Ignored game, SDK, references, and output
scripts/                     Bootstrap, packaging, deployment, and validation
```

`D3D12Drv/` currently contains the renderer implementation and its 227-specific
adapter code. CMake is the canonical build path. Files under `local/` are never
project source and must not be committed.

`XInputWinDrv/` contains the build definition and tracked delta for a
side-by-side Windows viewport package. Its inherited WinDrv source is copied
from the pinned ignored SDK into the generated build tree at configure time.
The tracked controller helper uses statically linked SDL3 Gamepad support to
map an active controller into Unreal's existing joystick key namespace, with
dynamically loaded system XInput and WinMM retained as fallback paths. Fresh
profiles select the package while stock WinDrv remains available for recovery.

The checked-in `D3D12Drv.vcxproj` and `.filters` files preserve inherited
upstream project structure and debugging metadata. They are reference material,
not an alternative to the supported CMake build.

## Proposed roadmap paths

```text
launcher/                    Portable installation and profile launcher
src/openxr/                  Phase-two OpenXR backend
src/hooks/VRHook227k15/      Optional version-pinned VR hook bridge
UnrealScript/VRBridge/       Phase-two gameplay and input policy
tests/                       Automated renderer and integration tests
tools/evidence/              ABI and binary evidence tooling
```

These paths describe the intended organization only. They are not present in
the repository yet and should gain tracked files only when implementation or a
concrete component contract is added.

# Project layout

## Implemented

```text
D3D12Drv/                    OldUnreal 227k adapter and native package project
manifests/hosts/             Supported host fingerprints
provenance/                  Source and permission inventory
LICENSES/                    Third-party and grant-specific license texts
local/                       Ignored game, SDK, references, and output
scripts/                     Repository and runtime validation scripts
```

`D3D12Drv/` currently contains the renderer implementation and its 227-specific
adapter code. CMake is the canonical build path. Files under `local/` are never
project source and must not be committed.

The checked-in `D3D12Drv.vcxproj` and `.filters` files preserve inherited
upstream project structure and debugging metadata. They are reference material,
not an alternative to the supported CMake build.

## Planned

```text
launcher/                    Portable installation and profile launcher
src/openxr/                  Phase-two OpenXR backend
src/hooks/VRHook227k15/      Optional version-pinned VR hook bridge
UnrealScript/VRBridge/       Phase-two gameplay and input policy
tests/                       Automated renderer and integration tests
tools/evidence/              ABI and binary evidence tooling
```

Planned directories gain tracked files only when implementation or a concrete
component contract is added. Their presence does not imply that the component
is implemented.
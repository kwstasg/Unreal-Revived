# Project layout

## Implemented

```text
D3D12Drv/                    OldUnreal 227k adapter and native package project
XInputWinDrv/                Generated-source Windows viewport package project
Launch/                     Branded desktop/VR engine hosts and argument tests
UnrealScript/ModernMenu/     Project-owned menu, HUD, input, and save UI
Localization/                Project-owned localization overlays
branding/                    Authored and generated project artwork
cmake/                       Deployment and packaging target declarations
docs/                        Current guides, validation records, and roadmap
manifests/content/           Installer content policy
manifests/developer/         Optional developer-bundle artifact identity
manifests/hosts/             Supported host fingerprints
manifests/provenance/        Third-party input identity and provenance
packaging/                   Offline installer definition
PERMISSIONS.md               Pinned payload authorization and packaging scope
local/                       Ignored game, SDK, reference material, and output
scripts/                     Bootstrap, packaging, deployment, and validation
```

`D3D12Drv/` currently contains the renderer implementation and its 227-specific
adapter code. CMake is the canonical build path. Files under `local/` are never
project source and must not be committed.

See [`../local/README.md`](../local/README.md) for generated files: the current
installer has one canonical output directory, experiments belong under
`local/tests/`, logs under `local/logs/`, and recovery snapshots under
`local/backups/`. Historical experiments may be stored in verified ZIP archives;
their archive manifests retain the original paths and integrity records.

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

## VR and future renderers

The OpenXR mode selection, runtime/HMD detection, D3D12 compatibility checks,
session lifecycle, reference space, frame timing, stereo rendering, eye
swapchains, and shared VR UI composition live in the D3D12 package, with the
Khronos loader supplied as a pinned CMake dependency. The seated VR baseline
has been accepted on Rift CV1; it is not a placeholder for future implementation.
RTX support and the Vulkan driver have no assigned source layout yet. See
[`roadmap.md`](roadmap.md) for milestone order and
[`pc-vr-seated.md`](pc-vr-seated.md) for the first milestone's scope.

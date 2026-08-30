# Project layout

```text
D3D12Drv/                    OldUnreal 227k adapter and native package project
launcher/                    Portable installation and profile launcher
src/d3d12/                   Direct3D 12 backend integration
src/renderer/                Engine-neutral rendering abstractions
src/ue1/                     Unreal Engine 1 adapter code
src/openxr/                  Phase-two OpenXR backend
src/hooks/VRHook227k15/      Optional version-pinned VR hook bridge
UnrealScript/VRBridge/       Phase-two gameplay and input policy
shaders/                     Renderer and composition shaders
tests/                       Unit and integration test sources
tools/evidence/              ABI and binary evidence tooling
manifests/hosts/             Supported host fingerprints
third_party/                 Authorized imported source
provenance/                  Source and permission inventory
LICENSES/                    Third-party and grant-specific license texts
local/                       Ignored game, SDK, references, and output
```

Directories for deferred components are created locally during bootstrap. They
gain tracked files only when implementation or a concrete component contract is
added.
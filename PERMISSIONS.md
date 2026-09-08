# Permissions

## OldUnreal 227k_15 Windows patch

The covered runtime and SDK inputs are identified immutably by
`manifests/hosts/unreal-gold-227k_15-win64.json`:

- Release: [Unreal v227k_15](https://github.com/OldUnreal/Unreal-testing/releases/tag/v227k_15)
- Release tag: [`v227k_15`](https://github.com/OldUnreal/Unreal-testing/tree/v227k_15)
- Release commit: [`2ea5408e2aa7c955eb087a6f8d2fcce318747d2f`](https://github.com/OldUnreal/Unreal-testing/commit/2ea5408e2aa7c955eb087a6f8d2fcce318747d2f)
- Runtime archive: [OldUnreal-UnrealPatch227k-Windows.zip](https://github.com/OldUnreal/Unreal-testing/releases/download/v227k_15/OldUnreal-UnrealPatch227k-Windows.zip)
- Runtime SHA-256: `88c49adef88e5a88c74f9fc80d89f0a2fe473d040578979aeb4425de32da12fc`
- SDK archive: [OldUnreal-UnrealPatch227k-SDK-Windows.zip](https://github.com/OldUnreal/Unreal-testing/releases/download/v227k_15/OldUnreal-UnrealPatch227k-SDK-Windows.zip)
- SDK SHA-256: `68a2fe383d426e2ed54197bafffaa0047757d4b32960d63bd0ce82eb7d84e913`

The original OldUnreal release URLs recorded in the host manifest are the
acquisition source for these hash-verified files.

## Upstream references

- [OldUnreal official website](https://www.oldunreal.com/)
- [OldUnreal organization](https://github.com/OldUnreal)
- [OldUnreal 227 testing and releases](https://github.com/OldUnreal/Unreal-testing)
- [OldUnreal public source](https://github.com/OldUnreal/Unreal-PubSrc)
- [OldUnreal 227 localization project](https://github.com/OldUnreal/Unreal-Localization)
- [OldUnreal 227k_15 license](https://github.com/OldUnreal/Unreal-testing/blob/v227k_15/LICENSE.md)

## NVIDIA intro logo

NVIDIA and the NVIDIA logo are trademarks and/or registered trademarks of
NVIDIA Corporation in the United States and other countries. The NVIDIA logo
remains the property of NVIDIA Corporation.

## Khronos OpenXR loader

The unmodified Khronos OpenXR loader is built from the hash-pinned OpenXR SDK
1.1.61 source archive and distributed under its Apache-2.0 OR MIT terms. The
installer retains the upstream `COPYING.adoc` beside Unreal Revived's install
records, and [`manifests/provenance/openxr-sdk-1.1.61.json`](manifests/provenance/openxr-sdk-1.1.61.json)
records the exact source and archive identity.

Source-control exclusions for archives and binaries remain intentional. The
pinned patch may be supplied from ignored local release inputs and embedded in
generated installer artifacts without committing it to the source tree.

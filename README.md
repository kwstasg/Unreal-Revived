# Unreal Gold Modernization

Modern DirectX 12 rendering, high-resolution support, uncapped presentation,
and native OpenXR VR for Unreal Gold.

## Status

The project is in bootstrap and renderer-port planning. The first target is
OldUnreal 227k_15 on Windows x64. OpenXR support follows flat-screen DirectX 12
rendering parity.

## Local setup

Game files, SDK files, reference repositories, downloads, and build output live
under the ignored `local/` directory. See `local/README.md` for the expected
layout. Never commit original game assets or local SDK artifacts.

## Development order

1. Port the authorized D3D12 renderer to the exact 227k_15 x64 SDK.
2. Validate native resolutions, presentation, and high-refresh behavior.
3. Build the portable deployment launcher.
4. Add native OpenXR stereo, input, and comfort features.

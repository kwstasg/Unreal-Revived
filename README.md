# Unreal Gold Modernization

Modern DirectX 12 rendering, high-resolution support, uncapped presentation,
and native OpenXR VR for Unreal Gold.

## Status

The DirectX 12 renderer is ported to OldUnreal 227k_15 on Windows x64. It
builds, deploys, and runs in a disposable Unreal Gold installation with native
resolution support, borderless letterboxing, corrected menu input, high-refresh
presentation, corrected HD lightmaps, and normal campaign selection.

OpenXR VR and a portable deployment launcher remain future work. The current
priority is flat-screen renderer parity and repeatable runtime validation.

## Quick start

Prepare the ignored SDK and game directories described in
[`local/README.md`](local/README.md), then configure and deploy the renderer:

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --config Release
cmake --build local/build --target deploy-d3d12drv --config Release
```

See [`docs/building.md`](docs/building.md) for prerequisites and environment
overrides.

## Local setup

Game files, SDK files, reference repositories, downloads, and build output live
under the ignored `local/` directory. See `local/README.md` for the expected
layout. Never commit original game assets or local SDK artifacts.

## Documentation

- [`docs/current-state.md`](docs/current-state.md) is the resume-here handoff.
- [`docs/renderer-227k.md`](docs/renderer-227k.md) explains the 227k_15 port.
- [`docs/configuration.md`](docs/configuration.md) lists runtime settings.
- [`docs/testing.md`](docs/testing.md) defines the validation checklist.
- [`docs/progress.md`](docs/progress.md) records completed engineering work.
- [`docs/project-layout.md`](docs/project-layout.md) describes repository scope.

## Roadmap

1. Complete flat-screen DirectX 12 parity and regression coverage.
2. Build the portable installation and profile launcher.
3. Add native OpenXR stereo rendering, input, and comfort features.

# Project guidelines

Read `docs/current-state.md` when resuming work or when prior session context is
unavailable.

## Safety and scope

- Treat this repository as an already initialized Git and CMake project. Do not
  scaffold or reinitialize it.
- Never modify the original Steam installation. Use the ignored disposable
  runtime under `local/game/` for deployment and testing.
- Never commit game assets, SDK artifacts, reference clones, binaries, logs,
  saves, or build output from `local/`.
- Preserve unrelated working-tree changes and keep edits within the requested
  component.

## Architecture and compatibility

- CMake is the canonical renderer build path. See `docs/building.md`.
- The supported current host is OldUnreal 227k_15 on Windows x64.
- Keep host-specific renderer compatibility behind `UNREAL_227` where
  practical. Preserve recognizable upstream UT99VulkanDrv structure.
- Treat OpenXR, the portable launcher, hooks, and VR bridge as roadmap work
  until tracked implementations exist.

## Provenance and documentation

- Record every imported third-party component with an immutable revision in
  both `THIRD_PARTY.md` and `provenance/components.yml`, with its notice under
  `LICENSES/`.
- Update the relevant document under `docs/` when behavior, setup, settings, or
  validation changes.
- Add meaningful completed work and validation evidence to `docs/progress.md`.
- Do not claim support for behavior that has not been validated.

## Validation

- Run the narrowest applicable build or runtime check after each substantive
  change.
- Run `powershell -NoProfile -File scripts/check-repository.ps1` before
  completion.
- Follow `docs/testing.md` for renderer and runtime validation.

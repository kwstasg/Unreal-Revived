# Engineering progress

This log records meaningful implementation milestones, why they were needed,
and how they were validated. Keep current behavior documented in the focused
technical guides; use this file for the chronological record.

## 2026-08-30

### Established a reproducible 227k_15 host

- Pinned the OldUnreal 227k_15 Windows x64 runtime and SDK with immutable archive
  and module hashes in `manifests/hosts/`.
- Kept the original Steam installation untouched and created an ignored,
  disposable runtime under `local/game/`.
- Added CMake validation for the required Core, Engine, and Render headers and
  x64 import libraries.
- Validated the runtime and SDK inputs against their recorded hashes.

### Imported and attributed the Direct3D 12 renderer

- Imported the authorized D3D12 backend from UT99VulkanDrv at the immutable
  revision recorded in `THIRD_PARTY.md` and `provenance/components.yml`.
- Preserved upstream structure while adding an explicit `UNREAL_227` host path.
- Added the applicable upstream notices under `LICENSES/`.
- Validated that the repository safety check excludes local references,
  downloads, binaries, SDK files, and game content.

### Ported the renderer to the 227 x64 ABI

- Added the CMake x64 DLL target and linked it to the 227 Core, Engine, and
  Render libraries.
- Adapted the render-device base class, capability flags, SDK includes, texture
  format enums, realtime texture invalidation, and `DrawGouraudPolyList` vtable
  entry for 227.
- Added the deployment target for `D3D12Drv.dll` and `D3D12Drv.int`.
- Validated a successful build, deployment, native D3D12 load, and absence of
  XOpenGL fallback.

### Corrected 227 HD lightmaps

- Fixed `TextureUploader_RGB10A2_LM` to read the packed source correctly,
  normalize the lighting channels, and provide the expected alpha.
- Removed black and magenta corruption from BSP lightmaps.
- Validated representative gameplay surfaces in the disposable runtime.

### Corrected borderless resolution behavior

- Preserved the selected logical resolution while presenting at the physical
  desktop resolution.
- Suppressed the synthetic WinDrv resize that promoted lower logical
  resolutions back to desktop size.
- Added callback-based mouse coordinate mapping that inverts presentation scale
  and letterbox offsets for UWindow.
- Preserved and restored the original viewport callback during renderer startup
  and shutdown.
- Validated menu hover and click alignment at native and lower resolutions.

### Restored normal startup and campaign selection

- Removed the forced campaign-map startup behavior.
- Established the working command form
  `Unreal.unr ini=D3D12Test.ini userini=D3D12TestUser.ini`; the leading map token
  prevents `ini=` from being parsed as a network URL.
- Traced the empty New Game combo through
  `UMenuNewGameClientWindow.IntDescIterator` with a disposable UnrealScript
  commandlet.
- Confirmed that 227 discovers campaign registrations from `System/`, then
  updated deployment to mirror localized `UnrealShare.int` and `UPak.int` into
  that directory.
- Validated that the iterator returns both `Unreal` and `Return to Na Pali` and
  that the D3D12 runtime remains responsive without fallback.

### Added project documentation

- Replaced the planning-stage README with the implemented renderer status,
  build entry point, documentation index, and honest roadmap.
- Added build, configuration, renderer-port, testing, and repository-layout
  documentation.
- Added workspace-wide and renderer-scoped Copilot instructions so future work
  follows the established safety, provenance, compatibility, and validation
  rules.
- Added `current-state.md` as a session-independent resume point containing the
  supported boundary, verified commands, critical invariants, and next
  priorities.
- Documented how the renderer plugin can be developed without full native
  engine source, including the SDK ABI, import libraries, available evidence,
  and limits on private engine modification.

## Entry template

Add new entries in this form:

```markdown
## YYYY-MM-DD

### Short milestone name

- Change: what behavior or code changed.
- Reason: the failure, requirement, or evidence that motivated it.
- Validation: the focused build, test, runtime check, or artifact inspected.
- Remaining: known limitations or follow-up work, when applicable.
```

Do not record a feature as complete until its focused validation has passed.
Do not use this log as a substitute for updating current-state technical docs.

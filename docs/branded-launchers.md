# Branded executables

The project builds `UnrealRevived.exe` and `UnrealRevivedVR.exe` from the
hash-checked `Launch/Src/Launch.cpp` in the pinned 227k_15 SDK. Each executable
hosts the engine and renderer in its own process; there is no child `Unreal.exe`.
Both carry the project icon, description, version and publisher metadata.
Upstream attribution remains in the copyright field and staged SDK license.

The generated source changes command-line construction and the launcher's
localization package identity. The SDK's allocator, engine initialization,
message loop and shutdown are retained. Engine, renderer, input and game-package
binaries are reused unchanged; the original `Unreal.exe` remains available.

| Executable | Engine profile | User profile | Mode | Default log |
|---|---|---|---|---|
| UnrealRevived.exe | Unreal.ini | User.ini | -novr | UnrealRevived.log |
| UnrealRevivedVR.exe | UnrealVR.ini | User.ini | -vr | UnrealRevivedVR.log |

No shortcut arguments are required. The startup map comes first internally.
Explicit maps/URLs, diagnostic arguments and quoted values are retained.
Mode/profile overrides are discarded: executable identity selects the mode
and profile, including after Preferences Restart. `-newwindow` prevents
forwarding a launch to another running mode. Avoid running both concurrently;
controls and saves remain shared.

Staging adds localized General strings under both executable names. Existing
translated state labels are retained where available. These aliases are needed
because the engine derives some localization names from the executable filename.

## Build and test

Normal launcher builds use the canonical `local/build` tree. Stage and test only
in a marked disposable installed runtime with `Unreal.ini`, `UnrealVR.ini` and
`User.ini`; use the isolated installer lifecycle in this guide to create it.
The old `branded-launch-preview` experiment has been retired.

```powershell
cmake -S . -B local/build -A x64
cmake --build local/build --target UnrealRevived UnrealRevivedVR --config Release
```

Pass that disposable runtime to `stage-branded-launchers.ps1 -RuntimeRoot` with
`-BinaryRoot local/build/Launch/Release`, then to
`test-branded-launchers.ps1 -RuntimeRoot`. Do not use a production installation.

The runtime test requires the user's graphics/OpenXR runtime for headset
detection; a sandbox account can exercise unavailable-runtime fallback.
It verifies no-argument startup from an unrelated working directory, direct
engine ownership, mode/profile selection, quoted log paths, explicit map
startup, and the same RELAUNCH command used by Preferences Restart.

## September 11, 2026 validation

The accepted installer and installed runtime were originally backed up under
`local/backups/branded-launch-baseline-20260911-151105/`, with the working-tree patch
and base revision. These rollback copies were later deleted at the owner's
explicit request; the locations below are historical. Accepted installer SHA-256:
`A552D7C28925D9788AAB519D0A333EF805E0A38AA16C3D150ED4DA0E2B4059F2`.

Argument tests passed. Both preview hosts loaded the intro with correct titles.
Desktop retained 1920x1080 and never queried OpenXR. VR detected Oculus Rift CV1
through Oculus runtime 1.207.0 and initialized stereo presentation with a
1280x1024 monitor window. NyLeve startup, conflicting mode/profile arguments,
and diagnostic paths with spaces passed. Both modes restarted into the same
executable and profile. Original engine, renderer, input and ModernMenu hashes
remained unchanged. Evidence is in `local/logs/branded-launch-runtime-validation.log`
and the preview runtime's mode-specific logs.

Display persistence was also tested in a fresh disposable copy with
`scripts/test-branded-display-isolation.ps1`: change VR to 1440x900 windowed,
change desktop to 1600x900 fullscreen, then relaunch both without arguments.
Both settings persisted, and each run left the inactive engine profile
byte-for-byte unchanged. Evidence: `local/logs/branded-display-isolation-validation.log`.
Run this display-change test in the user's graphics session; an interrupted
sandbox run can leave the disposable runtime in the engine's recovery state.

Meta's runtime logs identify `UnrealRevivedVR.exe` as the VR client. The user
subsequently accepted the preview and confirmed restart and launching from the
Oculus library work correctly. This records the user's hardware/UI validation
in addition to the automated startup and restart checks above.

The standard CMake installer targets now build and package both executables,
localized names and SDK notices. Installed shortcuts and post-install launch
target the branded executables without arguments. The prior accepted installer
backup was deleted at the owner's request; the working preview remains unchanged.

Setup's existing behavior is intentional: rerunning it on an installed copy
opens the branded uninstall dialog. Uninstall backs up all three profiles to
Documents and optionally retains saves for reinstallation. It does not restore
those backed-up settings automatically. Installing profiles over existing files
now seeds fresh defaults; see the current policy below. This supersedes the
older preservation/migration behavior recorded in the historical validation.

`scripts/test-branded-installer.ps1` exercises the real installer compiled from
the same Inno definition with `/DValidationBuild`. That switch gives it a
separate AppId and shortcut names, protecting the user's production installation.
It checks fresh installation, executable and host hashes, four shortcuts,
runtime startup and restart, fresh profile defaults after reinstall, uninstall
backups, reinstall with retained saves, and cleanup. Run in the user's Windows
graphics session with a new test directory under `local/`.

## Current profile policy and 0.9.0 validation

Setup follows uninstall/reinstall. The profile writer now always seeds desktop,
VR, controls and bundled weapon calibration from fresh defaults. Old settings
are not migrated. Saves and the existing uninstall backup remain preserved.
`scripts/test-installer-profile-reset.ps1` verifies the writer in an isolated
folder without running Setup. The 0.9.0 installer subsequently passed the full
isolated lifecycle after migration removal: fresh defaults for all four files,
exact uninstall backups, retained saves, fixture exclusion and desktop/VR
startup/restart. Automated CV1 OpenXR initialization remained in IDLE. The owner
subsequently accepted the installed 0.9.0 build after manual testing. See [the validation record](release-0.9.0-validation.md).

The lifecycle results below are historical and include superseded migration
behavior. Their binary/log paths do not imply that those artifacts remain on disk.

## September 12, 2026 installer validation

The September 21 release-cleanup candidate was subsequently rebuilt and passed
the same isolated lifecycle with production-only `ModernMenu.u`. Coverage now
also rejects packaged test fixtures, checks the shipped weapon-calibration seed,
changes that calibration and verifies preservation during profile migration and
the uninstall backup alongside all three canonical profiles. Fresh/reinstall
payload hashes, desktop/VR launches and restarts, Old Weapons activation, save
retention and test cleanup passed. The CV1 was detected and OpenXR initialized;
this automated check does not replace the earlier owner visual acceptance.
Evidence: `local/logs/release-installer-lifecycle.log`; candidate checksum is in
[the progress record](progress.md). No production installation was
targeted and no release was published.

The full isolated lifecycle passed, including fresh installation, both native
hosts and Preferences Restart, exact preservation of changed profiles when
applying installer configuration, exact uninstall backups of all three INIs,
retained saves across reinstall, and removal of validation shortcuts and
registration. Evidence: `local/logs/branded-installer-lifecycle-complete.log`.
This run detected Oculus 1.207.0 with the headset unavailable and validated
fallback; headset rendering and Meta library launch were validated in the
accepted preview above. A separate clean-machine release test remains outside
this local validation.

Both hosts add no DLL imports beyond the original `Unreal.exe` prerequisites.
Packaged renderer, input, OpenXR loader and ModernMenu binaries exactly match
the accepted runtime. `InitializeSetup` retains the baseline uninstall flow.

September 11 candidate, subsequently accepted by the owner after installation:
`local/backups/release-0.6.0-user-tested-20260912/output/UnrealRevived-Setup-0.6.0.exe`
(89,702,168 bytes). SHA-256:
`C9D7B9E3BCBD6003171EC228DD072518E21FBB89DE910AA602A89D263AFF7668`.

The rebuilt release installer uses the canonical
`local/package/offline-installer/output/` location. Its release manifest identifies
the committed source and new checksum; the historical checksum above identifies
the historical user-tested candidate only; that backup has been removed.

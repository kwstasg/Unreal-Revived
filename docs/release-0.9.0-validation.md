# 0.9.0 local installer validation

Validated and published 25 September 2026 with owner authorization.
[Release and downloads](https://github.com/kwstasg/Unreal-Revived/releases/tag/UnrealRevived-Setup-0.9.0).

## Artifact

- Canonical build: `cmake --build local/build --target package-offline-installer --config Release`.
- Source: `ae367b82a301181e95bbdb4be4da15402c36abaa`, clean working tree.
- Installer: `local/package/offline-installer/output/UnrealRevived-Setup-0.9.0.exe`.
- Size: 89,780,413 bytes; product version 0.9.0, file version 0.9.0.0.
- SHA256: `F9B8677F06CAEE329012B65ED4EC4CE70148CC7BF2C0227D4913D6A2EB6A5DBB`.
- Evidence: `local/logs/release-0.9.0-20260925/`, including artifact metadata,
  package/profile-reset/lifecycle logs and retained individual launch logs.

The lifecycle used the same payload and installer script with `ValidationBuild`
enabled, giving it an isolated application identity, registration and shortcuts.
The owner subsequently tested the installed 0.9.0 build and accepted it.

## Passed checks

- Production menu compilation and exclusion of development test fixtures.
- Fresh settings for all four profiles, with sentinel save preservation.
- Installation payload and original host hashes, branding and four shortcuts.
- Desktop, Return to Na Pali and OldWeapons startup.
- Desktop/VR mode selection, arguments containing spaces and Preferences restart
  retaining the correct executable, mode and profiles.
- Oculus CV1 OpenXR initialization and stereo swapchains; session remained IDLE.
- Uninstall retaining saves and making exact backups of all four profiles.
- Reinstall restoring fresh profile hashes while retaining saves.
- Final uninstall removing isolated registration, shortcuts and test backups.

## Owner acceptance and preservation note

On 25 September 2026, after the requested installed-build desktop/CV1 check,
the owner reported: "tested it and everything is in order". This closes the
installed-build acceptance task. It records overall manual acceptance, not an
individual result for every suggested scenario. The automated session remained
in IDLE; the owner report provides separate acceptance evidence. Other headset
compatibility and clean-machine testing remain unverified. The owner subsequently authorized publication and push.

Pre/post-build hashes matched for 22 of 23 development INI/save files. The menu
build reapplied defaults to `D3D12Test.ini`; the original bytes were not backed
up, so its precise prior settings cannot be restored from the captured hash.
Saves, the user profile and weapon calibration were unchanged. The follow-up
build-script correction removes video/user-default resets from menu rebuilds;
a disposable-profile production rebuild preserved custom HUD distance, vignette
and FOV. Fresh-runtime and installer default seeding remain in place. That
script-only correction is after the artifact source revision listed above.

The packaging script recreates disposable staging, replacing the preceding local
0.8.0 installer. Historical release records and the published 0.8.0 release remain
unchanged. Current 0.9.0 installer and evidence are retained.

The release tag includes finalized documentation and the development menu-build
profile-preservation correction. The accepted binary remains the unchanged
artifact from clean `ae367b82` recorded above; no shipped runtime source changed
between that build and publication.

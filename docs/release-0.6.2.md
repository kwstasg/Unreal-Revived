# Unreal Revived 0.6.2

This release adds seated VR comfort controls and head-collision protection,
bundles Old Weapons, and retains the desktop and OpenXR features of 0.6.1,
including the Return to Na Pali VR HUD fix.

## Changes

- **Height Offset:** adjust the seated viewpoint from -0.75 to +1.50 meters.
  Default 0.00 preserves the original height.
- **World Size:** adjust perceived world size from 40% to 250%, with 100% as
  default. Higher values make you feel smaller in the map; lower values make
  you feel bigger. Stereo depth, tracked movement, first-person camera height
  and the displayed weapon scale together. Height Offset adds separate tuning.
- Both VR sliders apply immediately, save between launches, include reset
  buttons and controller navigation, and have English/Greek labels and help.
- **Head-collision protection:** the headset world image progressively fades
  to black near blocking geometry and returns when the head moves clear.
  Tracking continues without camera clamping. The spatial HUD/menu stays
  visible for recovery. Non-blocking triggers and water volumes are excluded.
- Fixed negative slider rounding that trapped analog-stick height adjustment
  at the minimum. Added a regression commandlet for the installed runtime.
- Build and bundle the **Old Weapons** mutator and install its registrations.
- Remove **Realtime Ultra Res** from Pawn shadows. Opening Video settings maps
  saved resolutions above 512 to Realtime High Res. Decoration shadows and
  shadow draw distance remain unchanged.
- Serialize the menu and Old Weapons package builds, which share a runtime;
  include Old Weapons in bootstrap, rebuild and installer validation.
- Update the installer and branded launchers to version 0.6.2 and record source
  cleanliness in the payload manifest.

The experimental texture mip-bias workaround is not included. Original renderer
texture filtering is retained; the reported movement artifact was isolated to
the monitor using the user's second display.

## Installation

Run `UnrealRevived-Setup-0.6.2.exe` and select an original Unreal Gold
installation. Setup creates a separate Unreal Revived installation.
The desktop and VR launchers retain separate display profiles. Existing
installations use the supported uninstall/reinstall flow with save retention
and settings backups. Original game assets are not included.

## Validation

The owner accepted the pawn-shadow menu change, VR height/world-size controls
and signed-slider fix. On 2026-09-15, the owner confirmed normal collision fade
and recovery at walls, corners and low ceilings, and normal behavior with a
door, size adjustments, swimming in water and an elevator.

Earlier 0.6.2 installer lifecycle validation is retained under
`local/validation-062-20260915/`. It covered installation, payload/host hashes,
shortcuts, desktop/expansion/Old Weapons startup, Rift CV1 startup, Preferences
restart, exact profile migration, save retention, settings backups and
uninstall/reinstall. That earlier installer predates the final VR additions.

The final build's exact source revision, installer size/hash and automated
validation results are recorded alongside the installer in
`local/package/offline-installer/output/release-manifest.json`.
The adjacent `.exe.sha256` file identifies the final installer. Older 0.6.2
candidate hashes do not identify this release build.

## Compatibility boundary

The installer is unsigned. Rift CV1 remains the validated headset. Other
headsets/runtimes, VR multiplayer, dedicated swimming/flying movement semantics,
selectable desktop mirror modes and broader custom-map compatibility remain
follow-up work. Water testing confirms collision behavior, not complete
swimming-control support. Local installer tests do not establish a direct
in-place upgrade from 0.6.1 or clean-PC headset acceptance.

## Release artifacts

- `UnrealRevived-Setup-0.6.2.exe`
- `UnrealRevived-Setup-0.6.2.exe.sha256`
- `release-manifest.json`

Full change history: [Changelog](../CHANGELOG.md).

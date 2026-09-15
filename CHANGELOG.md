# Changelog

## 0.6.2 — 2026-09-15

### Added

- VR Height Offset slider: -0.75 to +1.50 meters, default 0.00, with live
  updates, saved settings and a reset button.
- VR World Size slider: 40–250%, default 100%. Stereo depth, tracked movement,
  first-person viewpoint height and displayed weapon scale together. Larger
  values make the player feel smaller in the map. Includes live updates,
  saved settings and a reset button.
- Progressive VR collision fade near solid walls, corners, ceilings and
  blocking objects. The image returns when the head moves clear. Tracking
  continues and the spatial HUD/menu stays visible for recovery.
- Bundled Old Weapons mutator, registrations, and a serialized package build.
- English and Greek labels/help for the new VR preferences.

### Fixed

- Height slider getting stuck at its negative minimum when using the analog
  stick. Signed rounding is covered by a runtime regression commandlet.
- Removed the expensive Realtime Ultra Res pawn-shadow option. Opening Video
  preferences maps saved pawn-shadow resolutions above 512 to High Res.

### Release engineering

- Updated launcher and installer versions to 0.6.2.
- Included Old Weapons in bootstrap, rebuild, deployment, installer payload
  verification and launch checks.
- Recorded source cleanliness in the payload manifest.

The temporary texture mip-bias experiment is not included. Detailed validation
and installation notes: [0.6.2 release notes](docs/release-0.6.2.md).

## 0.6.1

- Fixed the Return to Na Pali VR HUD and preserved expansion HUD state when
  loading older saves.
- Added the feature infographic to the project overview.

See [0.6.1 release notes](docs/release-0.6.1.md).

## 0.6.0

- Introduced the accepted seated OpenXR experience, spatial HUD/menu,
  gaze-aligned walking, recenter controls, and branded desktop/VR launchers
  with separate display profiles.

See [0.6.0 release notes](docs/release-0.6.0.md) for details and validation limits.

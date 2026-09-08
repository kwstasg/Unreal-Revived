# Unreal Revived branding

These Unreal Revived branding assets are tracked directly:

- `UnrealRevivedLogo.png`: transparent high-resolution logo source used by the
  README and runtime compatibility banners.
- `UnrealRevivedLogo.jpg`: dark-backed installer banner source.
- `InstallerBanner.png`: generated landscape branding derivative retained for
  future packaging layouts; the current installer uses only the portrait.
- `InstallerWizard.png`: generated portrait artwork used on Setup's Welcome
  and Completed pages and in the branded uninstaller.
- `UnrealRevivedCampaignLogoRuntime.png`: generated transparent 256x128
  ModernMenu texture used for both New Game campaign previews.
- `UnrealRevivedAboutLogoRuntime.png`: generated dark-backed 512x256
  ModernMenu texture whose 512x171 banner region appears above the credits.
- `Logo.png`: transparent 952x295 runtime logo.
- `SetupLogo.png`: transparent 343x84 first-time configuration logo.
- `Logo.bmp`: generated 952x295 OldUnreal-compatible launch banner.
- `SetupLogo.bmp`: generated 343x84 OldUnreal-compatible first-time
  configuration banner.
- `icon..png`: transparent icon source artwork.
- `UnrealRevived.ico`: desktop, Start Menu, and uninstall icon with 16, 24,
  32, 48, 64, 128, and 256 pixel frames.
- `MenuBackground.jpg`: authored 16:9 source artwork.
- `MenuBackground.bmp`: 3840x2160 canonical artwork for the in-game menu
    desktop when imported from the authored source.
- `NvidiaIntroLogo.png`: high-resolution NVIDIA source artwork.
- `NvidiaIntroLogoRuntime.png`: generated transparent 256x256 UE1 intro
    texture. NVIDIA ownership, permission, and notices are recorded in
    `manifests/provenance/nvidia-intro-logo.json`.

The generator derives both ModernMenu logo textures alongside the runtime and
installer banners. It also slices `MenuBackground.bmp` into twelve tracked 256x256 textures
under `branding/MenuTiles`. The ModernMenu build stages them into its temporary
package source tree for Unreal Engine 1 compatibility.

## Importing final menu artwork

Create the artwork yourself in PNG, BMP, or JPEG format at any exact 16:9
resolution. Import it and derive the project banner and icon with:

```powershell
powershell -NoProfile -File scripts/build-unreal-revived-branding.ps1 `
    -MenuBackgroundSource branding\MenuBackground.jpg `
    -DeriveBranding
```

This validates the aspect ratio, upscales the source into a tracked 24-bit
3840x2160 `MenuBackground.bmp`, and recreates the twelve tracked menu tiles.
It also derives the transparent logos and compatible BMP banners from
`UnrealRevivedLogo.png`, the installer artwork from `UnrealRevivedLogo.jpg`,
and every icon frame from `icon..png`. Omit `-DeriveBranding` to
update only the menu background and tiles.

OldUnreal 227k hardcodes `Help\Logo.bmp` and `Help\SetupLogo.bmp` in its setup
and launch executables. The generator therefore preserves transparency in the
tracked PNG outputs and composites compatibility BMP copies onto the banner's
dark background. The host's opaque GDI bitmap control cannot render PNG or BMP
alpha. The ICO retains source alpha, and other uses should prefer the
transparent PNG.

The runtime restores the source's native 16:9 proportions and uses centered
cover scaling for other viewport ratios. Wider displays crop the top and
bottom; narrower displays crop the sides.

Build and deploy the updated development package:

```powershell
cmake --build local/build --target deploy-modern-menu --config Release
```

This also copies `Logo.bmp` and `SetupLogo.bmp` into `local/game/Help`, installs
the generated ICO under a hash-derived `local/game/UnrealRevived` filename,
and recreates both development shortcuts with that icon.

Rebuild the distributable installer after validation:

```powershell
cmake --build local/build --target package-offline-installer --config Release
```

Regenerate only the logo and icon outputs from their transparent sources:

```powershell
powershell -NoProfile -File scripts/build-unreal-revived-branding.ps1 `
    -BrandingOnly
```

This regeneration command replaces the tracked BMP banners with generated
compatibility copies.

Running the generator without options also recreates the placeholder menu
background and menu tiles. `-DeriveBranding` requires a menu source. Keep the
documented dimensions and ICO frame sizes because the OldUnreal host,
ModernMenu package, and Windows shortcuts expect them.

Regenerate only the NVIDIA intro texture from its high-resolution master with:

```powershell
powershell -NoProfile -File scripts/build-unreal-revived-branding.ps1 `
    -IntroNvidiaSource branding\NvidiaIntroLogo.png
```

The source and generated texture must continue to match the immutable hashes
in the provenance manifest. Update that record only when authorized replacement
artwork is deliberately adopted.

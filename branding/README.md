# Unreal Revived branding

These Unreal Revived branding assets are tracked directly:

- `Logo.bmp`: 719x200 setup banner.
- `SetupLogo.bmp`: 343x84 first-time configuration banner.
- `UnrealRevived.ico`: desktop, Start Menu, and uninstall icon with 16, 24,
  32, 48, 64, 128, and 256 pixel frames.
- `MenuBackground.jpg`: authored 16:9 source artwork.
- `MenuBackground.bmp`: 3840x2160 canonical artwork for the in-game menu
    desktop when imported from the authored source.
- `NvidiaIntroLogo.png`: high-resolution NVIDIA source artwork.
- `NvidiaIntroLogoRuntime.png`: generated transparent 256x256 UE1 intro
    texture. NVIDIA ownership, permission, and notices are recorded in
    `manifests/provenance/nvidia-intro-logo.json`.

The generator slices `MenuBackground.bmp` into twelve tracked 256x256 textures
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
It also crops the circular crest into every frame of `UnrealRevived.ico` with
transparent corners, crops the lower wordmark into the 719x200 `Logo.bmp`, and
resizes that same banner into the 343x84 `SetupLogo.bmp`. Omit
`-DeriveBranding` to update only the menu background and tiles.

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

Edit the bitmap and icon files directly, or regenerate the baseline artwork:

```powershell
powershell -NoProfile -File scripts/build-unreal-revived-branding.ps1
```

Running the generator without `-MenuBackgroundSource` recreates all placeholder
branding images and menu tiles. `-DeriveBranding` requires a menu source. Keep
the documented dimensions and ICO frame sizes because the OldUnreal host,
ModernMenu package, and Windows shortcuts expect them.

Regenerate only the NVIDIA intro texture from its high-resolution master with:

```powershell
powershell -NoProfile -File scripts/build-unreal-revived-branding.ps1 `
    -IntroNvidiaSource branding\NvidiaIntroLogo.png
```

The source and generated texture must continue to match the immutable hashes
in the provenance manifest. Update that record only when authorized replacement
artwork is deliberately adopted.
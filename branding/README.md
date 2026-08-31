# Unreal Revived branding

These are original Unreal Revived project assets and are tracked directly:

- `Logo.bmp`: 719x200 setup banner.
- `SetupLogo.bmp`: 343x84 first-time configuration banner.
- `UnrealRevived.ico`: desktop, Start Menu, and uninstall icon with 16, 24,
  32, 48, 64, 128, and 256 pixel frames.

Edit the bitmap and icon files directly, or regenerate the baseline artwork:

```powershell
powershell -NoProfile -File scripts/build-unreal-revived-branding.ps1
```

Regeneration overwrites all three image files. Keep the documented dimensions
and ICO frame sizes because the OldUnreal host and Windows shortcuts expect
them.
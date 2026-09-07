# Unreal Revived
# Author: Kwstasg - Kostas Giannakakis
# Project: https://github.com/kwstasg/Unreal-Revived

param(
    [string] $OutputRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'branding'),

    [string] $MenuTextureRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'branding\MenuTiles'),

    [string] $MenuBackgroundSource,

    [switch] $DeriveBranding,

    [string] $LogoSource = (Join-Path (Split-Path -Parent $PSScriptRoot) 'branding\LogoHD.png'),

    [string] $IconSource = (Join-Path (Split-Path -Parent $PSScriptRoot) 'branding\icon..png'),

    [switch] $BrandingOnly,

    [string] $IntroNvidiaSource
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Get-BrandFontFamily {
    $installed = @([Drawing.Text.InstalledFontCollection]::new().Families.Name)
    foreach ($name in @('Trajan Pro', 'Georgia', 'Times New Roman')) {
        if ($name -in $installed) {
            return New-Object Drawing.FontFamily($name)
        }
    }
    throw 'No supported branding font is installed.'
}

function Add-BrandText {
    param(
        [Drawing.Graphics] $Graphics,
        [Drawing.FontFamily] $FontFamily,
        [string] $Text,
        [Drawing.RectangleF] $Bounds,
        [single] $Size,
        [Drawing.FontStyle] $Style
    )

    $format = [Drawing.StringFormat]::GenericTypographic
    $format.Alignment = [Drawing.StringAlignment]::Center
    $format.LineAlignment = [Drawing.StringAlignment]::Center
    $path = New-Object Drawing.Drawing2D.GraphicsPath
    try {
        $path.AddString($Text, $FontFamily, [int]$Style, $Size, $Bounds, $format)
        $shadow = New-Object Drawing.Pen([Drawing.Color]::FromArgb(230, 8, 10, 11), ([Math]::Max(1.5, $Size / 16.0)))
        $outline = New-Object Drawing.Pen([Drawing.Color]::FromArgb(255, 82, 55, 15), ([Math]::Max(0.8, $Size / 40.0)))
        $fill = New-Object Drawing.Drawing2D.LinearGradientBrush(
            (New-Object Drawing.PointF(0, $Bounds.Top)),
            (New-Object Drawing.PointF(0, $Bounds.Bottom)),
            [Drawing.Color]::FromArgb(255, 255, 224, 138),
            [Drawing.Color]::FromArgb(255, 151, 94, 24))
        try {
            $Graphics.DrawPath($shadow, $path)
            $Graphics.FillPath($fill, $path)
            $Graphics.DrawPath($outline, $path)
        }
        finally {
            $fill.Dispose()
            $outline.Dispose()
            $shadow.Dispose()
        }
    }
    finally {
        $path.Dispose()
    }
}

function New-BrandBanner {
    param(
        [int] $Width,
        [int] $Height,
        [string] $Output
    )

    $bitmap = New-Object Drawing.Bitmap($Width, $Height, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $fontFamily = Get-BrandFontFamily
    try {
        $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $background = New-Object Drawing.Drawing2D.LinearGradientBrush(
            (New-Object Drawing.Point(0, 0)),
            (New-Object Drawing.Point($Width, $Height)),
            [Drawing.Color]::FromArgb(255, 25, 31, 34),
            [Drawing.Color]::FromArgb(255, 93, 101, 103))
        try {
            $graphics.FillRectangle($background, 0, 0, $Width, $Height)
        }
        finally {
            $background.Dispose()
        }

        $random = New-Object Random 227
        for ($index = 0; $index -lt [int]($Height * 1.6); $index++) {
            $shade = $random.Next(25, 95)
            $alpha = $random.Next(8, 24)
            $pen = New-Object Drawing.Pen([Drawing.Color]::FromArgb($alpha, $shade, $shade, $shade), 1)
            try {
                $y = $random.Next(0, $Height)
                $graphics.DrawLine($pen, 0, $y, $Width, $y)
            }
            finally {
                $pen.Dispose()
            }
        }

        $border = New-Object Drawing.Pen([Drawing.Color]::FromArgb(255, 184, 128, 42), ([Math]::Max(1, $Width / 360.0)))
        $innerBorder = New-Object Drawing.Pen([Drawing.Color]::FromArgb(180, 8, 10, 11), 1)
        try {
            $graphics.DrawRectangle($border, 2, 2, $Width - 5, $Height - 5)
            $graphics.DrawRectangle($innerBorder, 6, 6, $Width - 13, $Height - 13)
        }
        finally {
            $innerBorder.Dispose()
            $border.Dispose()
        }

        $rivetSize = [Math]::Max(5, [int]($Height / 18))
        foreach ($point in @(
            @(10, 10), @(($Width - 10 - $rivetSize), 10),
            @(10, ($Height - 10 - $rivetSize)), @(($Width - 10 - $rivetSize), ($Height - 10 - $rivetSize)))) {
            $rivet = New-Object Drawing.Drawing2D.LinearGradientBrush(
                (New-Object Drawing.Rectangle($point[0], $point[1], $rivetSize, $rivetSize)),
                [Drawing.Color]::FromArgb(255, 214, 219, 216),
                [Drawing.Color]::FromArgb(255, 35, 40, 42),
                45.0)
            try {
                $graphics.FillEllipse($rivet, $point[0], $point[1], $rivetSize, $rivetSize)
            }
            finally {
                $rivet.Dispose()
            }
        }

        if ($Width -gt 500) {
            Add-BrandText $graphics $fontFamily 'UNREAL' ([Drawing.RectangleF]::new(55, 18, $Width - 110, 120)) 76 ([Drawing.FontStyle]::Bold)
            Add-BrandText $graphics $fontFamily 'REVIVED' ([Drawing.RectangleF]::new(125, 127, $Width - 250, 48)) 27 ([Drawing.FontStyle]::Regular)
        }
        else {
            Add-BrandText $graphics $fontFamily 'UNREAL' ([Drawing.RectangleF]::new(32, 2, $Width - 64, 58)) 36 ([Drawing.FontStyle]::Bold)
            Add-BrandText $graphics $fontFamily 'REVIVED' ([Drawing.RectangleF]::new(80, 54, $Width - 160, 26)) 13 ([Drawing.FontStyle]::Regular)
        }
    }
    finally {
        $fontFamily.Dispose()
        $graphics.Dispose()
    }
    try {
        $bitmap.Save($Output, [Drawing.Imaging.ImageFormat]::Bmp)
    }
    finally {
        $bitmap.Dispose()
    }
}

function Convert-BitmapToIconFrame {
    param(
        [Drawing.Bitmap] $Source,
        [int] $Size
    )

    $bitmap = New-Object Drawing.Bitmap($Size, $Size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear([Drawing.Color]::Transparent)
        $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.DrawImage($Source, 0, 0, $Size, $Size)
    }
    finally {
        $graphics.Dispose()
    }

    $stream = New-Object IO.MemoryStream
    $writer = New-Object IO.BinaryWriter($stream)
    try {
        $maskRowBytes = [int]([Math]::Ceiling($Size / 32.0) * 4)
        $writer.Write([uint32]40)
        $writer.Write([int32]$Size)
        $writer.Write([int32]($Size * 2))
        $writer.Write([uint16]1)
        $writer.Write([uint16]32)
        $writer.Write([uint32]0)
        $writer.Write([uint32]($Size * $Size * 4))
        $writer.Write([int32]0)
        $writer.Write([int32]0)
        $writer.Write([uint32]0)
        $writer.Write([uint32]0)
        for ($y = $Size - 1; $y -ge 0; $y--) {
            for ($x = 0; $x -lt $Size; $x++) {
                $pixel = $bitmap.GetPixel($x, $y)
                $writer.Write([byte]$pixel.B)
                $writer.Write([byte]$pixel.G)
                $writer.Write([byte]$pixel.R)
                $writer.Write([byte]$pixel.A)
            }
        }
        $writer.Write((New-Object byte[] ($maskRowBytes * $Size)))
        return ,$stream.ToArray()
    }
    finally {
        $writer.Dispose()
        $stream.Dispose()
        $bitmap.Dispose()
    }
}

function New-BrandIcon {
    param(
        [string] $Output,
        [Drawing.Bitmap] $Artwork
    )

    $size = 256
    if ($Artwork) {
        $source = New-Object Drawing.Bitmap($size, $size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [Drawing.Graphics]::FromImage($source)
        try {
            $graphics.Clear([Drawing.Color]::Transparent)
            $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($Artwork, 0, 0, $size, $size)
        }
        finally {
            $graphics.Dispose()
        }
    }
    else {
        $source = New-Object Drawing.Bitmap($size, $size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [Drawing.Graphics]::FromImage($source)
        $fontFamily = Get-BrandFontFamily
        try {
            $graphics.Clear([Drawing.Color]::Transparent)
            $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $points = [Drawing.PointF[]]@(
                (New-Object Drawing.PointF(128, 10)), (New-Object Drawing.PointF(226, 67)),
                (New-Object Drawing.PointF(226, 189)), (New-Object Drawing.PointF(128, 246)),
                (New-Object Drawing.PointF(30, 189)), (New-Object Drawing.PointF(30, 67)))
            $fill = New-Object Drawing.Drawing2D.LinearGradientBrush(
                (New-Object Drawing.Point(20, 20)), (New-Object Drawing.Point(236, 236)),
                [Drawing.Color]::FromArgb(255, 78, 88, 92), [Drawing.Color]::FromArgb(255, 15, 20, 23))
            $outline = New-Object Drawing.Pen([Drawing.Color]::FromArgb(255, 229, 166, 57), 12)
            $inner = New-Object Drawing.Pen([Drawing.Color]::FromArgb(255, 32, 37, 39), 4)
            try {
                $graphics.FillPolygon($fill, $points)
                $graphics.DrawPolygon($outline, $points)
                $graphics.DrawPolygon($inner, $points)
            }
            finally {
                $inner.Dispose()
                $outline.Dispose()
                $fill.Dispose()
            }
            Add-BrandText $graphics $fontFamily 'UR' (New-Object Drawing.RectangleF(38, 58, 180, 134)) 92 ([Drawing.FontStyle]::Bold)
            Add-BrandText $graphics $fontFamily 'REVIVED' (New-Object Drawing.RectangleF(48, 174, 160, 35)) 19 ([Drawing.FontStyle]::Regular)
        }
        finally {
            $fontFamily.Dispose()
            $graphics.Dispose()
        }
    }

    $sizes = @(16, 24, 32, 48, 64, 128, 256)
    $frames = @($sizes | ForEach-Object { Convert-BitmapToIconFrame $source $_ })
    $source.Dispose()
    $file = [IO.File]::Open($Output, [IO.FileMode]::Create, [IO.FileAccess]::Write)
    $writer = New-Object IO.BinaryWriter($file)
    try {
        $writer.Write([uint16]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]$frames.Count)
        $offset = 6 + (16 * $frames.Count)
        for ($index = 0; $index -lt $frames.Count; $index++) {
            $sizeByte = if ($sizes[$index] -eq 256) { 0 } else { $sizes[$index] }
            $writer.Write([byte]$sizeByte)
            $writer.Write([byte]$sizeByte)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([uint16]1)
            $writer.Write([uint16]32)
            $writer.Write([uint32]$frames[$index].Length)
            $writer.Write([uint32]$offset)
            $offset += $frames[$index].Length
        }
        foreach ($frame in $frames) {
            $writer.Write($frame)
        }
    }
    finally {
        $writer.Dispose()
        $file.Dispose()
    }
}

function Export-LogoBranding {
    param([string] $Source)

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        throw "Logo source does not exist: $Source"
    }

    $sourceImage = [Drawing.Image]::FromFile([IO.Path]::GetFullPath($Source))
    try {
        foreach ($outputSpec in @(
            [pscustomobject]@{ Name = 'Logo'; Width = 719; Height = 200 },
            [pscustomobject]@{ Name = 'SetupLogo'; Width = 343; Height = 84 })) {
            $transparent = New-Object Drawing.Bitmap($outputSpec.Width, $outputSpec.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics = [Drawing.Graphics]::FromImage($transparent)
            try {
                $graphics.Clear([Drawing.Color]::Transparent)
                $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $scale = [Math]::Min($outputSpec.Width / $sourceImage.Width, $outputSpec.Height / $sourceImage.Height)
                $width = [int][Math]::Round($sourceImage.Width * $scale)
                $height = [int][Math]::Round($sourceImage.Height * $scale)
                $left = [int](($outputSpec.Width - $width) / 2)
                $top = [int](($outputSpec.Height - $height) / 2)
                $graphics.DrawImage($sourceImage, $left, $top, $width, $height)
            }
            finally {
                $graphics.Dispose()
            }

            try {
                $transparent.Save((Join-Path $OutputRoot ($outputSpec.Name + '.png')), [Drawing.Imaging.ImageFormat]::Png)
                $compatible = New-Object Drawing.Bitmap($outputSpec.Width, $outputSpec.Height, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
                $compatibleGraphics = [Drawing.Graphics]::FromImage($compatible)
                try {
                    $compatibleGraphics.Clear([Drawing.Color]::FromArgb(240, 240, 240))
                    $compatibleGraphics.DrawImageUnscaled($transparent, 0, 0)
                    $compatible.Save((Join-Path $OutputRoot ($outputSpec.Name + '.bmp')), [Drawing.Imaging.ImageFormat]::Bmp)
                }
                finally {
                    $compatibleGraphics.Dispose()
                    $compatible.Dispose()
                }
            }
            finally {
                $transparent.Dispose()
            }
        }
    }
    finally {
        $sourceImage.Dispose()
    }
}

function Export-IconBranding {
    param([string] $Source)

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        throw "Icon source does not exist: $Source"
    }
    $iconArtwork = [Drawing.Bitmap]::FromFile([IO.Path]::GetFullPath($Source))
    try {
        New-BrandIcon (Join-Path $OutputRoot 'UnrealRevived.ico') $iconArtwork
    }
    finally {
        $iconArtwork.Dispose()
    }
}

function New-PlaceholderMenuBackground {
    param([string] $Output)

    $width = 1280
    $height = 720
    $bitmap = New-Object Drawing.Bitmap($width, $height, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $fontFamily = Get-BrandFontFamily
    try {
        $graphics.ScaleTransform(1.25, 0.9375)
        $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $background = New-Object Drawing.Drawing2D.LinearGradientBrush(
            (New-Object Drawing.Point(0, 0)),
            (New-Object Drawing.Point($width, $height)),
            [Drawing.Color]::FromArgb(255, 10, 17, 20),
            [Drawing.Color]::FromArgb(255, 86, 96, 96))
        try {
            $graphics.FillRectangle($background, 0, 0, $width, $height)
        }
        finally {
            $background.Dispose()
        }

        $random = New-Object Random 227
        for ($index = 0; $index -lt 900; $index++) {
            $alpha = $random.Next(7, 25)
            $tone = $random.Next(50, 155)
            $pen = New-Object Drawing.Pen([Drawing.Color]::FromArgb($alpha, $tone, $tone, $tone), $random.Next(1, 4))
            try {
                $x = $random.Next(-100, $width)
                $y = $random.Next(0, $height)
                $graphics.DrawLine($pen, $x, $y, $x + $random.Next(20, 220), $y + $random.Next(-8, 9))
            }
            finally {
                $pen.Dispose()
            }
        }

        $panel = New-Object Drawing.Drawing2D.LinearGradientBrush(
            ([Drawing.Rectangle]::new(92, 58, 840, 652)),
            [Drawing.Color]::FromArgb(225, 36, 47, 50),
            [Drawing.Color]::FromArgb(235, 11, 16, 18),
            90.0)
        $outer = New-Object Drawing.Pen([Drawing.Color]::FromArgb(255, 195, 137, 42), 7)
        $inner = New-Object Drawing.Pen([Drawing.Color]::FromArgb(220, 4, 7, 8), 3)
        try {
            $graphics.FillRectangle($panel, 92, 58, 840, 652)
            $graphics.DrawRectangle($outer, 92, 58, 840, 652)
            $graphics.DrawRectangle($inner, 108, 74, 808, 620)
        }
        finally {
            $inner.Dispose()
            $outer.Dispose()
            $panel.Dispose()
        }

        $emblemPoints = [Drawing.PointF[]]@(
            [Drawing.PointF]::new(512, 112), [Drawing.PointF]::new(652, 193),
            [Drawing.PointF]::new(652, 355), [Drawing.PointF]::new(512, 436),
            [Drawing.PointF]::new(372, 355), [Drawing.PointF]::new(372, 193))
        $emblem = New-Object Drawing.Drawing2D.LinearGradientBrush(
            (New-Object Drawing.Point(370, 110)), (New-Object Drawing.Point(655, 440)),
            [Drawing.Color]::FromArgb(255, 95, 108, 110), [Drawing.Color]::FromArgb(255, 13, 20, 22))
        $emblemOuter = New-Object Drawing.Pen([Drawing.Color]::FromArgb(255, 237, 176, 67), 13)
        $emblemInner = New-Object Drawing.Pen([Drawing.Color]::FromArgb(255, 25, 30, 31), 4)
        try {
            $graphics.FillPolygon($emblem, $emblemPoints)
            $graphics.DrawPolygon($emblemOuter, $emblemPoints)
            $graphics.DrawPolygon($emblemInner, $emblemPoints)
        }
        finally {
            $emblemInner.Dispose()
            $emblemOuter.Dispose()
            $emblem.Dispose()
        }

        Add-BrandText $graphics $fontFamily 'UR' ([Drawing.RectangleF]::new(382, 174, 260, 178)) 128 ([Drawing.FontStyle]::Bold)
        Add-BrandText $graphics $fontFamily 'UNREAL REVIVED' ([Drawing.RectangleF]::new(142, 468, 740, 112)) 65 ([Drawing.FontStyle]::Bold)
        Add-BrandText $graphics $fontFamily 'NATIVE DIRECT3D 12' ([Drawing.RectangleF]::new(302, 590, 420, 54)) 25 ([Drawing.FontStyle]::Regular)

        foreach ($point in @(@(119, 85), @(877, 85), @(119, 649), @(877, 649))) {
            $rivet = New-Object Drawing.Drawing2D.LinearGradientBrush(
                ([Drawing.Rectangle]::new($point[0], $point[1], 28, 28)),
                [Drawing.Color]::FromArgb(255, 230, 232, 222),
                [Drawing.Color]::FromArgb(255, 37, 42, 43),
                45.0)
            try {
                $graphics.FillEllipse($rivet, $point[0], $point[1], 28, 28)
            }
            finally {
                $rivet.Dispose()
            }
        }
    }
    finally {
        $fontFamily.Dispose()
        $graphics.Dispose()
    }

    try {
        $bitmap.Save($Output, [Drawing.Imaging.ImageFormat]::Bmp)
    }
    finally {
        $bitmap.Dispose()
    }
}

function Import-MenuBackground {
    param(
        [string] $Source,
        [string] $Output
    )

    $sourcePath = [IO.Path]::GetFullPath($Source)
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Menu background source not found: $sourcePath"
    }

    $image = [Drawing.Image]::FromFile($sourcePath)
    try {
        if (($image.Width * 9) -ne ($image.Height * 16)) {
            throw "Menu background must use a 16:9 aspect ratio; source is $($image.Width)x$($image.Height): $sourcePath"
        }

        $bitmap = New-Object Drawing.Bitmap(3840, 2160, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($image, 0, 0, 3840, 2160)
        }
        finally {
            $graphics.Dispose()
        }
    }
    finally {
        $image.Dispose()
    }

    try {
        $bitmap.Save($Output, [Drawing.Imaging.ImageFormat]::Bmp)
    }
    finally {
        $bitmap.Dispose()
    }
}

function Export-IntroNvidiaLogo {
    param(
        [string] $Source,
        [string] $Output
    )

    $sourcePath = [IO.Path]::GetFullPath($Source)
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "NVIDIA intro logo source not found: $sourcePath"
    }

    $image = [Drawing.Bitmap]::FromFile($sourcePath)
    $outputBitmap = New-Object Drawing.Bitmap(256, 256, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($outputBitmap)
    try {
        $graphics.Clear([Drawing.Color]::Transparent)
        $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $sourceRectangle = [Drawing.Rectangle]::new(260, 250, 1640, 1510)
        $graphics.DrawImage($image, [Drawing.Rectangle]::new(8, 8, 240, 240), $sourceRectangle, [Drawing.GraphicsUnit]::Pixel)
    }
    finally {
        $graphics.Dispose()
        $image.Dispose()
    }

    for ($y = 0; $y -lt $outputBitmap.Height; $y++) {
        for ($x = 0; $x -lt $outputBitmap.Width; $x++) {
            $pixel = $outputBitmap.GetPixel($x, $y)
            if ($pixel.R -ge 230 -and $pixel.G -ge 230 -and $pixel.B -ge 230) {
                $outputBitmap.SetPixel($x, $y, [Drawing.Color]::Transparent)
            }
        }
    }

    try {
        $outputBitmap.Save($Output, [Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $outputBitmap.Dispose()
    }
}

function Export-MenuBackgroundTiles {
    param([string] $Source)

    $bitmap = [Drawing.Bitmap]::FromFile($Source)
    $encodedBitmap = New-Object Drawing.Bitmap(1024, 768, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $encodedGraphics = [Drawing.Graphics]::FromImage($encodedBitmap)
    try {
        $encodedGraphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $encodedGraphics.DrawImage($bitmap, 0, 0, 1024, 768)

        for ($row = 0; $row -lt 3; $row++) {
            for ($column = 0; $column -lt 4; $column++) {
                $tile = New-Object Drawing.Bitmap(256, 256, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
                $tileGraphics = [Drawing.Graphics]::FromImage($tile)
                try {
                    $tileGraphics.DrawImageUnscaled($encodedBitmap, -($column * 256), -($row * 256))
                }
                finally {
                    $tileGraphics.Dispose()
                }
                try {
                    $tileName = 'ModernBg{0}{1}.bmp' -f ($column + 1), ($row + 1)
                    $tile.Save((Join-Path $MenuTextureRoot $tileName), [Drawing.Imaging.ImageFormat]::Bmp)
                }
                finally {
                    $tile.Dispose()
                }
            }
        }
    }
    finally {
        $encodedGraphics.Dispose()
        $encodedBitmap.Dispose()
        $bitmap.Dispose()
    }
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
New-Item -ItemType Directory -Path $MenuTextureRoot -Force | Out-Null

$menuBackgroundOutput = Join-Path $OutputRoot 'MenuBackground.bmp'
if ($IntroNvidiaSource) {
    $introNvidiaOutput = Join-Path $OutputRoot 'NvidiaIntroLogoRuntime.png'
    if ([IO.Path]::GetFullPath($IntroNvidiaSource) -eq [IO.Path]::GetFullPath($introNvidiaOutput)) {
        throw 'NVIDIA intro logo source must not be the generated runtime texture.'
    }
    Export-IntroNvidiaLogo $IntroNvidiaSource $introNvidiaOutput
    Write-Host "NVIDIA intro logo imported from $([IO.Path]::GetFullPath($IntroNvidiaSource))"
}

if ($BrandingOnly) {
    if ($MenuBackgroundSource -or $IntroNvidiaSource -or $DeriveBranding) {
        throw '-BrandingOnly cannot be combined with menu, NVIDIA, or derive options.'
    }
    Export-LogoBranding $LogoSource
    Export-IconBranding $IconSource
    Write-Host "Logo and icon branding generated at $OutputRoot"
    return
}

if ($MenuBackgroundSource) {
    Import-MenuBackground $MenuBackgroundSource $menuBackgroundOutput
    Export-MenuBackgroundTiles $menuBackgroundOutput
    if ($DeriveBranding) {
        Export-LogoBranding $LogoSource
        Export-IconBranding $IconSource
    }
    Write-Host "Menu background imported and tiled from $([IO.Path]::GetFullPath($MenuBackgroundSource))"
    return
}

if ($IntroNvidiaSource) {
    return
}

if ($DeriveBranding) {
    throw '-DeriveBranding requires -MenuBackgroundSource.'
}

Export-LogoBranding $LogoSource
Export-IconBranding $IconSource
New-PlaceholderMenuBackground $menuBackgroundOutput
Export-MenuBackgroundTiles $menuBackgroundOutput

Write-Host "Unreal Revived branding generated at $OutputRoot"
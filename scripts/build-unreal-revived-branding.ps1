param(
    [string] $OutputRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'branding')
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
    param([string] $Output)

    $size = 256
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

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
New-BrandBanner 719 200 (Join-Path $OutputRoot 'Logo.bmp')
New-BrandBanner 343 84 (Join-Path $OutputRoot 'SetupLogo.bmp')
New-BrandIcon (Join-Path $OutputRoot 'UnrealRevived.ico')

Write-Host "Unreal Revived branding generated at $OutputRoot"
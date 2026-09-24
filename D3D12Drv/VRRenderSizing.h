// Runtime-driven sizing only. Headset panel specifications are not render targets.
#pragma once
#include <algorithm>
#include <cmath>
#include <cstdint>

namespace VRRenderSizing
{
struct Size { int Width; int Height; };

inline int NormalizeQuality(int Quality)
{
	return Quality >= 1 && Quality <= 4 ? Quality : 2;
}

inline Size EyeSize(int Quality, Size Profile, uint32_t Width, uint32_t Height,
	uint32_t MaxWidth, uint32_t MaxHeight, uint32_t DeviceLimit = 16384)
{
	Quality = NormalizeQuality(Quality);
	if (!Quality || !Width || !Height || !MaxWidth || !MaxHeight || !DeviceLimit)
		return Profile;
	const double Scales[] = { 0.0, 0.75, 1.0, 1.25, 1.5 };
	const double Scale = std::min({ Scales[Quality],
		static_cast<double>(std::min(MaxWidth, DeviceLimit)) / Width,
		static_cast<double>(std::min(MaxHeight, DeviceLimit)) / Height });
	return { std::max(1, static_cast<int>(std::floor(Width * Scale))),
		std::max(1, static_cast<int>(std::floor(Height * Scale))) };
}

struct Rect { float X; float Y; float Width; float Height; };

inline Rect RasterViewport(Size Logical, Size Raster, Rect Frame)
{
	const float ScaleX = static_cast<float>(Raster.Width) / Logical.Width;
	const float ScaleY = static_cast<float>(Raster.Height) / Logical.Height;
	return { Frame.X * ScaleX, (Logical.Height - Frame.Y - Frame.Height) * ScaleY,
		Frame.Width * ScaleX, Frame.Height * ScaleY };
}
}

#include "../VRRenderSizing.h"
#include <cstdlib>
#include <iostream>
#include <limits>

void Check(bool Passed, const char* Message)
{
	if (!Passed) { std::cerr << Message << '\n'; std::exit(1); }
}
bool Near(float A, float B) { return std::abs(A - B) < 0.001f; }

int main()
{
	using namespace VRRenderSizing;
	const Size Profile = { 1280, 1024 };
	for (const Size Logical : { Profile, Size{1920,1080}, Size{1600,1280} })
	{
		for (int Quality : { -1, 0, 6, 999 })
		{
			const auto Original = EyeSize(Quality, Logical, 3000, 3200, 6000, 6400);
			Check(Original.Width == Logical.Width && Original.Height == Logical.Height,
				"Default and invalid presets must preserve customized profiles");
		}
	}
	const Size Expected[] = { Profile, {1500,1800}, {2000,2400}, {2500,3000}, {3000,3600}, {4000,4800} };
	for (int Quality = 1; Quality <= 5; ++Quality)
	{
		const auto Eye = EyeSize(Quality, Profile, 2000, 2400, 6000, 6000);
		Check(Eye.Width == Expected[Quality].Width && Eye.Height == Expected[Quality].Height,
			"Presets must scale both dimensions");
		const auto Full = RasterViewport(Profile, Eye, {0,0,1280,1024});
		Check(Near(Full.X, 0) && Near(Full.Y, 0) && Near(Full.Width, float(Eye.Width)) &&
			Near(Full.Height, float(Eye.Height)), "Full logical frame must fill eye texture");
		const auto Sub = RasterViewport(Profile, Eye, {128,256,640,512});
		Check(Near(Sub.X / Eye.Width, 0.1f) && Near(Sub.Y / Eye.Height, 0.25f) &&
			Near(Sub.Width / Eye.Width, 0.5f) && Near(Sub.Height / Eye.Height, 0.5f),
			"Inset frames must retain normalized coordinates at every quality");
	}
	const auto Left = EyeSize(2, Profile, 2000, 2200, 4000, 4400);
	const auto Right = EyeSize(2, Profile, 2100, 2400, 4200, 4800);
	Check(Left.Width == 2000 && Right.Width == 2100 && Right.Height == 2400,
		"Unequal eyes must keep their independent runtime sizes");
	const auto Limited = EyeSize(4, Profile, 2000, 2400, 2600, 3000);
	Check(Limited.Width == 2500 && Limited.Height == 3000, "Clamp both axes together to preserve proportions");
	const auto Huge = EyeSize(4, Profile, 20000, 30000, 50000, 50000);
	Check(Huge.Width <= 16384 && Huge.Height == 16384, "Respect device limit");
	const auto Invalid = EyeSize(4, Profile, 0, 2400, 0, 4000);
	Check(Invalid.Width == Profile.Width && Invalid.Height == Profile.Height, "Invalid recommendations fall back");
	const auto Overflow = EyeSize(4, Profile, std::numeric_limits<uint32_t>::max(),
		std::numeric_limits<uint32_t>::max(), 16384, 16384);
	Check(Overflow.Width == 16384 && Overflow.Height == 16384, "Avoid integer overflow from runtime dimensions");
	std::cout << "VR render sizing and logical viewport checks passed\n";
}

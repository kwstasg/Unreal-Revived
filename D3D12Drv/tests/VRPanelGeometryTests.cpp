// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

#include "../VRPanelGeometry.h"
#include <cstdlib>
#include <iostream>

void Check(bool Condition)
{
	if (!Condition) { std::cerr << "VR panel geometry invariant failed\n"; std::exit(1); }
}
bool Near(float A, float B) { return std::fabs(A - B) < 0.0001f; }

int main()
{
	using namespace VRPanelGeometry;
	const int Resolutions[][2] = { {1280,1024}, {1280,720}, {1920,1080}, {1820,980}, {2560,1440}, {3840,2160} };
	for (const auto& R : Resolutions)
		for (float Scale : {0.5f, 1.0f, 2.0f})
		{
			const float W = Width(Scale), H = Height(W, R[0], R[1]);
			Check(Near(W / H, float(R[0]) / R[1]));
			Check(Near(W / Width(1), Scale));
		}
	std::cout << "Panel size, scale and source-aspect checks passed\n";
}

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
	Quaternion Previous = { 0, 0, 0, 1 };
	for (int Yaw = -180; Yaw <= 180; Yaw += 5)
		for (int Pitch = -85; Pitch <= 85; Pitch += 5)
		{
			const float Y = Yaw * 3.14159265f / 180, P = Pitch * 3.14159265f / 180;
			const auto Q = Upright(-std::sin(Y) * std::cos(P), -std::cos(Y) * std::cos(P), Previous);
			Check(Near(Q.x, 0) && Near(Q.z, 0));
			Check(Near(Q.y * Q.y + Q.w * Q.w, 1));
			// Rotating world-up by this quaternion must leave it exactly upright.
			Check(Near(2 * (Q.x * Q.y - Q.z * Q.w), 0));
			Check(Near(1 - 2 * (Q.x * Q.x + Q.z * Q.z), 1));
			Check(Near(2 * (Q.y * Q.z + Q.x * Q.w), 0));
			Check(Near(-2 * Q.y * Q.w, -std::sin(Y)));
			Previous = Q;
		}
	const auto Vertical = Upright(0, 0, Previous);
	Check(Near(Vertical.y, Previous.y) && Near(Vertical.w, Previous.w));
	const int Resolutions[][2] = { {1280,1024}, {1280,720}, {1920,1080}, {1820,980}, {2560,1440}, {3840,2160} };
	for (const auto& R : Resolutions)
		for (float Scale : {0.5f, 1.0f, 2.0f})
		{
			const float W = Width(Scale), H = Height(W, R[0], R[1]);
			Check(Near(W / H, float(R[0]) / R[1]));
			Check(Near(W / Width(1), Scale));
		}
	std::cout << "Upright heading, vertical fallback and source-aspect checks passed\n";
}

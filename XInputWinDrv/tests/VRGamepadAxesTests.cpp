// Unreal Revived
// Author: Kwstasg - Kostas Giannakakis
// Project: https://github.com/kwstasg/Unreal-Revived

#include "../VRGamepadAxes.h"
#include <cstdlib>
#include <iostream>

static void Check(float Actual, float Expected)
{
	if (std::fabs(Actual - Expected) > 0.0001f)
	{
		std::cerr << "Expected " << Expected << ", got " << Actual << '\n';
		std::exit(1);
	}
}

int main()
{
	constexpr float Pi = 3.14159265359f;
	// Looking right: forward becomes body-right; strafe-right becomes back.
	float Strafe = 0.0f, Forward = 1.0f;
	VRGamepadAxes::Rotate(Strafe, Forward, Pi / 2);
	Check(Strafe, 1.0f); Check(Forward, 0.0f);
	Strafe = 1.0f; Forward = 0.0f;
	VRGamepadAxes::Rotate(Strafe, Forward, Pi / 2);
	Check(Strafe, 0.0f); Check(Forward, -1.0f);
	Strafe = 0.0f; Forward = -1.0f;
	VRGamepadAxes::Rotate(Strafe, Forward, -Pi / 2);
	Check(Strafe, 1.0f); Check(Forward, 0.0f);
	Strafe = 0.0f; Forward = 1.0f;
	VRGamepadAxes::Rotate(Strafe, Forward, Pi);
	Check(Strafe, 0.0f); Check(Forward, -1.0f);
	// Head direction must never accelerate diagonals or create movement at rest.
	for (int Degrees = -360; Degrees <= 360; Degrees += 5)
	{
		const float Yaw = Degrees * Pi / 180.0f;
		Strafe = 0.3f; Forward = -0.7f;
		VRGamepadAxes::Rotate(Strafe, Forward, Yaw);
		Check(Strafe * Strafe + Forward * Forward, 0.58f);
		VRGamepadAxes::Rotate(Strafe, Forward, -Yaw);
		Check(Strafe, 0.3f); Check(Forward, -0.7f);
		Strafe = Forward = 0.0f;
		VRGamepadAxes::Rotate(Strafe, Forward, Yaw);
		Check(Strafe, 0.0f); Check(Forward, 0.0f);
	}
	std::cout << "VR gamepad direction and magnitude checks passed\n";
}

// Unreal Revived - horizontal, magnitude-preserving gamepad movement basis.
#pragma once
#include <cmath>

namespace VRGamepadAxes
{
	inline void Rotate(float& Strafe, float& Forward, float YawRadians)
	{
		const float SinYaw = std::sin(YawRadians);
		const float CosYaw = std::cos(YawRadians);
		const float OldForward = Forward;
		Forward = OldForward * CosYaw - Strafe * SinYaw;
		Strafe = OldForward * SinYaw + Strafe * CosYaw;
	}
}

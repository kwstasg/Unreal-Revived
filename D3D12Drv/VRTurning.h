#pragma once
#include <algorithm>
#include <cmath>

// One turn per deliberate stick deflection; shared by production and tests.
class VRTurning
{
public:
	static int Mode(int Value) { return Value >= 0 && Value <= 2 ? Value : 0; }
	static int Angle(int Value) { return ((std::clamp(Value, 15, 90) + 7) / 15) * 15; }
	void Reset() { Armed = false; Elapsed = 0; Target = Applied = 0; }
	int Step(float Axis, float Seconds, int TurnMode, int Degrees, bool Active)
	{
		if (!Active || Mode(TurnMode) == 0 || !std::isfinite(Axis) ||
			!std::isfinite(Seconds) || Seconds < 0 || Seconds > 0.25f)
		{
			Reset();
			return 0;
		}
		if (std::abs(Axis) <= 0.25f && Target == 0) Armed = true;
		if (Armed && std::abs(Axis) >= 0.7f && Target == 0)
		{
			Armed = false;
			Target = static_cast<int>(std::round(Angle(Degrees) * 65536.0 / 360.0)) * (Axis < 0 ? -1 : 1);
			Elapsed = 0;
			Applied = 0;
		}
		if (!Target) return 0;
		Elapsed = std::min(Elapsed + Seconds, 0.15f);
		const float T = TurnMode == 1 ? 1.0f : Elapsed / 0.15f;
		const int Total = static_cast<int>(std::round(Target * (T * T * (3 - 2 * T))));
		const int Delta = Total - Applied;
		Applied = Total;
		if (T >= 1) Target = Applied = 0;
		return Delta;
	}
private:
	bool Armed = false;
	float Elapsed = 0;
	int Target = 0, Applied = 0;
};

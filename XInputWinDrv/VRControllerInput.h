// Combine gamepad buttons without one device releasing another device's hold.
#pragma once

namespace VRControllerInput
{
	template<class State> void Merge(State& Target, const State& Other)
	{
		Target.Buttons |= Other.Buttons;
		if (Other.LeftTrigger > Target.LeftTrigger) Target.LeftTrigger = Other.LeftTrigger;
		if (Other.RightTrigger > Target.RightTrigger) Target.RightTrigger = Other.RightTrigger;
		auto Magnitude = [](int X, int Y) { return double(X) * X + double(Y) * Y; };
		if (Magnitude(Other.LeftX, Other.LeftY) > Magnitude(Target.LeftX, Target.LeftY))
		{
			Target.LeftX = Other.LeftX;
			Target.LeftY = Other.LeftY;
		}
		if (Magnitude(Other.RightX, Other.RightY) > Magnitude(Target.RightX, Target.RightY))
		{
			Target.RightX = Other.RightX;
			Target.RightY = Other.RightY;
		}
	}
}

// Unreal Revived
// The installed UWindow slider rounds negative steps incorrectly.
class ModernSignedSliderControl extends UWindowHSliderControl;

function float CheckValue(float Test)
{
	local float Rounded;
	Rounded = Test;
	if (Step > 0)
	{
		Rounded = int(Abs(Test) / Step + 0.5) * Step;
		if (Test < 0)
			Rounded = -Rounded;
	}
	return FClamp(Rounded, MinValue, MaxValue);
}
